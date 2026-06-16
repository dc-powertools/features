#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "node is installed" node --version
check "npm is installed" npm --version

reportResults
