#!/usr/bin/bash
# shellcheck disable=SC2016
set -e

_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
if [ -f "$_LIB" ]; then
    # shellcheck source=../dev-container-features-test-lib
    source "$_LIB"
else
    # shellcheck disable=SC1091
    source dev-container-features-test-lib
fi

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check "git is installed" git --version
check "git imports config at runtime startup" grep -qF \
    '"postStartCommand": [' \
    "$REPO_ROOT/src/git/devcontainer-feature.json"
check "git passes the workspace path to its startup hook" grep -qF \
    '"${containerWorkspaceFolder}"' \
    "$REPO_ROOT/src/git/devcontainer-feature.json"
check "git manifest has no build-time onCreate hook" sh -c \
    '! grep -qF "\"onCreateCommand\"" "$1"' sh "$REPO_ROOT/src/git/devcontainer-feature.json"
check "recursive workspace trust defaults to false" grep -qxF \
    'false' /usr/local/share/git/trust-workspace-recursively

# Simulate the dcc bind mount: point postStart.sh at a mock host gitconfig
_MOCK="$(mktemp)"
_HOME="$(mktemp -d)"
_WORKSPACE="$_HOME/project root"
mkdir -p "$_WORKSPACE"
git init -q "$_WORKSPACE"
printf '[user]\n\tname = Test User\n\temail = test@example.com\n[safe]\n\tdirectory = /existing/repo\n[worktree]\n\tuseRelativePaths = false\n' > "$_MOCK"
HOME="$_HOME" HOST_GITCONFIG="$_MOCK" \
    bash /usr/local/share/git/postStart.sh "$_WORKSPACE"
rm -f "$_MOCK"

check "git user.name is set from host gitconfig" \
    env HOME="$_HOME" sh -c 'git config --global user.name | grep -qF "Test User"'
check "git user.email is set from host gitconfig" \
    env HOME="$_HOME" sh -c 'git config --global user.email | grep -qF "test@example.com"'
check "git configures worktrees to use relative paths" env HOME="$_HOME" sh -c \
    'test "$(git config --global --type=bool worktree.useRelativePaths)" = "true"'
check "git trusts the workspace root" env HOME="$_HOME" sh -c \
    'git config --global --get-all safe.directory | grep -Fqx -- "$1"' sh "$_WORKSPACE"
check "git accepts a differently owned workspace root" env HOME="$_HOME" \
    GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C "$_WORKSPACE" status --short
check "git preserves existing safe directories" env HOME="$_HOME" sh -c \
    'git config --global --get-all safe.directory | grep -Fqx -- "/existing/repo"'
check "git does not trust nested repos by default" env HOME="$_HOME" sh -c \
    '! git config --global --get-all safe.directory | grep -Fqx -- "$1/*"' sh "$_WORKSPACE"
check "git does not disable ownership checks globally" env HOME="$_HOME" sh -c \
    '! git config --global --get-all safe.directory | grep -Fqx -- "*"'

# Run again without replacing the generated config to verify idempotency.
HOME="$_HOME" HOST_GITCONFIG="$_HOME/missing-gitconfig" \
    bash /usr/local/share/git/postStart.sh "$_WORKSPACE"
check "git records the workspace root once" env HOME="$_HOME" sh -c \
    'test "$(git config --global --get-all safe.directory | grep -Fxc -- "$1")" -eq 1' \
    sh "$_WORKSPACE"

rm -rf "$_HOME"

reportResults
