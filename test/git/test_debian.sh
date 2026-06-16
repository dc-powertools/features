#!/usr/bin/bash
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

# Simulate the dcc bind mount: point onCreate.sh at a mock host gitconfig
_MOCK="$(mktemp)"
printf '[user]\n\tname = Test User\n\temail = test@example.com\n' > "$_MOCK"
HOST_GITCONFIG="$_MOCK" bash /usr/local/share/git/onCreate.sh
rm -f "$_MOCK"

check "git user.name is set from host gitconfig" \
    sh -c 'git config --global user.name | grep -qF "Test User"'
check "git user.email is set from host gitconfig" \
    sh -c 'git config --global user.email | grep -qF "test@example.com"'

reportResults
