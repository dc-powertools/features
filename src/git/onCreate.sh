#!/usr/bin/bash
set -e

HOST_GITCONFIG="${HOST_GITCONFIG:-/run/host-gitconfig}"
if [ -s "$HOST_GITCONFIG" ]; then
    cp "$HOST_GITCONFIG" "$HOME/.gitconfig"
fi
