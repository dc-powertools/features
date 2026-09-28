#!/usr/bin/bash
set -e

WORKSPACE_FOLDER="${1:?workspace folder argument is required}"
HOST_GITCONFIG="${HOST_GITCONFIG:-/run/host-gitconfig}"
TRUST_WORKSPACE_RECURSIVELY_FILE="${TRUST_WORKSPACE_RECURSIVELY_FILE:-/usr/local/share/git/trust-workspace-recursively}"

if [ -s "$HOST_GITCONFIG" ]; then
    cp "$HOST_GITCONFIG" "$HOME/.gitconfig"
fi

git config --global worktree.useRelativePaths true

add_safe_directory() {
    directory="$1"
    if ! git config --global --get-all safe.directory | grep -Fqx -- "$directory"; then
        git config --global --add safe.directory "$directory"
    fi
}

add_safe_directory "$WORKSPACE_FOLDER"

if [ -r "$TRUST_WORKSPACE_RECURSIVELY_FILE" ] &&
    [ "$(cat "$TRUST_WORKSPACE_RECURSIVELY_FILE")" = "true" ]; then
    add_safe_directory "$WORKSPACE_FOLDER/*"
fi
