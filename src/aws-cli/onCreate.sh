#!/usr/bin/bash
set -e

AWS_DIR="$HOME/.aws"
CONFIG_FILE="$AWS_DIR/config"
SEED="${AWS_CLI_CONFIG_SEED:-/usr/local/share/aws-cli/config}"

if [ -f "$SEED" ] && [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$AWS_DIR"
    cp "$SEED" "$CONFIG_FILE"
fi
