#!/usr/bin/bash

set -e

# Ensure downloader is available
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -y >/dev/null
    apt-get -y install --no-install-recommends ca-certificates curl >/dev/null
fi

# See instructions at https://code.claude.com/docs/en/setup

# https://chatgpt.com/codex/install.sh
REMOTE_HOME="${_REMOTE_USER_HOME:-}"
if [ -z "$REMOTE_HOME" ]; then
  REMOTE_HOME="$(getent passwd "$_REMOTE_USER" | cut -d: -f6)"
fi
if [ -z "$REMOTE_HOME" ]; then
  echo "Could not determine home directory for $_REMOTE_USER." >&2
  exit 1
fi

CODEX_NON_INTERACTIVE=1 \
  CODEX_HOME='' \
  VERSION="$VERSION" \
  su "$_REMOTE_USER" -c "HOME='$REMOTE_HOME' '$(dirname "$0")/bootstrap.sh'"

ln -sf "$REMOTE_HOME/.local/bin/codex" /usr/local/bin/codex

# clean up apt-get
apt-get clean  >/dev/null
rm -rf /var/lib/apt/lists/*  >/dev/null

echo 'Done!'
