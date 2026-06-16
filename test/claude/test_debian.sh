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

check "claude is installed" claude --version

reportResults
