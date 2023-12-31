#!/usr/bin/env bash

set -euo pipefail

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

export FLAKEBOX_GIT_LS
FLAKEBOX_GIT_LS="$(git ls-files)"
export FLAKEBOX_GIT_LS_TEXT
FLAKEBOX_GIT_LS_TEXT="$(echo "$FLAKEBOX_GIT_LS" | grep -v -E "\.(png|ods|jpg|jpeg|woff2|keystore|wasm|ttf|jar|ico|gif)\$")"


function check_nothing() {
  true
}
export -f check_nothing
