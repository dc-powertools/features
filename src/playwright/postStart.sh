#!/usr/bin/bash
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WORKSPACE_FOLDER="${1:-$PWD}"
CLI="$(node "$SCRIPT_DIR/resolve-cli.cjs" "$WORKSPACE_FOLDER")"
if [ -z "$CLI" ]; then
    echo "Playwright: no installed workspace package; keeping build-time dependencies."
    exit 0
fi
exec "$SCRIPT_DIR/install-deps.sh" "$CLI"
