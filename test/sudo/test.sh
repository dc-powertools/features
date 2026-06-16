#!/usr/bin/env bash

set -e

_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
# shellcheck source=../dev-container-features-test-lib
[ -f "$_LIB" ] && source "$_LIB" || source dev-container-features-test-lib

check "sudo is installed" sudo --version
check "remote user can sudo without password" sudo true

reportResults
