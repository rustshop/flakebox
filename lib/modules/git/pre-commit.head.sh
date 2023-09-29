#!/usr/bin/env bash

set -eo pipefail

set +e
git diff-files --quiet
is_unclean=$?
set -e

# Revert `git stash` on exit
function revert_git_stash {
  >&2 echo "Unstashing uncommitted changes..."
  git stash pop -q
}

# Stash pending changes and revert them when script ends
if [ -z "${NO_STASH:-}" ] && [ $is_unclean -ne 0 ]; then
  >&2 echo "Stashing uncommitted changes..."
  GIT_LITERAL_PATHSPECS=0 git stash -q --keep-index
  trap revert_git_stash EXIT
fi

export git_ls_files
git_ls_files="$(git ls-files)"
export git_ls_nonbinary_files
git_ls_nonbinary_files="$(echo "$git_ls_files" | xargs file --mime | grep -v "; charset=binary" | cut -d: -f1)"

export git_ls_nonbinary_files
git_ls_nonbinary_files="$(echo "$git_ls_files" | xargs file --mime | grep -v "; charset=binary" | cut -d: -f1)"

