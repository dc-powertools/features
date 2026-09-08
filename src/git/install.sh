#!/usr/bin/bash
set -e

apt-get update -y >/dev/null
apt-get -y install --no-install-recommends git >/dev/null
mkdir -p /usr/local/share/git/
cp "$(dirname "$0")/postStart.sh" /usr/local/share/git/postStart.sh
chmod 0755 /usr/local/share/git/postStart.sh

TRUST_WORKSPACE_RECURSIVELY="${TRUSTWORKSPACERECURSIVELY:-false}"
case "$TRUST_WORKSPACE_RECURSIVELY" in
    true|false) ;;
    *)
        echo "trustWorkspaceRecursively must be true or false" >&2
        exit 1
        ;;
esac
printf '%s\n' "$TRUST_WORKSPACE_RECURSIVELY" \
    > /usr/local/share/git/trust-workspace-recursively
chmod 0644 /usr/local/share/git/trust-workspace-recursively

apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null
echo 'Done!'
