use std::path::PathBuf;

use fs_err as fs;

use super::path_state::{PathState, install_file, temporary_path};

fn test_dir(name: &str) -> PathBuf {
    let path =
        std::env::temp_dir().join(format!("flakebox-git-hooks-{name}-{}", std::process::id()));
    let _ = fs::remove_dir_all(&path);
    fs::create_dir(&path).unwrap();
    path
}

#[test]
fn apply_preserves_destination_created_after_validation() {
    let directory = test_dir("changed-destination");
    let destination = directory.join("dispatcher");
    fs::write(&destination, b"foreign\n").unwrap();

    assert!(install_file(b"flakebox\n", 0o755, &destination, &PathState::Missing).is_err());
    assert_eq!(fs::read(&destination).unwrap(), b"foreign\n");
    fs::remove_dir_all(directory).unwrap();
}

#[test]
fn apply_preserves_temporary_path_occupied_after_validation() {
    let directory = test_dir("occupied-temporary");
    let destination = directory.join("dispatcher");
    let temporary = temporary_path(&destination);
    fs::write(&temporary, b"foreign temporary\n").unwrap();

    assert!(install_file(b"flakebox\n", 0o755, &destination, &PathState::Missing).is_err());
    assert_eq!(fs::read(&temporary).unwrap(), b"foreign temporary\n");
    assert!(!destination.exists());
    fs::remove_dir_all(directory).unwrap();
}
