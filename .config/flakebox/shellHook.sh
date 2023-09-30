#!/usr/bin/env bash
dot_git="$(git rev-parse --git-common-dir)"
if [[ ! -d "${dot_git}/hooks" ]]; then mkdir -p "${dot_git}/hooks"; fi
rm -f "${dot_git}/hooks/comit-msg"
ln -sf "$(pwd)/misc/git-hooks/comit-msg" "${dot_git}/hooks/comit-msg"

dot_git="$(git rev-parse --git-common-dir)"
if [[ ! -d "${dot_git}/hooks" ]]; then mkdir -p "${dot_git}/hooks"; fi
rm -f "${dot_git}/hooks/pre-commit"
ln -sf "$(pwd)/misc/git-hooks/pre-commit" "${dot_git}/hooks/pre-commit"

# set template
/nix/store/nqdyqplahmhdgz8pzzd5nip17zf3ijzx-git-2.40.1/bin/git config commit.template misc/git-hooks/commit-template.txt

if [ -n "${DIRENV_IN_ENVRC:-}" ]; then
  # and not set DIRENV_LOG_FORMAT
  if [ -n "${DIRENV_LOG_FORMAT:-}" ]; then
    >&2 echo "💡 Set 'DIRENV_LOG_FORMAT=\"\"' in your shell environment variables for a cleaner output of direnv"
  fi
fi

>&2 echo "💡 Run 'just' for a list of available 'just ...' helper recipes"
