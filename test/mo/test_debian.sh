#!/usr/bin/env bash

set -e

_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
if [ -f "$_LIB" ]; then
    # shellcheck source=../dev-container-features-test-lib
    source "$_LIB"
else
    # shellcheck disable=SC1091
    source dev-container-features-test-lib
fi

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check "mo is installed" mo --version
check "MO_HOME is configured for dcc cache" grep -q "\"MO_HOME\": \"\${containerCacheFolder}/.mo\"" "$REPO_ROOT/src/mo/devcontainer-feature.json"
check "yolo script bypasses mo permissions" grep -q "\"yolo\": \"mo --dangerously-skip-permissions --resume\"" "$REPO_ROOT/src/mo/devcontainer-feature.json"
check "mo onCreate initializes MO_HOME" env MO_HOME=/tmp/dcc-mo-test-home /usr/local/share/mo/onCreate.sh
check "mo onCreate created MO_HOME" test -d /tmp/dcc-mo-test-home

reportResults
