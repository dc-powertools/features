#!/usr/bin/env bash

set -e

_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
# shellcheck source=../dev-container-features-test-lib
[ -f "$_LIB" ] && source "$_LIB" || source dev-container-features-test-lib

check "claude version is equal to 2.0.30" sh -c "claude --version | grep '2.0.30'"

reportResults
