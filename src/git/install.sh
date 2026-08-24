#!/usr/bin/bash
set -e

apt-get update -y >/dev/null
apt-get -y install --no-install-recommends git >/dev/null
mkdir -p /usr/local/share/git/
cp "$(dirname "$0")/postStart.sh" /usr/local/share/git/postStart.sh
chmod 0755 /usr/local/share/git/postStart.sh
apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null
echo 'Done!'
