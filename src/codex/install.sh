#!/usr/bin/bash

set -e

# Ensure downloader and daemon process inspection are available
PACKAGES=()
if ! command -v curl >/dev/null 2>&1; then
    PACKAGES+=(ca-certificates curl)
fi
if ! command -v ps >/dev/null 2>&1; then
    PACKAGES+=(procps)
fi
if [ "${#PACKAGES[@]}" -gt 0 ]; then
    apt-get update -y >/dev/null
    apt-get -y install --no-install-recommends "${PACKAGES[@]}" >/dev/null
fi

REMOTE_HOME="${_REMOTE_USER_HOME:-}"
if [ -z "$REMOTE_HOME" ]; then
  REMOTE_HOME="$(getent passwd "$_REMOTE_USER" | cut -d: -f6)"
fi
if [ -z "$REMOTE_HOME" ]; then
  echo "Could not determine home directory for $_REMOTE_USER." >&2
  exit 1
fi

INSTALLER="$(mktemp)"
trap 'rm -f "$INSTALLER"' EXIT
curl -fsSL https://chatgpt.com/codex/install.sh -o "$INSTALLER"

CODEX_NON_INTERACTIVE=1 \
  CODEX_HOME='' \
  CODEX_RELEASE="${VERSION:-latest}" \
  su "$_REMOTE_USER" -s /bin/sh -c "HOME='$REMOTE_HOME' sh -s" < "$INSTALLER"

ln -sf "$REMOTE_HOME/.local/bin/codex" /usr/local/bin/codex

# clean up apt-get
apt-get clean  >/dev/null
rm -rf /var/lib/apt/lists/*  >/dev/null

echo 'Done!'
