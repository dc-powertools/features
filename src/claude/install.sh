#!/usr/bin/env bash

set -e

# See instructions at https://code.claude.com/docs/en/setup

# https://downloads.claude.ai/claude-code-releases/bootstrap.sh
bash "$(dirname "$0")/bootstrap.sh" "$VERSION"

# Copy the binary to /usr/local/bin for global access
cp "$HOME/.local/bin/claude" /usr/local/bin/claude

echo 'Done!'

