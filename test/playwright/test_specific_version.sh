#!/usr/bin/env bash
set -e

EXPECTED_VERSION="${VERSION:-1.61.0}"
EXPECTED_BROWSERS="${BROWSERS:-chromium}"
ACTUAL_STATE="$(cat /usr/local/share/playwright/deps-state)"
if [ "$ACTUAL_STATE" != "$EXPECTED_VERSION $EXPECTED_BROWSERS" ]; then
    echo "Expected $EXPECTED_VERSION $EXPECTED_BROWSERS, got $ACTUAL_STATE" >&2
    exit 1
fi
echo "Pinned Playwright dependencies recorded: $ACTUAL_STATE"
