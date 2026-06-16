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

check "node version is 22.14.0" sh -c "node --version | grep 'v22.14.0'"
check "npm is installed" npm --version

reportResults
