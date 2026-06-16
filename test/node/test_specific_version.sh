#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "node version is 22.14.0" sh -c "node --version | grep 'v22.14.0'"
check "npm is installed" npm --version

reportResults
