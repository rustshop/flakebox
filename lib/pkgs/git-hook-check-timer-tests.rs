use super::*;

fn warning_at(nanoseconds: u64) -> Option<String> {
    slow_check_warning(
        OsStr::new("check_boundary"),
        Duration::from_nanos(nanoseconds),
    )
}

#[test]
fn does_not_warn_below_one_second() {
    assert_eq!(warning_at(999_999_999), None);
}

#[test]
fn does_not_warn_at_exactly_one_second() {
    assert_eq!(warning_at(1_000_000_000), None);
}

#[test]
fn barely_slow_check_does_not_display_one_second() {
    assert_eq!(
        warning_at(1_000_000_001),
        Some("flakebox: warning: check_boundary took 1.001s (>1s)".to_owned())
    );
}

#[test]
fn rounds_display_to_millisecond_precision() {
    assert_eq!(
        warning_at(1_234_567_890),
        Some("flakebox: warning: check_boundary took 1.235s (>1s)".to_owned())
    );
}

#[test]
fn warning_formatter_compacts_only_redundant_newlines() {
    let input = [
        b"terminated\n".as_slice(),
        WARNING_MARKER,
        b"flakebox: warning: check_one took 1.200s (>1s)\n",
        WARNING_MARKER,
        b"flakebox: warning: check_two took 1.300s (>1s)\n",
    ]
    .concat();
    let mut output = Vec::new();

    compact_warning_spacing(&input[..], &mut output).expect("warning formatter succeeds");

    assert_eq!(
        output,
        b"terminated\nflakebox: warning: check_one took 1.200s (>1s)\n\
            flakebox: warning: check_two took 1.300s (>1s)\n"
    );
}

#[test]
fn warning_formatter_preserves_unterminated_and_binary_output() {
    let input = [
        b"unterminated\0".as_slice(),
        WARNING_MARKER,
        b"flakebox: warning: check_slow took 1.200s (>1s)\n",
    ]
    .concat();
    let mut output = Vec::new();

    compact_warning_spacing(&input[..], &mut output).expect("warning formatter succeeds");

    assert_eq!(
        output,
        b"unterminated\0\nflakebox: warning: check_slow took 1.200s (>1s)\n"
    );
}

#[test]
fn warning_formatter_preserves_ordinary_output_byte_exactly() {
    let input = b"\0ordinary\n\noutput without newline";
    let mut output = Vec::new();

    compact_warning_spacing(&input[..], &mut output).expect("warning formatter succeeds");

    assert_eq!(output, input);
}

#[test]
fn warning_formatter_does_not_prefix_first_warning() {
    let input = [
        WARNING_MARKER,
        b"flakebox: warning: check_slow took 1.200s (>1s)\n",
    ]
    .concat();
    let mut output = Vec::new();

    compact_warning_spacing(&input[..], &mut output).expect("warning formatter succeeds");

    assert_eq!(output, b"flakebox: warning: check_slow took 1.200s (>1s)\n");
}

#[cfg(unix)]
#[test]
fn signal_before_child_publication_is_queued_for_publisher() {
    let state = ChildSignalState::new();
    assert_eq!(state.receive(TERMINATE_SIGNAL), None);
    assert_eq!(state.publish(1234), Some(TERMINATE_SIGNAL));
}

#[cfg(unix)]
#[test]
fn signal_after_child_publication_is_routed_to_published_group() {
    let state = ChildSignalState::new();
    assert_eq!(state.publish(1234), None);
    assert_eq!(state.receive(TERMINATE_SIGNAL), Some(1234));
}

#[cfg(unix)]
#[test]
fn signal_during_shutdown_is_not_routed_to_finished_child() {
    let state = ChildSignalState::new();
    state.begin_shutdown();
    assert_eq!(state.receive(TERMINATE_SIGNAL), None);
    assert_eq!(state.encoded.load(Ordering::SeqCst), SHUTTING_DOWN);
}
