#!/usr/bin/env bash

set -euo pipefail

# Copy over README.md from the book and fix links.
printf '<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->\n\n' > README.md
{
  sed -e 's#(\.#(./docs#g' < docs/README.md >> README.md
  echo "# Full Flakebox Book ToC"
  echo ""
  echo "Note: Documentation for the exact version of Flakebox used is available via 'flakebox docs' command."
  echo ""
  sed -e 's#(\.#(./docs#g' < docs/SUMMARY.md 
} >> README.md
printf '\n<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->' >> README.md

# Copy generated results/nixos-options.md to the checked-in location.
nix build .#docs && cp -f result/nixos-options.md docs/