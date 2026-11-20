//! Check a NUL-delimited list of paths on stdin for a missing final LF.

use std::ffi::OsStr;
use std::fs::{self, File};
use std::io::{self, BufRead as _, Read as _, Seek as _, SeekFrom, Write as _};
use std::os::unix::ffi::OsStrExt as _;
use std::path::Path;
use std::process::ExitCode;

fn missing_newline(path: &Path) -> io::Result<bool> {
    let metadata = match fs::symlink_metadata(path) {
        Ok(metadata) => metadata,
        // The path may have been removed or its parent replaced in the
        // worktree.
        Err(err)
            if matches!(
                err.kind(),
                io::ErrorKind::NotFound | io::ErrorKind::NotADirectory
            ) =>
        {
            return Ok(false);
        }
        Err(err) => return Err(err),
    };
    if !metadata.is_file() || metadata.len() == 0 {
        return Ok(false);
    }

    let mut file = File::open(path)?;
    file.seek(SeekFrom::End(-1))?;
    let mut last_byte = [0];
    file.read_exact(&mut last_byte)?;
    if matches!(last_byte[0], b'\n' | 0) {
        return Ok(false);
    }

    // A file with a NUL anywhere is considered binary. Only scan the
    // contents when the last byte would otherwise make the check fail.
    file.rewind()?;
    let mut buf = [0; 16 * 1024];
    loop {
        let len = match file.read(&mut buf) {
            Err(err) if err.kind() == io::ErrorKind::Interrupted => continue,
            result => result?,
        };
        if len == 0 {
            return Ok(true);
        }
        if buf[..len].contains(&0) {
            return Ok(false);
        }
    }
}

fn path_label(path: &Path) -> String {
    match path.to_str() {
        Some(text) if !text.chars().any(char::is_control) => text.to_owned(),
        _ => format!("{path:?}"),
    }
}

fn check_paths() -> io::Result<bool> {
    let mut stdin = io::stdin().lock();
    let mut stderr = io::stderr().lock();
    let mut record = Vec::new();
    let mut failed = false;

    while stdin.read_until(0, &mut record)? != 0 {
        if record.pop() != Some(0) || record.is_empty() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid path record",
            ));
        }
        let path = Path::new(OsStr::from_bytes(&record));
        match missing_newline(path) {
            Ok(true) => {
                writeln!(stderr, "{} doesn't end with a newline", path_label(path))?;
                failed = true;
            }
            Ok(false) => {}
            Err(err) if err.kind() == io::ErrorKind::NotFound => {}
            Err(err) => {
                return Err(io::Error::new(
                    err.kind(),
                    format!("{}: {err}", path_label(path)),
                ));
            }
        }
        record.clear();
    }

    if failed {
        writeln!(stderr, "Fix the problems above or use --no-verify")?;
    }
    Ok(failed)
}

fn main() -> ExitCode {
    match check_paths() {
        Ok(false) => ExitCode::SUCCESS,
        Ok(true) => ExitCode::FAILURE,
        Err(err) => {
            eprintln!("flakebox-git-check-newline: {err}");
            ExitCode::from(2)
        }
    }
}
