#!/usr/bin/bash
# Usage: [VERSION=...] test/run.sh <feature> <test_script>
# Installs src/<feature>/install.sh then runs the given test script.

set -e

FEATURE="$1"
TEST_SCRIPT="$2"

if [ -z "$FEATURE" ] || [ -z "$TEST_SCRIPT" ]; then
    echo "Usage: [VERSION=...] $0 <feature> <test_script>" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Put test/ on PATH so `source dev-container-features-test-lib` finds the bundled lib
export PATH="$SCRIPT_DIR:$PATH"

VERSION="${VERSION:-latest}"
_REMOTE_USER="${_REMOTE_USER:-$(id -un)}"

echo "=== Installing feature: $FEATURE (version: $VERSION) ==="

if [ "$(id -u)" = "0" ]; then
    VERSION="$VERSION" _REMOTE_USER="$_REMOTE_USER" \
        bash "$REPO_ROOT/src/$FEATURE/install.sh"
elif command -v sudo >/dev/null 2>&1; then
    sudo env VERSION="$VERSION" _REMOTE_USER="$_REMOTE_USER" \
        bash "$REPO_ROOT/src/$FEATURE/install.sh"
else
    echo "WARNING: not root and no sudo — skipping install (assuming feature is pre-installed)" >&2
fi

echo ""
echo "=== Running: $TEST_SCRIPT ==="
bash "$TEST_SCRIPT"
