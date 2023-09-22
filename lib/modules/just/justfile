alias b := build
alias c := check
alias t := test


default:
  @just --list

# run and restart on changes
watch:
  env RUST_LOG=${RUST_LOG:-debug} cargo watch -x run
  
# run `cargo build` on everything
build:
  cargo build --workspace --all-targets

# run `cargo check` on everything
check:
  cargo check --workspace --all-targets

# run `cargo clippy` on everything
clippy:
  cargo clippy --workspace --all-targets -- --deny warnings --allow deprecated

# run `cargo clippy --fix` on everything
clippy-fix:
  cargo clippy --workspace --all-targets --fix

# run tests
test: build
  cargo test

# run lints (quick)
lint:
  env NO_STASH=true $(git rev-parse --git-common-dir)/hooks/pre-commit
  just clippy
  env cargo doc --profile dev --no-deps --document-private-items

# fix some lint failures
lint-fix:
  just format
  just clippy-fix

# run all checks recommended before opening a PR
final-check: lint
  cargo test --doc
  just test


# check typos
[no-exit-message]
typos:
  #!/usr/bin/env bash
  set -eo pipefail

  git_ls_files="$(git ls-files)"
  git_ls_nonbinary_files="$(echo "$git_ls_files" | xargs file --mime | grep -v "; charset=binary" | cut -d: -f1)"

  if ! echo "$git_ls_nonbinary_files" | parallel typos {} ; then
    >&2 echo "Typos found: Valid new words can be added to '_typos.toml'"
    return 1
  fi

# automatically fix all typos
[no-exit-message]
typos-fix-all:
  #!/usr/bin/env bash
  set -eo pipefail

  git_ls_files="$(git ls-files)"
  git_ls_nonbinary_files="$(echo "$git_ls_files" | xargs file --mime | grep -v "; charset=binary" | cut -d: -f1)"

  if ! echo "$git_ls_nonbinary_files" | parallel typos -w {} ; then
    >&2 echo "Typos found: Valid new words can be added to '_typos.toml'"
    # TODO: not enforcing anything right, just being annoying in the CLI
    # return 1
  fi

# run code formatters
format:
  cargo fmt --all
  nixpkgs-fmt $(echo **.nix)
