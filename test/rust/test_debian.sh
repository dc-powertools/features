#!/usr/bin/env bash
# shellcheck disable=SC2016

set -e

export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export PATH="$CARGO_HOME/bin:$PATH"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
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
check "rustfmt is installed" rustfmt --version
check "clippy is installed" cargo clippy --version
check "gcc is installed" gcc --version
check "rustup home uses container HOME" grep -qF \
    '"RUSTUP_HOME": "${containerEnv:HOME}/.rustup"' \
    "$REPO_ROOT/src/rust/devcontainer-feature.json"
check "cargo home uses container HOME" grep -qF \
    '"CARGO_HOME": "${containerEnv:HOME}/.cargo"' \
    "$REPO_ROOT/src/rust/devcontainer-feature.json"
check "cargo bin is added to dcc runtime PATH" grep -qF \
    '"PATH": "${containerEnv:HOME}/.cargo/bin:${containerEnv:PATH}"' \
    "$REPO_ROOT/src/rust/devcontainer-feature.json"
check "rust state includes rustup path" grep -qF \
    '"${containerEnv:HOME}/.rustup"' \
    "$REPO_ROOT/src/rust/devcontainer-feature.json"
check "rust state includes cargo path" grep -qF \
    '"${containerEnv:HOME}/.cargo"' \
    "$REPO_ROOT/src/rust/devcontainer-feature.json"
check "rust state includes target path" grep -qF \
    '"${containerWorkspaceFolder}/target"' \
    "$REPO_ROOT/src/rust/devcontainer-feature.json"

reportResults
