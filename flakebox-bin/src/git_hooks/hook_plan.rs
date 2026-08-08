use std::io::ErrorKind;
use std::path::{Path, PathBuf};

use error_stack::{Report, ResultExt};

use super::path_state::{
    PathState, install_file, install_marker, install_symlink, remove_owned_path, temporary_path,
};
use crate::{AppError, AppResult};

pub(super) enum HookAction {
    Enable {
        contents: Vec<u8>,
        mode: u32,
        hook: PathBuf,
        hook_state: PathState,
        dispatcher: PathBuf,
        dispatcher_state: PathState,
        marker: PathBuf,
        marker_state: PathState,
    },
    Disable {
        hook: PathBuf,
        hook_state: PathState,
        marker: PathBuf,
        marker_state: PathState,
        legacy_target: PathBuf,
    },
}

impl HookAction {
    pub(super) fn apply(self) -> AppResult<()> {
        match self {
            Self::Enable {
                contents,
                mode,
                hook,
                hook_state,
                dispatcher,
                dispatcher_state,
                marker,
                marker_state,
            } => {
                install_file(&contents, mode, &dispatcher, &dispatcher_state)?;
                install_symlink(
                    &PathBuf::from("flakebox").join(hook.file_name().expect("hook has file name")),
                    &hook,
                    &hook_state,
                )?;
                install_marker(&marker, &marker_state)
            }
            Self::Disable {
                hook,
                hook_state,
                marker,
                marker_state,
                legacy_target,
            } => {
                remove_owned_path(
                    &marker,
                    &marker_state,
                    |state| matches!(state, PathState::Regular { contents, mode } if contents == b"enabled\n" && *mode == 0o644),
                )?;
                remove_owned_path(
                    &hook,
                    &hook_state,
                    |state| matches!(state, PathState::Symlink(target) if target == &legacy_target),
                )
            }
        }
    }
}

pub(super) fn preflight_dispatcher(
    dispatcher: &Path,
    dispatcher_state: &PathState,
    hook_state: &PathState,
    installed_target: &Path,
    candidate_contents: &[u8],
    candidate_mode: u32,
) -> AppResult<()> {
    match dispatcher_state {
        PathState::Missing => Ok(()),
        PathState::Regular { contents, mode }
            if contents == candidate_contents && *mode == candidate_mode =>
        {
            Ok(())
        }
        PathState::Regular { .. } if matches!(hook_state, PathState::Symlink(target) if target == installed_target) => {
            Ok(())
        }
        PathState::Regular { .. } => Err(Report::new(AppError::Project)).attach_printable(format!(
            "{} is not proven to be Flakebox-owned; preserve or remove it explicitly",
            dispatcher.display()
        )),
        PathState::Symlink(_) | PathState::Directory { .. } | PathState::Other => {
            Err(Report::new(AppError::Project)).attach_printable(format!(
                "{} is not a Flakebox-owned regular file; preserve or remove it explicitly",
                dispatcher.display()
            ))
        }
    }
}

pub(super) fn preflight_marker(marker: &Path, state: &PathState) -> AppResult<()> {
    match state {
        PathState::Missing => Ok(()),
        PathState::Regular { contents, mode } if contents == b"enabled\n" && *mode == 0o644 => {
            Ok(())
        }
        PathState::Regular { .. } => Err(Report::new(AppError::Project)).attach_printable(format!(
            "{} is not a Flakebox-owned enablement marker; preserve or remove it explicitly",
            marker.display()
        )),
        PathState::Symlink(_) | PathState::Directory { .. } | PathState::Other => {
            Err(Report::new(AppError::Project))
            .attach_printable(format!(
                "{} is not a Flakebox-owned regular enablement marker; preserve or remove it explicitly",
                marker.display()
            ))
        }
    }
}

pub(super) fn preflight_temporary_path(destination: &Path) -> AppResult<()> {
    let temporary = temporary_path(destination);
    match temporary.symlink_metadata() {
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Ok(_) => Err(Report::new(AppError::Project)).attach_printable(format!(
            "temporary install path {} already exists; preserve or remove it explicitly",
            temporary.display()
        )),
        Err(error) => Err(error)
            .change_context(AppError::IO)
            .attach_printable_lazy(|| format!("could not inspect {}", temporary.display())),
    }
}

pub(super) fn ensure_hook_replaceable(
    hook: &Path,
    state: &PathState,
    installed_target: &Path,
    project_root: &Path,
    name: &str,
) -> AppResult<()> {
    let legacy_target = project_root.join("misc/git-hooks").join(name);
    match state {
        PathState::Missing => Ok(()),
        PathState::Symlink(target) if target == installed_target || target == &legacy_target => {
            Ok(())
        }
        PathState::Symlink(target) => {
            Err(Report::new(AppError::Project)).attach_printable(format!(
                "{} points to non-Flakebox target {}; preserve or remove it explicitly before \
             installing Flakebox hooks",
                hook.display(),
                target.display()
            ))
        }
        PathState::Regular { .. } | PathState::Directory { .. } | PathState::Other => {
            Err(Report::new(AppError::Project)).attach_printable(format!(
                "{} is not a Flakebox-owned symlink; preserve or remove it explicitly before \
                 installing Flakebox hooks",
                hook.display()
            ))
        }
    }
}

pub(super) fn preflight_legacy_hook(
    hook: &Path,
    state: &PathState,
    name: &str,
    project_root: &Path,
) -> AppResult<()> {
    let legacy_suffix = Path::new("misc/git-hooks").join(name);
    let PathState::Symlink(target) = state else {
        return Ok(());
    };
    if *target != project_root.join(&legacy_suffix) && target.ends_with(legacy_suffix) {
        return Err(Report::new(AppError::Project)).attach_printable(format!(
            "{} points to an ambiguous legacy-style target {}; inspect linked worktrees and \
             remove or migrate the link explicitly",
            hook.display(),
            target.display()
        ));
    }
    Ok(())
}
