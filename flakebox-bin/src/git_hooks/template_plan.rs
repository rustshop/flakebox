use std::path::{Path, PathBuf};
use std::process::Command;

use error_stack::{Report, ResultExt};

use super::path_state::{PathState, path_state, revalidate};
use super::{COMMIT_TEMPLATE, git, git_args, require_git_success};
use crate::{AppError, AppResult};

#[derive(Clone, Copy)]
pub(super) enum OwnedConfigScope {
    Local,
    Worktree,
}

pub(super) struct TemplateAction {
    project_root: PathBuf,
    local_config: PathBuf,
    local_state: PathState,
    worktree_config: PathBuf,
    worktree_state: PathState,
    mutation: TemplateMutation,
}

enum TemplateMutation {
    Enable {
        activation: WorktreeActivation,
        legacy: LegacyTemplateMutation,
        worktree: EnabledWorktreeMutation,
    },
    Disable {
        legacy: LegacyTemplateMutation,
        worktree: DisabledWorktreeMutation,
    },
}

enum WorktreeActivation {
    Preserve,
    Enable,
    RemoveDefaultBareAndEnable,
}

enum LegacyTemplateMutation {
    Preserve,
    Remove,
}

enum EnabledWorktreeMutation {
    Preserve,
    Set,
}

enum DisabledWorktreeMutation {
    Preserve,
    Unset,
}

impl TemplateAction {
    pub(super) fn validate(
        candidate_root: &Path,
        project_root: &Path,
        git_common_dir: &Path,
        git_dir: &Path,
    ) -> AppResult<Self> {
        let candidate_enabled = candidate_root.join(COMMIT_TEMPLATE).exists();
        let expected = nul_terminated(COMMIT_TEMPLATE);
        let worktree_config_enabled = worktree_config_enabled(project_root)?;
        let local_config = git_common_dir.join("config");
        let worktree_config = git_dir.join("config.worktree");
        let local_state = path_state(&local_config)?;
        let worktree_state = path_state(&worktree_config)?;

        let local_template = git_local_template_value(project_root)?;
        let worktree_template = match &worktree_state {
            PathState::Missing => None,
            PathState::Regular { .. } => config_file_value(project_root, &worktree_config)?,
            PathState::Symlink(_) | PathState::Directory { .. } | PathState::Other
                if candidate_enabled =>
            {
                return Err(Report::new(AppError::Project)).attach_printable(format!(
                    "{} is not a regular worktree config file; preserve or replace it explicitly",
                    worktree_config.display()
                ));
            }
            PathState::Symlink(_) | PathState::Directory { .. } | PathState::Other => None,
        };
        let mut remove_default_core_bare = false;
        if candidate_enabled {
            if !worktree_config_enabled {
                remove_default_core_bare = preflight_worktree_config_activation(project_root)?;
            }
            if let Some(value) = &worktree_template
                && *value != expected
            {
                return Err(Report::new(AppError::Project)).attach_printable(
                    "worktree commit.template has a non-Flakebox value; preserve or remove it \
                     explicitly before installing the Flakebox template",
                );
            }
        }

        let legacy = if local_template.as_deref() == Some(expected.as_slice()) {
            LegacyTemplateMutation::Remove
        } else {
            LegacyTemplateMutation::Preserve
        };
        let mutation = if candidate_enabled {
            let activation = match (worktree_config_enabled, remove_default_core_bare) {
                (true, _) => WorktreeActivation::Preserve,
                (false, true) => WorktreeActivation::RemoveDefaultBareAndEnable,
                (false, false) => WorktreeActivation::Enable,
            };
            let worktree = if worktree_template.as_deref() == Some(expected.as_slice()) {
                EnabledWorktreeMutation::Preserve
            } else {
                EnabledWorktreeMutation::Set
            };
            TemplateMutation::Enable {
                activation,
                legacy,
                worktree,
            }
        } else {
            let worktree = if worktree_config_enabled
                && worktree_template.as_deref() == Some(expected.as_slice())
            {
                DisabledWorktreeMutation::Unset
            } else {
                DisabledWorktreeMutation::Preserve
            };
            TemplateMutation::Disable { legacy, worktree }
        };

        Ok(Self {
            project_root: project_root.to_owned(),
            local_config,
            local_state,
            worktree_config,
            worktree_state,
            mutation,
        })
    }

    pub(super) fn apply(self) -> AppResult<()> {
        let mut local_state = self.local_state;
        let worktree_state = self.worktree_state;

        match self.mutation {
            TemplateMutation::Enable {
                activation,
                legacy,
                worktree,
            } => {
                apply_worktree_activation(
                    &self.project_root,
                    &self.local_config,
                    &mut local_state,
                    activation,
                )?;
                apply_legacy_template_mutation(
                    &self.project_root,
                    &self.local_config,
                    &local_state,
                    legacy,
                )?;
                if matches!(worktree, EnabledWorktreeMutation::Set) {
                    revalidate(&self.worktree_config, &worktree_state)?;
                    let output = git(
                        &self.project_root,
                        ["config", "--worktree", "commit.template", COMMIT_TEMPLATE],
                    )?;
                    require_git_success(output, "could not configure commit.template")?;
                }
            }
            TemplateMutation::Disable { legacy, worktree } => {
                apply_legacy_template_mutation(
                    &self.project_root,
                    &self.local_config,
                    &local_state,
                    legacy,
                )?;
                if matches!(worktree, DisabledWorktreeMutation::Unset) {
                    revalidate(&self.worktree_config, &worktree_state)?;
                    unset_config_value(
                        &self.project_root,
                        OwnedConfigScope::Worktree,
                        COMMIT_TEMPLATE,
                    )?;
                }
            }
        }
        Ok(())
    }
}

fn apply_worktree_activation(
    project_root: &Path,
    local_config: &Path,
    local_state: &mut PathState,
    mutation: WorktreeActivation,
) -> AppResult<()> {
    if matches!(mutation, WorktreeActivation::RemoveDefaultBareAndEnable) {
        revalidate(local_config, local_state)?;
        let output = git(
            project_root,
            [
                "config",
                "--local",
                "--fixed-value",
                "--unset-all",
                "core.bare",
                "false",
            ],
        )?;
        require_git_success(output, "could not migrate the default core.bare value")?;
        #[cfg(feature = "test-support")]
        inject_core_bare_after_migration_for_test(project_root)?;
        *local_state = path_state(local_config)?;
    }
    if !matches!(mutation, WorktreeActivation::Preserve) {
        preflight_worktree_config_activation_after_migration(project_root)?;
        revalidate(local_config, local_state)?;
        let output = git(
            project_root,
            ["config", "--local", "extensions.worktreeConfig", "true"],
        )?;
        require_git_success(output, "could not enable worktree Git configuration")?;
        *local_state = path_state(local_config)?;
    }
    Ok(())
}

#[cfg(feature = "test-support")]
fn inject_core_bare_after_migration_for_test(project_root: &Path) -> AppResult<()> {
    if std::env::var_os("FLAKEBOX_TEST_INJECT_CORE_BARE_AFTER_MIGRATION").is_none() {
        return Ok(());
    }
    let output = git(project_root, ["config", "--local", "core.bare", "true"])?;
    require_git_success(output, "could not inject the test-only core.bare race")?;
    Ok(())
}

fn preflight_worktree_config_activation_after_migration(project_root: &Path) -> AppResult<()> {
    if local_config_values(project_root, "core.worktree")?.is_some() {
        return Err(Report::new(AppError::Project)).attach_printable(
            "core.worktree changed during installation; migrate it to worktree config before \
             enabling extensions.worktreeConfig",
        );
    }
    if local_config_values(project_root, "core.bare")?.is_some() {
        return Err(Report::new(AppError::Project)).attach_printable(
            "core.bare changed during installation; migrate it to worktree config before enabling \
             extensions.worktreeConfig",
        );
    }
    Ok(())
}

fn apply_legacy_template_mutation(
    project_root: &Path,
    local_config: &Path,
    local_state: &PathState,
    mutation: LegacyTemplateMutation,
) -> AppResult<()> {
    if matches!(mutation, LegacyTemplateMutation::Remove) {
        revalidate(local_config, local_state)?;
        unset_config_value(project_root, OwnedConfigScope::Local, COMMIT_TEMPLATE)?;
    }
    Ok(())
}

fn config_file_value(project_root: &Path, path: &Path) -> AppResult<Option<Vec<u8>>> {
    let output = Command::new("git")
        .arg("-C")
        .arg(project_root)
        .args(["config", "--file"])
        .arg(path)
        .args(["--null", "--get-all", "commit.template"])
        .output()
        .change_context(AppError::IO)?;
    if output.status.success() {
        Ok(Some(output.stdout))
    } else if output.status.code() == Some(1) {
        Ok(None)
    } else {
        require_git_success(output, "could not inspect dormant worktree commit.template")
            .map(|_| None)
    }
}

fn preflight_worktree_config_activation(project_root: &Path) -> AppResult<bool> {
    if local_config_values(project_root, "core.worktree")?.is_some() {
        return Err(Report::new(AppError::Project)).attach_printable(
            "cannot enable extensions.worktreeConfig while local core.worktree is set; \
             migrate core.worktree to worktree config as described by git-config(1), then retry",
        );
    }
    let remove_default_core_bare = match local_config_values(project_root, "core.bare")? {
        None => false,
        Some(value) if value == b"false\0" => true,
        Some(_) => {
            return Err(Report::new(AppError::Project)).attach_printable(
                "cannot enable extensions.worktreeConfig while non-default local core.bare is set; \
                 migrate core.bare to worktree config as described by git-config(1), then retry",
            );
        }
    };

    Ok(remove_default_core_bare)
}

fn worktree_config_enabled(project_root: &Path) -> AppResult<bool> {
    let output = git(
        project_root,
        [
            "config",
            "--local",
            "--type=bool",
            "--get",
            "extensions.worktreeConfig",
        ],
    )?;
    if output.status.success() {
        Ok(output.stdout == b"true\n")
    } else if output.status.code() == Some(1) {
        Ok(false)
    } else {
        require_git_success(output, "could not inspect extensions.worktreeConfig").map(|_| false)
    }
}

fn local_config_values(project_root: &Path, key: &str) -> AppResult<Option<Vec<u8>>> {
    let output = git_args(
        project_root,
        &["config", "--local", "--null", "--get-all", key],
    )?;
    if output.status.success() {
        Ok(Some(output.stdout))
    } else if output.status.code() == Some(1) {
        Ok(None)
    } else {
        require_git_success(output, &format!("could not inspect {key}")).map(|_| None)
    }
}

fn git_local_template_value(project_root: &Path) -> AppResult<Option<Vec<u8>>> {
    let output = git_args(
        project_root,
        &[
            "config",
            "--local",
            "--null",
            "--get-all",
            "commit.template",
        ],
    )?;
    if output.status.success() {
        Ok(Some(output.stdout))
    } else if output.status.code() == Some(1) {
        Ok(None)
    } else {
        require_git_success(output, "could not inspect commit.template").map(|_| None)
    }
}

pub(super) fn unset_config_value(
    project_root: &Path,
    scope: OwnedConfigScope,
    expected: &str,
) -> AppResult<()> {
    let scope_arg = match scope {
        OwnedConfigScope::Local => "--local",
        OwnedConfigScope::Worktree => "--worktree",
    };
    let output = git(
        project_root,
        [
            "config",
            scope_arg,
            "--fixed-value",
            "--unset-all",
            "commit.template",
            expected,
        ],
    )?;
    require_git_success(output, "could not remove commit.template")?;
    Ok(())
}

fn nul_terminated(value: &str) -> Vec<u8> {
    let mut bytes = value.as_bytes().to_vec();
    bytes.push(0);
    bytes
}
