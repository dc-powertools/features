#!/usr/bin/env bash
# shellcheck disable=SC2016

set -e

_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
if [ -f "$_LIB" ]; then
    # shellcheck source=../dev-container-features-test-lib
    source "$_LIB"
else
    # shellcheck disable=SC1091
    source dev-container-features-test-lib
fi

check "node is installed" node --version
check "npm is installed" npm --version
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
check "node_modules is declared as dcc state" grep -qF \
    '"${containerWorkspaceFolder}/node_modules"' \
    "$REPO_ROOT/src/node/devcontainer-feature.json"

reportResults
