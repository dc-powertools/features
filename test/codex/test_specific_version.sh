#!/usr/bin/env bash

set -e

bash "$(dirname "$0")/test.sh"

EXPECTED_VERSION="${VERSION:-0.156.1}"
ACTUAL_VERSION="$(codex --version)"
if [ "$ACTUAL_VERSION" != "codex-cli $EXPECTED_VERSION" ]; then
    echo "Expected codex-cli $EXPECTED_VERSION, got $ACTUAL_VERSION" >&2
    exit 1
fi
echo "Requested Codex version $EXPECTED_VERSION is installed."
