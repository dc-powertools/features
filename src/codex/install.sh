#!/usr/bin/bash

set -e

# Ensure downloader is available
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -y >/dev/null
    apt-get -y install --no-install-recommends ca-certificates curl >/dev/null
fi

# See instructions at https://code.claude.com/docs/en/setup

# https://chatgpt.com/codex/install.sh
CODEX_NON_INTERACTIVE=1 \
  CODEX_HOME='' \
  VERSION="$VERSION" \
  su "$_REMOTE_USER" -c "'$(dirname "$0")/bootstrap.sh'"

ln -sf "/home/$_REMOTE_USER/.local/bin/codex" /usr/local/bin/codex

mkdir -p /usr/local/share/codex/
cp {./,/usr/local/share/codex/}onCreate.sh

# clean up apt-get
apt-get clean  >/dev/null
rm -rf /var/lib/apt/lists/*  >/dev/null

echo 'Done!'

