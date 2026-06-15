#!/usr/bin/bash

set -e

# Ensure downloader is available
apt-get update -y  >/dev/null
apt-get -y install --no-install-recommends ca-certificates curl  >/dev/null

# See instructions at https://code.claude.com/docs/en/setup

# https://chatgpt.com/codex/install.sh
CODEX_NON_INTERACTIVE=1 \
  CODEX_INSTALL_DIR=/usr/local/bin \
  VERSION="$VERSION" \
  bash "$(dirname "$0")/bootstrap.sh"

# clean up apt-get
apt-get clean  >/dev/null
rm -rf /var/lib/apt/lists/*  >/dev/null

echo 'Done!'

