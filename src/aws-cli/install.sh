#!/usr/bin/bash

set -e

SSOSTARTURL="${SSOSTARTURL:-}"
SSOREGION="${SSOREGION:-}"
SSOACCOUNTID="${SSOACCOUNTID:-}"
SSOROLENAME="${SSOROLENAME:-}"
REGION="${REGION:-}"

# Install prerequisites
apt-get update -y >/dev/null
apt-get -y install --no-install-recommends ca-certificates curl unzip >/dev/null

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  AWS_ARCH="x86_64" ;;
    aarch64) AWS_ARCH="aarch64" ;;
    *)
        echo "Unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

echo "Downloading AWS CLI v2 for ${AWS_ARCH}..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "$TMP_DIR/awscliv2.zip"

echo "Installing..."
unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
if [ -x /usr/local/bin/aws ]; then
    "$TMP_DIR/aws/install" --update
else
    "$TMP_DIR/aws/install"
fi

aws --version

# Seed SSO config if both options are provided
mkdir -p /usr/local/share/aws-cli
if [ -n "$SSOSTARTURL" ] && [ -n "$SSOREGION" ]; then
    {
        echo "[sso-session default]"
        echo "sso_start_url = $SSOSTARTURL"
        echo "sso_region = $SSOREGION"
        echo "sso_registration_scopes = sso:account:access"
        PROFILE_REGION="${REGION:-$SSOREGION}"
        if [ -n "$SSOACCOUNTID" ] || [ -n "$SSOROLENAME" ] || [ -n "$PROFILE_REGION" ]; then
            echo ""
            echo "[profile default]"
            echo "sso_session = default"
            [ -n "$SSOACCOUNTID" ] && echo "sso_account_id = $SSOACCOUNTID"
            [ -n "$SSOROLENAME" ] && echo "sso_role_name = $SSOROLENAME"
            [ -n "$PROFILE_REGION" ] && echo "region = $PROFILE_REGION"
        fi
    } > /usr/local/share/aws-cli/config
fi

cp "$(dirname "$0")/onCreate.sh" /usr/local/share/aws-cli/onCreate.sh

# Clean up apt lists
apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null

echo 'Done!'
