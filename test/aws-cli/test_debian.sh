#!/usr/bin/env bash
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

check "aws is installed" aws --version
check "aws state uses container HOME" grep -qF \
    '"${containerEnv:HOME}/.aws"' \
    "$REPO_ROOT/src/aws-cli/devcontainer-feature.json"
check "aws commands use customizations.dcc.commands" grep -qF \
    '"sso-login": "aws sso login --use-device-code --profile default"' \
    "$REPO_ROOT/src/aws-cli/devcontainer-feature.json"
check "aws manifest has no top-level scripts" sh -c \
    '! grep -qF "\"scripts\"" "$1"' sh "$REPO_ROOT/src/aws-cli/devcontainer-feature.json"
check "aws manifest has no top-level command" sh -c \
    '! grep -qF "\"command\"" "$1"' sh "$REPO_ROOT/src/aws-cli/devcontainer-feature.json"
check "aws seeds config at runtime startup" grep -qF \
    '"postStartCommand": "/usr/local/share/aws-cli/postStart.sh"' \
    "$REPO_ROOT/src/aws-cli/devcontainer-feature.json"

_HOME="$(mktemp -d)"
_SEED="$(mktemp)"
printf '[default]\nregion = us-east-1\n' > "$_SEED"

HOME="$_HOME" AWS_CLI_CONFIG_SEED="$_SEED" bash /usr/local/share/aws-cli/postStart.sh

check "postStart seeds config under HOME .aws directory" \
    grep -qF "region = us-east-1" "$_HOME/.aws/config"
check "postStart does not create a literal tilde path" \
    test ! -e "$_HOME/~/.aws/config"

printf '[default]\nregion = us-west-2\n' > "$_HOME/.aws/config"
HOME="$_HOME" AWS_CLI_CONFIG_SEED="$_SEED" bash /usr/local/share/aws-cli/postStart.sh

check "postStart preserves existing config" \
    grep -qF "region = us-west-2" "$_HOME/.aws/config"

rm -rf "$_HOME" "$_SEED"

reportResults
