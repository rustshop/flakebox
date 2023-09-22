#!/usr/bin/env bash

set -euo pipefail

git_cmd="nix run nixpkgs#git --"

flake_nix_template="$1"

if [ -z "$flake_nix_template" ] || [ ! -f "$flake_nix_template" ]; then
  >&2 echo "❌ No flake nix template found. Expected to be executed as a part of 'nix run ...' invocation"
  exit 1
fi
  
if [ ! -e "Cargo.toml" ]; then
  >&2 echo "⛔ No Cargo.toml found. Re-run in a root directory of a Rust project"
  exit 1
fi

if ! $git_cmd rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  >&2 echo "⛔ Expected to be executed in a local git repository"
  exit 1
fi

if [ -e "flake.nix" ]; then
  >&2 echo "⛔ 'flake.nix' already exist. Delete and try again or integrate the following template manually:"
  cat "$flake_nix_template"
  exit 1
fi

# cat to set permissions to default
cat < "$flake_nix_template" > flake.nix
$git_cmd add flake.nix

>&2 echo "✅ Successfully installed"
>&2 echo "ℹ️  Commit new files to make the changes permanent."
>&2 echo "ℹ️  Run 'nix develop' to start the dev shell"
