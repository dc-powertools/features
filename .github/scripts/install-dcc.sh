#!/usr/bin/bash
# Install the latest stable dcc release for subsequent GitHub Actions steps.
set -euo pipefail

: "${GITHUB_PATH:?GITHUB_PATH must point to the workflow PATH file}"

case "$(uname -s)/$(uname -m)" in
    Linux/x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
    Linux/aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
    *) echo "Unsupported platform for the CI dcc installer" >&2; exit 1 ;;
esac

ARCHIVE="dcc-${TARGET}.tar.gz"
RELEASE="$(curl -fsSL --retry 3 https://api.github.com/repos/dc-powertools/dcc/releases/latest)"
DOWNLOAD_URL="$(jq -er --arg name "$ARCHIVE" \
    '.assets[] | select(.name == $name) | .browser_download_url' <<< "$RELEASE")"
SHA256="$(jq -er --arg name "$ARCHIVE" \
    '.assets[] | select(.name == $name) | .digest | select(type == "string") |
     select(test("^sha256:[0-9a-f]{64}$")) | ltrimstr("sha256:")' <<< "$RELEASE")"

INSTALL_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/dcc.XXXXXX")"
curl -fsSL --retry 3 "$DOWNLOAD_URL" -o "$INSTALL_DIR/$ARCHIVE"
printf '%s  %s\n' "$SHA256" "$INSTALL_DIR/$ARCHIVE" | sha256sum -c -
tar -xzf "$INSTALL_DIR/$ARCHIVE" -C "$INSTALL_DIR" dcc
"$INSTALL_DIR/dcc" --version
printf '%s\n' "$INSTALL_DIR" >> "$GITHUB_PATH"
