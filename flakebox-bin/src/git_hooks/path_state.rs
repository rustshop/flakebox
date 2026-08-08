use std::fs::{OpenOptions, Permissions};
use std::io::{ErrorKind, Write};
use std::os::unix::fs::{MetadataExt, OpenOptionsExt, PermissionsExt, symlink};
use std::path::{Path, PathBuf};

use error_stack::{Report, ResultExt};
use fs_err as fs;

use crate::{AppError, AppResult};

#[derive(Clone, Debug, Eq, PartialEq)]
pub(super) enum PathState {
    Missing,
    Regular { contents: Vec<u8>, mode: u32 },
    Symlink(PathBuf),
    Directory { device: u64, inode: u64 },
    Other,
}

pub(super) struct DirectoryAction {
    path: PathBuf,
    state: PathState,
    create: bool,
}

impl DirectoryAction {
    pub(super) fn validate(path: &Path, create: bool) -> AppResult<Self> {
        let state = path_state(path)?;
        match state {
            PathState::Missing | PathState::Directory { .. } => Ok(Self {
                path: path.to_owned(),
                state,
                create,
            }),
            PathState::Regular { .. } | PathState::Symlink(_) | PathState::Other => {
                Err(Report::new(AppError::Project)).attach_printable(format!(
                    "{} is not an ownership-safe directory; preserve or replace it explicitly",
                    path.display()
                ))
            }
        }
    }

    pub(super) fn apply(self) -> AppResult<()> {
        revalidate(&self.path, &self.state)?;
        if self.create && matches!(self.state, PathState::Missing) {
            fs::create_dir(&self.path)
                .change_context(AppError::IO)
                .attach_printable_lazy(|| format!("could not create {}", self.path.display()))?;
        }
        Ok(())
    }
}

pub(super) fn path_state(path: &Path) -> AppResult<PathState> {
    let metadata = match path.symlink_metadata() {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == ErrorKind::NotFound => return Ok(PathState::Missing),
        Err(error) => {
            return Err(error)
                .change_context(AppError::IO)
                .attach_printable_lazy(|| format!("could not inspect {}", path.display()));
        }
    };
    if metadata.file_type().is_symlink() {
        return fs::read_link(path)
            .map(PathState::Symlink)
            .change_context(AppError::IO);
    }
    if metadata.file_type().is_file() {
        return fs::read(path)
            .map(|contents| PathState::Regular {
                contents,
                mode: metadata.permissions().mode() & 0o777,
            })
            .change_context(AppError::IO);
    }
    if metadata.file_type().is_dir() {
        return Ok(PathState::Directory {
            device: metadata.dev(),
            inode: metadata.ino(),
        });
    }
    Ok(PathState::Other)
}

pub(super) fn install_marker(destination: &Path, validated: &PathState) -> AppResult<()> {
    revalidate(destination, validated)?;
    if matches!(validated, PathState::Regular { contents, mode } if contents == b"enabled\n" && *mode == 0o644)
    {
        return Ok(());
    }
    let temporary = temporary_path(destination);
    write_new(&temporary, b"enabled\n", 0o644)?;
    rename_into_place(&temporary, destination)
}

pub(super) fn install_file(
    source_contents: &[u8],
    source_mode: u32,
    destination: &Path,
    validated: &PathState,
) -> AppResult<()> {
    revalidate(destination, validated)?;
    if matches!(
        validated,
        PathState::Regular { contents, mode }
            if contents == source_contents && *mode == source_mode
    ) {
        return Ok(());
    }

    let temporary = temporary_path(destination);
    write_new(&temporary, source_contents, source_mode)?;
    rename_into_place(&temporary, destination)
}

pub(super) fn install_symlink(
    source: &Path,
    destination: &Path,
    validated: &PathState,
) -> AppResult<()> {
    revalidate(destination, validated)?;
    if matches!(validated, PathState::Symlink(installed) if installed == source) {
        return Ok(());
    }

    let temporary = temporary_path(destination);
    symlink(source, &temporary)
        .change_context(AppError::IO)
        .attach_printable_lazy(|| {
            format!(
                "could not exclusively create {}; preserve or remove that path explicitly before retrying",
                temporary.display()
            )
        })?;
    rename_into_place(&temporary, destination)
}

fn write_new(path: &Path, contents: &[u8], mode: u32) -> AppResult<()> {
    let mut file = OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(mode)
        .open(path)
        .change_context(AppError::IO)
        .attach_printable_lazy(|| {
            format!(
                "could not exclusively create {}; preserve or remove that path explicitly before retrying",
                path.display()
            )
        })?;
    let result = (|| {
        file.write_all(contents)?;
        file.set_permissions(Permissions::from_mode(mode))
    })();
    if let Err(error) = result {
        return Err(error)
            .change_context(AppError::IO)
            .attach_printable_lazy(|| {
                format!(
                    "could not finish {}; the exclusively created temporary file was preserved; \
                     inspect and remove it explicitly before retrying",
                    path.display()
                )
            });
    }
    Ok(())
}

pub(super) fn revalidate(path: &Path, validated: &PathState) -> AppResult<()> {
    if path_state(path)? != *validated {
        return Err(Report::new(AppError::Project)).attach_printable(format!(
            "{} changed after installer validation; retry without concurrent writers",
            path.display()
        ));
    }
    Ok(())
}

pub(super) fn remove_owned_path(
    path: &Path,
    validated: &PathState,
    owned: impl FnOnce(&PathState) -> bool,
) -> AppResult<()> {
    if !owned(validated) {
        return Ok(());
    }
    revalidate(path, validated)?;
    fs::remove_file(path).change_context(AppError::IO)
}

pub(super) fn temporary_path(destination: &Path) -> PathBuf {
    destination.with_extension(format!("flakebox-new-{}", std::process::id()))
}

fn rename_into_place(temporary: &Path, destination: &Path) -> AppResult<()> {
    if let Err(error) = fs::rename(temporary, destination) {
        return Err(error)
            .change_context(AppError::IO)
            .attach_printable_lazy(|| {
                format!("could not atomically install {}", destination.display())
            })
            .attach_printable(format!(
                "temporary path {} was preserved; inspect and remove it explicitly before retrying",
                temporary.display()
            ));
    }
    Ok(())
}
