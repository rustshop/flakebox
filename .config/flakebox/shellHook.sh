#!/usr/bin/env bash
yesterday=$(date -d "yesterday" +%s)
motd_ts_path=".config/flakebox/tmp/motd"

if [ ! -e "$motd_ts_path" ] || [ "$motd_ts_path" -ot "$yesterday" ]; then
mkdir -p "$(dirname "$motd_ts_path")"
touch "$motd_ts_path"
>&2 echo "Welcome to Flakebox dev env"

fi

flakebox_git_integration_outdated=
if root="$(git rev-parse --show-toplevel 2>/dev/null)" &&
  dot_git="$(git rev-parse --git-common-dir 2>/dev/null)" &&
  git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null)"; then
  hook="${dot_git}/hooks/pre-commit"
dispatcher="${dot_git}/hooks/flakebox/pre-commit"
source="${FLAKEBOX_ROOT_DIR_CANDIDATE}/.config/flakebox/git-hooks/pre-commit"
if [[ ! -e "${git_dir}/flakebox/hooks/pre-commit-enabled" ]] ||
  [[ ! -L "${hook}" ]] ||
  [[ "$(readlink "${hook}")" != "flakebox/pre-commit" ]] ||
  ! cmp -s "${source}" "${dispatcher}"; then
  flakebox_git_integration_outdated=1
fi

  hook="${dot_git}/hooks/commit-msg"
dispatcher="${dot_git}/hooks/flakebox/commit-msg"
source="${FLAKEBOX_ROOT_DIR_CANDIDATE}/.config/flakebox/git-hooks/commit-msg"
if [[ ! -e "${git_dir}/flakebox/hooks/commit-msg-enabled" ]] ||
  [[ ! -L "${hook}" ]] ||
  [[ "$(readlink "${hook}")" != "flakebox/commit-msg" ]] ||
  ! cmp -s "${source}" "${dispatcher}"; then
  flakebox_git_integration_outdated=1
fi

  if ! git config --null --get commit.template 2>/dev/null |
  cmp -s - <(printf 'misc/git-hooks/commit-template.txt\0'); then
  flakebox_git_integration_outdated=1
fi

fi
if [[ -n "${flakebox_git_integration_outdated}" ]]; then
  >&2 echo "ℹ️  Flakebox Git integration is missing or outdated. Run 'flakebox install-hooks'."
fi
unset flakebox_git_integration_outdated dispatcher git_dir hook source root dot_git

if ! flakebox lint --silent; then
  >&2 echo "ℹ️  Project recommendations detected. Run 'flakebox lint' for more info."
fi

if [[ "$-" == *i* ]] && [[ -t 2 ]] && [ -n "${DIRENV_IN_ENVRC:-}" ]; then
  # and not set DIRENV_LOG_FORMAT
  if [ -n "${DIRENV_LOG_FORMAT:-}" ]; then
    >&2 echo "💡 Set 'DIRENV_LOG_FORMAT=\"\"' in your shell environment variables for a cleaner output of direnv"
  fi
fi

if [[ "$-" == *i* ]] && [[ -t 2 ]]; then
  >&2 echo "💡 Run 'just' for a list of available 'just ...' helper recipes"
fi
