#!/usr/bin/bash
set -e

BROWSERS="${BROWSERS:-chromium}"
case "$BROWSERS" in
    chromium|firefox|webkit|all) ;;
    *) echo "Invalid browsers option: $BROWSERS" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p /usr/local/share/playwright
install -m 0755 "$SCRIPT_DIR/install-deps.sh" "$SCRIPT_DIR/postStart.sh" /usr/local/share/playwright/
install -m 0644 "$SCRIPT_DIR/resolve-cli.cjs" /usr/local/share/playwright/resolve-cli.cjs
printf '%s\n' "$BROWSERS" > /usr/local/share/playwright/browsers
chmod 0644 /usr/local/share/playwright/browsers
ln -sf /usr/local/share/playwright/postStart.sh /usr/local/bin/playwright-install-deps

# Isolate the build-time CLI from the workspace and do not download browsers.
INSTALL_DIR="$(mktemp -d)"
trap 'rm -rf "$INSTALL_DIR"' EXIT
npm install --prefix "$INSTALL_DIR" --cache "$INSTALL_DIR/npm-cache" --no-save --package-lock=false \
    --ignore-scripts --no-audit --no-fund "playwright@${VERSION:-latest}"
/usr/local/share/playwright/install-deps.sh "$INSTALL_DIR/node_modules/playwright/cli.js"

apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null
echo 'Done!'
