#!/usr/bin/env bash

set -euo pipefail

docs_build_command='nix build github:rustshop/flakebox#docs'
options_summary_entry='- [Config Options](./nixos-options.md)'

if [[ $(grep -Fxc -- "$options_summary_entry" docs/SUMMARY.md) -ne 1 ]]; then
  echo "error: expected exactly one config-options entry in docs/SUMMARY.md" >&2
  exit 1
fi

# Copy over README.md from the book and fix links.
echo -n > README.md
{
  printf '<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->\n\n'
  sed -e 's#(\.#(./docs#g' < docs/README.md
  printf '\n'
  echo "# Flakebox Book ToC"
  echo
  echo "The best way to view the Flakebox documentation is by running:"
  echo
  echo '```'
  echo "$docs_build_command"
  echo '```'
  echo
  echo 'Then open `result/index.html` in a browser.'
  echo
  echo "In projects already using Flakebox, the documentation can be accessed using the \`flakebox docs\` command."
  echo
  awk -v entry="$options_summary_entry" -v command="$docs_build_command" '
    $0 == entry {
      print "- Config options: run `flakebox docs`, or `" command "`; then open `result/index.html` in a browser"
      next
    }
    { gsub(/\(\./, "(./docs"); print }
  ' docs/SUMMARY.md
  printf '\n<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->'
  echo
} >> README.md
