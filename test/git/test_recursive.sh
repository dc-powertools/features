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

check "git is installed" git --version
check "recursive workspace trust is enabled" grep -qxF \
    'true' /usr/local/share/git/trust-workspace-recursively

_HOME="$(mktemp -d)"
_WORKSPACE="$_HOME/project root"
mkdir -p "$_WORKSPACE/nested/repository"
git init -q "$_WORKSPACE"
git init -q "$_WORKSPACE/nested/repository"

HOME="$_HOME" HOST_GITCONFIG="$_HOME/missing-gitconfig" \
    bash /usr/local/share/git/postStart.sh "$_WORKSPACE"

check "git trusts the workspace root" env HOME="$_HOME" sh -c \
    'git config --global --get-all safe.directory | grep -Fqx -- "$1"' sh "$_WORKSPACE"
check "git trusts repositories below the workspace" env HOME="$_HOME" sh -c \
    'git config --global --get-all safe.directory | grep -Fqx -- "$1/*"' sh "$_WORKSPACE"
check "git accepts a differently owned workspace root" env HOME="$_HOME" \
    GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C "$_WORKSPACE" status --short
check "git accepts a differently owned nested repository" env HOME="$_HOME" \
    GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C "$_WORKSPACE/nested/repository" status --short
check "recursive trust remains bounded to the workspace" env HOME="$_HOME" sh -c \
    '! git config --global --get-all safe.directory | grep -Fqx -- "*"'

HOME="$_HOME" HOST_GITCONFIG="$_HOME/missing-gitconfig" \
    bash /usr/local/share/git/postStart.sh "$_WORKSPACE"
check "git records each workspace trust entry once" env HOME="$_HOME" sh -c \
    'test "$(git config --global --get-all safe.directory | grep -Fxc -- "$1")" -eq 1 && test "$(git config --global --get-all safe.directory | grep -Fxc -- "$1/*")" -eq 1' \
    sh "$_WORKSPACE"

rm -rf "$_HOME"

reportResults
