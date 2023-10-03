#!/usr/bin/env bash

# pretend this is an e2e test
cargo test ${CARGO_PROFILE:+--profile $CARGO_PROFILE}
