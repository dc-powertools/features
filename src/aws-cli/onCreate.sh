#!/usr/bin/bash
set -e

if [ -z "$AWS_CONFIG_FILE" ]; then
    exit 0
fi

mkdir -p "$(dirname "$AWS_CONFIG_FILE")"

SEED="/usr/local/share/aws-cli/config"
if [ -f "$SEED" ] && [ ! -f "$AWS_CONFIG_FILE" ]; then
    cp "$SEED" "$AWS_CONFIG_FILE"
fi
