#!/usr/bin/bash

set -e

PACKAGE="${PACKAGE:-}"
YUMPACKAGE="${YUMPACKAGE:-}"

if [ -z "$PACKAGE" ]; then
    echo "The 'package' option is required." >&2
    exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null
    apt-get -y install --no-install-recommends "$PACKAGE" >/dev/null
    apt-get clean >/dev/null
    rm -rf /var/lib/apt/lists/* >/dev/null
elif command -v dnf >/dev/null 2>&1; then
    PKG="${YUMPACKAGE:-$PACKAGE}"
    dnf install -y "$PKG" >/dev/null
    dnf clean all >/dev/null
elif command -v yum >/dev/null 2>&1; then
    PKG="${YUMPACKAGE:-$PACKAGE}"
    yum install -y "$PKG" >/dev/null
    yum clean all >/dev/null
else
    echo "No supported package manager found (apt-get, dnf, or yum)." >&2
    exit 1
fi

echo "Done!"
