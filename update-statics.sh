#!/usr/bin/env bash

set -euo pipefail

# Copy over README.md from the book and fix links.
echo -n > README.md
{
  printf '<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->\n\n'
  sed -e 's#(\.#(./docs#g' < docs/README.md
  echo "# Full Flakebox Book ToC"
  echo ""
  echo "Note: Documentation for the exact version of Flakebox used is available via \`flakebox docs\` command."
  echo ""
  sed -e 's#(\.#(./docs#g' < docs/SUMMARY.md 
  printf '\n<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->'
  echo
} >> README.md

# Copy generated results/nixos-options.md to the checked-in location.
nix build .#docs && cp -f result/nixos-options.md docs/
