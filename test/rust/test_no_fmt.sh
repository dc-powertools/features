#!/usr/bin/env bash

set -e

export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
export PATH="/usr/local/cargo/bin:$PATH"

_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
if [ -f "$_LIB" ]; then
    # shellcheck source=../dev-container-features-test-lib
    source "$_LIB"
else
    # shellcheck disable=SC1091
    source dev-container-features-test-lib
fi

check "rustc is installed" rustc --version
check "cargo is installed" cargo --version
check "clippy is installed" cargo clippy --version

reportResults
