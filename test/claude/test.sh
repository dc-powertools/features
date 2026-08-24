#!/usr/bin/env bash
# shellcheck disable=SC2016

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

check "claude is installed" claude --version
check "claude config dir uses container HOME" grep -qF \
    '"CLAUDE_CONFIG_DIR": "${containerEnv:HOME}/.claude"' \
    "$REPO_ROOT/src/claude/devcontainer-feature.json"
check "claude state uses container HOME" grep -qF \
    '"${containerEnv:HOME}/.claude"' \
    "$REPO_ROOT/src/claude/devcontainer-feature.json"
check "claude commands use customizations.dcc.commands" grep -qF \
    '"claude": "claude --continue"' \
    "$REPO_ROOT/src/claude/devcontainer-feature.json"
check "claude manifest has no top-level scripts" sh -c \
    '! grep -qF "\"scripts\"" "$1"' sh "$REPO_ROOT/src/claude/devcontainer-feature.json"

reportResults
