use std::path::{Path, PathBuf};

use error_stack::{Report, ResultExt};

use super::HOOK_NAMES;
use super::hook_plan::{
    HookAction, ensure_hook_replaceable, preflight_dispatcher, preflight_legacy_hook,
    preflight_marker, preflight_temporary_path,
};
use super::path_state::{DirectoryAction, PathState, path_state};
use super::template_plan::TemplateAction;
use crate::{AppError, AppResult};

pub(super) struct InstallPlan {
    directories: Vec<DirectoryAction>,
    hooks: Vec<HookAction>,
    template: TemplateAction,
}

impl InstallPlan {
    pub(super) fn validate(
        candidate_root: &Path,
        project_root: &Path,
        git_common_dir: &Path,
        git_dir: &Path,
    ) -> AppResult<Self> {
        let hooks_dir = git_common_dir.join("hooks");
        let dispatchers_dir = hooks_dir.join("flakebox");
        let flakebox_dir = git_dir.join("flakebox");
        let markers_dir = flakebox_dir.join("hooks");
        let create_managed_directories = HOOK_NAMES.iter().any(|name| {
            candidate_root
                .join(".config/flakebox/git-hooks")
                .join(name)
                .exists()
        });
        let directories = [&hooks_dir, &dispatchers_dir, &flakebox_dir, &markers_dir]
            .into_iter()
            .map(|path| DirectoryAction::validate(path, create_managed_directories))
            .collect::<AppResult<Vec<_>>>()?;
        let mut hooks = Vec::new();

        for name in HOOK_NAMES {
            let candidate = candidate_root.join(".config/flakebox/git-hooks").join(name);
            let hook = hooks_dir.join(name);
            let dispatcher = dispatchers_dir.join(name);
            let marker = markers_dir.join(format!("{name}-enabled"));
            let hook_state = path_state(&hook)?;
            let marker_state = path_state(&marker)?;

            if candidate.exists() {
                let link_target = PathBuf::from("flakebox").join(name);
                let dispatcher_state = path_state(&dispatcher)?;
                let PathState::Regular { contents, mode } = path_state(&candidate)? else {
                    return Err(Report::new(AppError::Project)).attach_printable(format!(
                        "{} is not a regular generated hook",
                        candidate.display()
                    ));
                };
                ensure_hook_replaceable(&hook, &hook_state, &link_target, project_root, name)?;
                preflight_dispatcher(
                    &dispatcher,
                    &dispatcher_state,
                    &hook_state,
                    &link_target,
                    &contents,
                    mode,
                )?;
                preflight_marker(&marker, &marker_state)?;
                for destination in [&hook, &dispatcher, &marker] {
                    preflight_temporary_path(destination)?;
                }
                hooks.push(HookAction::Enable {
                    contents,
                    mode,
                    hook,
                    hook_state,
                    dispatcher,
                    dispatcher_state,
                    marker,
                    marker_state,
                });
            } else {
                preflight_legacy_hook(&hook, &hook_state, name, project_root)?;
                preflight_marker(&marker, &marker_state)?;
                hooks.push(HookAction::Disable {
                    hook,
                    hook_state,
                    marker,
                    marker_state,
                    legacy_target: project_root.join("misc/git-hooks").join(name),
                });
            }
        }

        Ok(Self {
            directories,
            hooks,
            template: TemplateAction::validate(
                candidate_root,
                project_root,
                git_common_dir,
                git_dir,
            )?,
        })
    }

    pub(super) fn apply(self) -> AppResult<()> {
        for directory in self.directories {
            directory.apply()?;
        }
        for hook in self.hooks {
            hook.apply()?;
        }
        self.template.apply()
    }
}
