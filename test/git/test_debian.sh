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
    '"postStartCommand": "/usr/local/share/git/postStart.sh"' \
    "$REPO_ROOT/src/git/devcontainer-feature.json"
check "git manifest has no build-time onCreate hook" sh -c \
    '! grep -qF "\"onCreateCommand\"" "$1"' sh "$REPO_ROOT/src/git/devcontainer-feature.json"

# Simulate the dcc bind mount: point postStart.sh at a mock host gitconfig
_MOCK="$(mktemp)"
_HOME="$(mktemp -d)"
printf '[user]\n\tname = Test User\n\temail = test@example.com\n' > "$_MOCK"
HOME="$_HOME" HOST_GITCONFIG="$_MOCK" bash /usr/local/share/git/postStart.sh
rm -f "$_MOCK"

check "git user.name is set from host gitconfig" \
    env HOME="$_HOME" sh -c 'git config --global user.name | grep -qF "Test User"'
check "git user.email is set from host gitconfig" \
    env HOME="$_HOME" sh -c 'git config --global user.email | grep -qF "test@example.com"'

rm -rf "$_HOME"

reportResults
