#!/usr/bin/bash
set -e

CONFIG_FILE="~/.aws/config"
SEED="/usr/local/share/aws-cli/config"

if [ -f "$SEED" ] && [ ! -f "$CONFIG_FILE" ]; then
    cp "$SEED" "$CONFIG_FILE"
fi
