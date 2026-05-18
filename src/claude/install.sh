#!/usr/bin/env bash

set -e

# Ensure downloader is available
apt-get update -y  >/dev/null
apt-get -y install --no-install-recommends ca-certificates curl  >/dev/null

# See instructions at https://code.claude.com/docs/en/setup

# https://downloads.claude.ai/claude-code-releases/bootstrap.sh
bash "$(dirname "$0")/bootstrap.sh" "$VERSION"

# Copy the binary to /usr/local/bin for global access
cp "$HOME/.local/bin/claude" /usr/local/bin/claude

# clean up apt-get
apt-get clean  >/dev/null
rm -rf /var/lib/apt/lists/*  >/dev/null

echo 'Done!'

