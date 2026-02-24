#!/usr/bin/env bash
set -eou pipefail

function job_lint() {
  selfci step start "treefmt"
  if ! treefmt --ci ; then
    selfci step fail
  fi
}

function job_checks() {
    selfci step start "flake check"
    nix flake check -L
}

case "$SELFCI_JOB_NAME" in
  main)
    selfci job start "lint"
    selfci job start "checks"
    ;;
  checks)
    job_checks
    ;;
  lint)
    export -f job_lint
    nix develop -c bash -c "job_lint"
    ;;
  *)
    echo "Unknown job: $SELFCI_JOB_NAME"
    exit 1
esac
