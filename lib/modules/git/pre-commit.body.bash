set -euo pipefail

set +e
git diff-files --quiet
is_unclean=$?
set -e

inventory_dir="$(mktemp -d)"
[[ "$inventory_dir" == /* ]] || inventory_dir="$PWD/$inventory_dir"
restore_patch=false
function cleanup_flakebox_hook {
  local hook_status=$?
  trap - EXIT

  rm -rf -- "$inventory_dir" || hook_status=1
  if ! "$restore_patch"; then
    exit "$hook_status"
  fi

  if ! git cat-file blob "$FLAKEBOX_GIT_PATCH_OID" | git apply --whitespace=nowarn; then
    >&2 echo "flakebox: error: could not restore uncommitted changes; recover the patch from $FLAKEBOX_GIT_PATCH_REF"
    [ "$hook_status" -ne 0 ] || hook_status=1
  else
    git update-ref -d "$FLAKEBOX_GIT_PATCH_REF" "$FLAKEBOX_GIT_PATCH_OID"
  fi

  exit "$hook_status"
}
trap cleanup_flakebox_hook EXIT

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
  restore_patch=true
  GIT_LITERAL_PATHSPECS=0 git restore --worktree -- .
fi

unset FLAKEBOX_GIT_LS FLAKEBOX_GIT_LS_TEXT
export FLAKEBOX_GIT_LS_FILE="$inventory_dir/tracked"
export FLAKEBOX_GIT_LS_TEXT_FILE="$inventory_dir/text"

function exclude_paths {
  if (( $# )); then
    grep -azvE "$@" || [[ $? == 1 ]]
  else
    cat
  fi
}
global_excludes=()
text_excludes=(-e '\.(png|ods|jpg|jpeg|woff2|keystore|wasm|ttf|jar|ico|gif)$')
[[ -z "${FLAKEBOX_GIT_LS_IGNORE:-}" ]] || global_excludes+=(-e "$FLAKEBOX_GIT_LS_IGNORE")
[[ -z "${FLAKEBOX_GIT_LS_TEXT_IGNORE:-}" ]] || text_excludes+=(-e "$FLAKEBOX_GIT_LS_TEXT_IGNORE")
git ls-files -z --deduplicate | exclude_paths "${global_excludes[@]}" |
  while LC_ALL=C IFS= read -r -d '' file; do
    if [[ ! -L "$file" ]]; then printf '%s\0' "$file"; fi
  done > "$FLAKEBOX_GIT_LS_FILE"
exclude_paths "${text_excludes[@]}" < "$FLAKEBOX_GIT_LS_FILE" > "$FLAKEBOX_GIT_LS_TEXT_FILE"

# Transitional adapter for custom Bash checks. Keep these shell variables out
# of child environments even when a check runs external commands.
function flakebox_load_legacy_inventory {
  FLAKEBOX_GIT_LS="$(tr '\0' '\n' < "$FLAKEBOX_GIT_LS_FILE")"
  FLAKEBOX_GIT_LS_TEXT="$(tr '\0' '\n' < "$FLAKEBOX_GIT_LS_TEXT_FILE")"
}
export -f flakebox_load_legacy_inventory
