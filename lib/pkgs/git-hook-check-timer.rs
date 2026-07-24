//! Runs one exported git-hook check under Bash and reports slow execution.
//!
//! Flakebox packages this helper only for its supported Unix hosts (Linux and
//! macOS). It uses a monotonic clock, mirrors the check's status or terminating
//! signal, and forwards cancellation signals to the check's process group.

use std::env;
use std::ffi::OsStr;
use std::io::{self, Write as _};
#[cfg(unix)]
use std::os::unix::process::{CommandExt as _, ExitStatusExt as _};
use std::process::{self, Command, ExitStatus};
use std::sync::atomic::{AtomicI32, Ordering};
use std::time::{Duration, Instant};

const WARNING_THRESHOLD: Duration = Duration::from_secs(1);
const TIMER_ERROR_EXIT_CODE: i32 = 125;

#[cfg(unix)]
const HANGUP_SIGNAL: i32 = 1;
#[cfg(unix)]
const INTERRUPT_SIGNAL: i32 = 2;
#[cfg(unix)]
const QUIT_SIGNAL: i32 = 3;
#[cfg(unix)]
const TERMINATE_SIGNAL: i32 = 15;
#[cfg(unix)]
const SIGNALS_TO_FORWARD: [i32; 4] = [
    HANGUP_SIGNAL,
    INTERRUPT_SIGNAL,
    QUIT_SIGNAL,
    TERMINATE_SIGNAL,
];
#[cfg(unix)]
const CHILD_NOT_PUBLISHED: i32 = 0;
#[cfg(unix)]
const SHUTTING_DOWN: i32 = i32::MAX;
#[cfg(unix)]
const DEFAULT_SIGNAL_HANDLER: usize = 0;

#[cfg(unix)]
static CHILD_SIGNAL_STATE: ChildSignalState = ChildSignalState::new();
/// Remembers the most recent signal so the timer can terminate in the same way.
#[cfg(unix)]
static RECEIVED_SIGNAL: AtomicI32 = AtomicI32::new(0);

/// Coordinates signal delivery with publication of the child process group.
///
/// The encoded state is zero before publication, a positive process group
/// after publication, a negative pending signal, or `SHUTTING_DOWN` after the
/// child exits. Atomic transitions ensure a signal is queued or routed, never
/// both, while multiple early signals retain the most recent one.
#[cfg(unix)]
struct ChildSignalState {
    /// Encoded publication, pending-signal, or shutdown state.
    encoded: AtomicI32,
}

#[cfg(unix)]
impl ChildSignalState {
    /// Creates an unpublished child signal state.
    const fn new() -> Self {
        Self {
            encoded: AtomicI32::new(CHILD_NOT_PUBLISHED),
        }
    }

    /// Queues a signal or returns the published process group to receive it.
    fn receive(&self, signal_number: i32) -> Option<i32> {
        loop {
            let current_state = self.encoded.load(Ordering::SeqCst);
            if current_state == SHUTTING_DOWN {
                return None;
            }
            if 0 < current_state {
                return Some(current_state);
            }

            if self
                .encoded
                .compare_exchange(
                    current_state,
                    -signal_number,
                    Ordering::SeqCst,
                    Ordering::SeqCst,
                )
                .is_ok()
            {
                return None;
            }
        }
    }

    /// Publishes the process group and returns any signal queued before it.
    fn publish(&self, process_group: i32) -> Option<i32> {
        loop {
            let current_state = self.encoded.load(Ordering::SeqCst);
            if self
                .encoded
                .compare_exchange(
                    current_state,
                    process_group,
                    Ordering::SeqCst,
                    Ordering::SeqCst,
                )
                .is_ok()
            {
                return (current_state < 0).then_some(-current_state);
            }
        }
    }

    /// Stops forwarding to the child while signal dispositions are restored.
    fn begin_shutdown(&self) {
        self.encoded.store(SHUTTING_DOWN, Ordering::SeqCst);
    }

    /// Reports whether the child has been unpublished.
    fn is_shutting_down(&self) -> bool {
        self.encoded.load(Ordering::SeqCst) == SHUTTING_DOWN
    }
}

#[cfg(unix)]
unsafe extern "C" {
    fn kill(process_id: i32, signal: i32) -> i32;
    fn raise(signal: i32) -> i32;
    fn signal(signal: i32, handler: usize) -> usize;
}

struct CheckResult {
    /// Exit status returned by the check process.
    status: ExitStatus,
    /// Monotonic time from immediately before spawn through process exit.
    elapsed: Duration,
}

fn main() {
    let mut args = env::args_os().skip(1);
    let Some(check_name) = args.next() else {
        timer_error("missing check name");
    };
    if args.next().is_some() {
        timer_error("expected exactly one check name");
    }

    #[cfg(unix)]
    install_signal_forwarding();

    let check_result = run_check(&check_name);

    if let Ok(check_result) = &check_result {
        if let Some(warning) = slow_check_warning(&check_name, check_result.elapsed) {
            // A diagnostic write failure must never replace the check's exit status.
            // The leading newline keeps this record complete even if this or
            // another concurrent check left stderr unterminated.
            let warning_record = format!("\n{warning}\n");
            let _ = io::stderr().lock().write_all(warning_record.as_bytes());
        }
    }

    match check_result {
        Ok(check_result) => exit_like_check(check_result.status),
        Err(error) => timer_error(&format!("could not run check {check_name:?}: {error}")),
    }
}

fn run_check(check_name: &OsStr) -> io::Result<CheckResult> {
    let mut command = Command::new("bash");
    command.arg("-c").arg(check_name);

    #[cfg(unix)]
    command.process_group(0);

    let started_at = Instant::now();
    let mut child = command.spawn()?;

    #[cfg(unix)]
    {
        let process_group = i32::try_from(child.id()).expect("child process ID fits in i32");
        if let Some(pending_signal) = CHILD_SIGNAL_STATE.publish(process_group) {
            forward_to_child_process_group(process_group, pending_signal);
        }
    }

    let status = child.wait();
    #[cfg(unix)]
    {
        // Unpublish the child before elapsed-time formatting or diagnostic I/O
        // can delay shutdown and allow its process-group ID to be recycled.
        CHILD_SIGNAL_STATE.begin_shutdown();
        debug_assert!(CHILD_SIGNAL_STATE.is_shutting_down());
    }
    let status = status?;
    let elapsed = started_at.elapsed();

    Ok(CheckResult { status, elapsed })
}

fn slow_check_warning(check_name: &OsStr, elapsed: Duration) -> Option<String> {
    if elapsed <= WARNING_THRESHOLD {
        return None;
    }

    let rounded_milliseconds = (elapsed.as_nanos() + 500_000) / 1_000_000;
    // The strict threshold is measured at nanosecond precision. Do not display
    // 1.000s for a duration that was genuinely above that threshold.
    let displayed_milliseconds = rounded_milliseconds.max(1_001);

    Some(format!(
        "flakebox: warning: {} took {}.{:03}s (>1s)",
        check_name.to_string_lossy(),
        displayed_milliseconds / 1_000,
        displayed_milliseconds % 1_000
    ))
}

fn timer_error(message: &str) -> ! {
    let _ = writeln!(
        io::stderr().lock(),
        "flakebox: error: git-hook check timer: {message}"
    );
    process::exit(TIMER_ERROR_EXIT_CODE);
}

#[cfg(unix)]
extern "C" fn forward_signal(signal_number: i32) {
    RECEIVED_SIGNAL.store(signal_number, Ordering::SeqCst);
    if let Some(child_process_group) = CHILD_SIGNAL_STATE.receive(signal_number) {
        forward_to_child_process_group(child_process_group, signal_number);
    }
}

#[cfg(unix)]
fn forward_to_child_process_group(process_group: i32, signal_number: i32) {
    // SAFETY: POSIX kill(2) is async-signal-safe. A negative PID targets the
    // whole child process group created immediately before spawning the check.
    unsafe {
        kill(-process_group, signal_number);
    }
}

#[cfg(unix)]
fn install_signal_forwarding() {
    for signal_number in SIGNALS_TO_FORWARD {
        // SAFETY: `forward_signal` has the C signal-handler ABI and only uses
        // atomics plus the async-signal-safe kill(2).
        unsafe {
            signal(signal_number, forward_signal as *const () as usize);
        }
    }
}

fn exit_like_check(status: ExitStatus) -> ! {
    #[cfg(unix)]
    {
        // Stop publishing the now-finished child, then restore default signal
        // dispositions before reading the final signal. A signal in between
        // is recorded by the handler; a later signal terminates us directly.
        debug_assert!(CHILD_SIGNAL_STATE.is_shutting_down());
        for forwarded_signal in SIGNALS_TO_FORWARD {
            // SAFETY: these are the signal dispositions installed above.
            unsafe {
                signal(forwarded_signal, DEFAULT_SIGNAL_HANDLER);
            }
        }

        let received_signal = RECEIVED_SIGNAL.load(Ordering::SeqCst);
        let signal_number = if received_signal != 0 {
            Some(received_signal)
        } else {
            status.signal()
        };

        if let Some(signal_number) = signal_number {
            // SAFETY: restoring this signal's default disposition before
            // raise(3) makes this process terminate exactly like the check,
            // including for signals that are not normally forwarded.
            unsafe {
                signal(signal_number, DEFAULT_SIGNAL_HANDLER);
            }
            // SAFETY: signal dispositions were restored immediately above.
            unsafe {
                raise(signal_number);
            }
            process::exit(128 + signal_number);
        }
    }

    process::exit(status.code().unwrap_or(TIMER_ERROR_EXIT_CODE));
}

#[cfg(test)]
#[path = "git-hook-check-timer-tests.rs"]
mod tests;
