#!/usr/bin/bash

set -e

# Ensure downloader is available
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -y >/dev/null
    apt-get -y install --no-install-recommends ca-certificates curl >/dev/null
fi

# See instructions at https://code.claude.com/docs/en/setup

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
curl -fsSL https://claude.ai/install.sh -o "$INSTALLER"

# Expand positional arguments in the remote user's shell.
# shellcheck disable=SC2016
su "$_REMOTE_USER" -s /bin/bash \
    -c 'export HOME="$1"; exec bash -s -- "$2"' \
    -- bash "$REMOTE_HOME" "${VERSION:-latest}" < "$INSTALLER"

ln -sf "$REMOTE_HOME/.local/bin/claude" /usr/local/bin/claude

# clean up apt-get
apt-get clean  >/dev/null
rm -rf /var/lib/apt/lists/*  >/dev/null

echo 'Done!'
