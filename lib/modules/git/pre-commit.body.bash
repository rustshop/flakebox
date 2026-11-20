set -euo pipefail

set +e
git diff-files --quiet
is_unclean=$?
set -e

# Restore the worktree patch captured by this hook.
function restore_flakebox_worktree {
  local hook_status=$?
  trap - EXIT

  if ! git cat-file blob "$FLAKEBOX_GIT_PATCH_OID" | git apply --whitespace=nowarn; then
    >&2 echo "flakebox: error: could not restore uncommitted changes; recover the patch from $FLAKEBOX_GIT_PATCH_REF"
    [ "$hook_status" -ne 0 ] || hook_status=1
  else
    git update-ref -d "$FLAKEBOX_GIT_PATCH_REF" "$FLAKEBOX_GIT_PATCH_OID"
  fi

  exit "$hook_status"
}

# Hide tracked worktree changes during checks and restore them on exit. Store
# the binary patch under a private ref so recovery remains possible on failure.
# Jujutsu has no staged/unstaged distinction, and manipulating its colocated
# Git index can race with Jujutsu snapshots, so checks use its current tree.
flakebox_git_root="$(git rev-parse --show-toplevel)"
if [ -z "${NO_STASH:-}" ] &&
  [ $is_unclean -ne 0 ] &&
  [ ! -e "$flakebox_git_root/.jj" ]; then
  FLAKEBOX_GIT_PATCH_OID="$(
    git diff-files --binary --full-index --no-ext-diff |
      git hash-object -w --stdin
  )"
  FLAKEBOX_GIT_PATCH_REF="refs/flakebox/pre-commit/$$-$RANDOM"
  git update-ref "$FLAKEBOX_GIT_PATCH_REF" "$FLAKEBOX_GIT_PATCH_OID" ""
  trap restore_flakebox_worktree EXIT
  GIT_LITERAL_PATHSPECS=0 git restore --worktree -- .
fi

export FLAKEBOX_GIT_LS
if [ -z "${FLAKEBOX_GIT_LS_IGNORE:-}" ]; then
  FLAKEBOX_GIT_LS="$(git ls-files | while read -r file; do if [ ! -L "$file" ]; then printf '%s\n' "$file"; fi; done)"
else
  FLAKEBOX_GIT_LS="$(git ls-files | { grep -v -E -e "${FLAKEBOX_GIT_LS_IGNORE}" || [[ $? == 1 ]]; } | while read -r file; do if [ ! -L "$file" ]; then printf '%s\n' "$file"; fi; done)"
fi

export FLAKEBOX_GIT_LS_TEXT
if [ -z "${FLAKEBOX_GIT_LS_TEXT_IGNORE:-}" ]; then
  FLAKEBOX_GIT_LS_TEXT="$(printf '%s\n' "$FLAKEBOX_GIT_LS" | { grep -v -E -e '@textExclude@' || [[ $? == 1 ]]; })"
else
  FLAKEBOX_GIT_LS_TEXT="$(printf '%s\n' "$FLAKEBOX_GIT_LS" | { grep -v -E -e '@textExclude@' -e "${FLAKEBOX_GIT_LS_TEXT_IGNORE}" || [[ $? == 1 ]]; })"
fi
