#!/usr/bin/bash

# if running in direnv
if [ -n "${DIRENV_IN_ENVRC:-}" ]; then
  # and not set DIRENV_LOG_FORMAT
  if [ -n "${DIRENV_LOG_FORMAT:-}" ]; then
    >&2 echo "💡 Set 'DIRENV_LOG_FORMAT=\"\"' in your shell environment variables for a cleaner output of direnv"
  fi
fi

>&2 echo "💡 Run 'just' for a list of available 'just ...' helper recipes"

flakebox init

dot_git="$(git rev-parse --git-common-dir)"
if [[ ! -d "''${dot_git}/hooks" ]]; then mkdir "''${dot_git}/hooks"; fi

