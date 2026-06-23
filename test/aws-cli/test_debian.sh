#!/usr/bin/env bash

set -e

_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
if [ -f "$_LIB" ]; then
    # shellcheck source=../dev-container-features-test-lib
    source "$_LIB"
else
    # shellcheck disable=SC1091
    source dev-container-features-test-lib
fi

check "aws is installed" aws --version

_HOME="$(mktemp -d)"
_SEED="$(mktemp)"
printf '[default]\nregion = us-east-1\n' > "$_SEED"

HOME="$_HOME" AWS_CLI_CONFIG_SEED="$_SEED" bash /usr/local/share/aws-cli/onCreate.sh

check "onCreate seeds config under HOME .aws directory" \
    grep -qF "region = us-east-1" "$_HOME/.aws/config"
check "onCreate does not create a literal tilde path" \
    test ! -e "$_HOME/~/.aws/config"

printf '[default]\nregion = us-west-2\n' > "$_HOME/.aws/config"
HOME="$_HOME" AWS_CLI_CONFIG_SEED="$_SEED" bash /usr/local/share/aws-cli/onCreate.sh

check "onCreate preserves existing config" \
    grep -qF "region = us-west-2" "$_HOME/.aws/config"

rm -rf "$_HOME" "$_SEED"

reportResults
