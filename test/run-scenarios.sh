#!/usr/bin/bash
# Run all scenarios for a feature defined in test/<feature>/scenarios.json.
# Usage: test/run-scenarios.sh <feature>

set -e

FEATURE="$1"
if [ -z "$FEATURE" ]; then
    echo "Usage: $0 <feature>" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCENARIOS_FILE="$SCRIPT_DIR/$FEATURE/scenarios.json"

if [ ! -f "$SCENARIOS_FILE" ]; then
    echo "No scenarios.json found at $SCENARIOS_FILE" >&2
    exit 1
fi

SETUP_HOOK="$SCRIPT_DIR/$FEATURE/setup.sh"
if [ -f "$SETUP_HOOK" ]; then
    # shellcheck source=/dev/null
    source "$SETUP_HOOK"
fi

FAILED=0

while IFS= read -r scenario; do
    TEST_SCRIPT="$SCRIPT_DIR/$FEATURE/${scenario}.sh"
    if [ ! -f "$TEST_SCRIPT" ]; then
        echo "Warning: skipping scenario '$scenario' — no test script at $TEST_SCRIPT" >&2
        continue
    fi

    # Extract feature options as uppercase env var assignments (VERSION=stable, FMT=false, etc.)
    readarray -t ENV_ARGS < <(
        jq -r --arg feature "$FEATURE" --arg scenario "$scenario" \
            '.[$scenario].features[$feature] // {} | to_entries[] | "\(.key | ascii_upcase)=\(.value | tostring)"' \
            "$SCENARIOS_FILE"
    )

    echo ""
    if type setup &>/dev/null; then setup; fi

    if ! env "${ENV_ARGS[@]}" "$SCRIPT_DIR/run.sh" "$FEATURE" "$TEST_SCRIPT"; then
        FAILED=$((FAILED + 1))
    fi

    if type teardown &>/dev/null; then teardown; fi
done < <(jq -r 'keys[]' "$SCENARIOS_FILE")

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "$FAILED scenario(s) failed for feature: $FEATURE" >&2
    exit 1
fi
