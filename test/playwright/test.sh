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
check "playwright depends on node feature" grep -qF \
    '"ghcr.io/dc-powertools/features/node:0": {}' \
    "$REPO_ROOT/src/playwright/devcontainer-feature.json"

# Common/tools packages
check "xvfb is installed" dpkg -s xvfb
check "fonts-liberation is installed" dpkg -s fonts-liberation

# Chromium packages (default)
check "libnss3 is installed" dpkg -s libnss3
check "libnspr4 is installed" dpkg -s libnspr4
check "libgbm1 is installed" dpkg -s libgbm1
check "libdrm2 is installed" dpkg -s libdrm2

reportResults
