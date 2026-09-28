#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI="${1:?absolute Playwright CLI path is required}"
BROWSERS="$(cat "$SCRIPT_DIR/browsers")"
case "$BROWSERS" in
    chromium|firefox|webkit|all) ;;
    *) echo "Invalid browsers option: $BROWSERS" >&2; exit 1 ;;
esac
case "$CLI" in
    /*) ;;
    *) echo "Playwright CLI path must be absolute" >&2; exit 1 ;;
esac

CLI_VERSION="$(node "$CLI" --version)"
VERSION="${CLI_VERSION#Version }"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    echo "Could not determine Playwright version: $CLI_VERSION" >&2
    exit 1
fi

STATE_FILE="$SCRIPT_DIR/deps-state"
STATE="$VERSION $BROWSERS"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$STATE" ]; then
    echo "Playwright: dependencies already installed for $STATE."
    exit 0
fi

if [ "$(id -u)" != "0" ]; then
    # Feature dependency supplies passwordless sudo for the remote user.
    exec sudo -n -- "$SCRIPT_DIR/install-deps.sh" "$CLI"
fi

ARGS=(install-deps)
if [ "$BROWSERS" != "all" ]; then
    ARGS+=("$BROWSERS")
fi
echo "Playwright: installing system dependencies for $STATE."
node "$CLI" "${ARGS[@]}"

# Record only successful installs, in the same filesystem as the OS packages.
STATE_TMP="$(mktemp "$SCRIPT_DIR/.deps-state.XXXXXX")"
trap 'rm -f "$STATE_TMP"' EXIT
printf '%s\n' "$STATE" > "$STATE_TMP"
chmod 0644 "$STATE_TMP"
mv -f "$STATE_TMP" "$STATE_FILE"
