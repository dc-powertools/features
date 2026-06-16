#!/usr/bin/bash
set -e

apt-get update -y >/dev/null
apt-get -y install --no-install-recommends git >/dev/null
mkdir -p /usr/local/share/git/
cp "$(dirname "$0")/onCreate.sh" /usr/local/share/git/onCreate.sh
apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null
echo 'Done!'
