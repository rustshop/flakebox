#!/usr/bin/env bash

# This sad script will have to do for now.
sed -e 's#(\.#(./docs#g' < docs/README.md > README.md
