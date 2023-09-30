#!/usr/bin/env bash

set -euo pipefail

# Copy over README.md from the book and fix links.
echo -n > README.md
{
  printf '<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->\n\n'
  sed -e 's#(\.#(./docs#g' < docs/README.md
  echo "# Flakebox Book ToC"
  echo
  echo "The best way to view the Flakebox documentation is by running:"
  echo
  echo '```'
  echo 'nix build github:rustshop/flakebox#docs && xdg-open result/index.html'
  echo '```'
  echo
  echo "In projects already using Flakebox, the documentation can be accessed using \`flakebox docs\` command."
  echo ""
  sed -e 's#(\.#(./docs#g' < docs/SUMMARY.md 
  printf '\n<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->'
  echo
} >> README.md

# Copy generated results/nixos-options.md to the checked-in location.
nix build .#docs && cp -f result/nixos-options.md docs/
