#!/usr/bin/bash

set -e

apt-get update -y >/dev/null
apt-get -y install --no-install-recommends sudo >/dev/null

echo "$_REMOTE_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$_REMOTE_USER"
chmod 0440 "/etc/sudoers.d/$_REMOTE_USER"

apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null

echo 'Done!'
