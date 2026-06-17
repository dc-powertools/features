#!/usr/bin/bash

set -e

# Install prerequisites
apt-get update -y >/dev/null
if command -v curl >/dev/null 2>&1; then
    apt-get -y install --no-install-recommends ca-certificates xz-utils libatomic1 >/dev/null
else
    apt-get -y install --no-install-recommends ca-certificates curl xz-utils libatomic1 >/dev/null
fi

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  NODE_ARCH="x64" ;;
    aarch64) NODE_ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac

# Resolve SHASUMS URL from VERSION option
VERSION="${VERSION:-latest}"
case "$VERSION" in
    latest | "")
        SHASUMS_URL="https://nodejs.org/dist/latest/SHASUMS256.txt"
        ;;
    *.**)
        # Full semver like "22.14.0" (contains at least two dots)
        SHASUMS_URL="https://nodejs.org/dist/v${VERSION}/SHASUMS256.txt"
        ;;
    [0-9]*)
        # Major version only like "22"
        SHASUMS_URL="https://nodejs.org/dist/latest-v${VERSION}.x/SHASUMS256.txt"
        ;;
    *)
        echo "Invalid version: '$VERSION'. Use 'latest', a major like '22', or full semver like '22.14.0'." >&2
        exit 1
        ;;
esac

echo "Fetching Node.js release info..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

SHASUMS_FILE="$TMP_DIR/SHASUMS256.txt"
curl -fsSL "$SHASUMS_URL" -o "$SHASUMS_FILE"

# Extract tarball name and expected SHA256 for our architecture
TARBALL_ENTRY="$(grep -E "node-v[0-9]+\.[0-9]+\.[0-9]+-linux-${NODE_ARCH}\.tar\.xz$" "$SHASUMS_FILE" | head -n1)"
if [ -z "$TARBALL_ENTRY" ]; then
    echo "No linux-${NODE_ARCH} tarball entry found in SHASUMS256.txt" >&2
    exit 1
fi

TARBALL_NAME="$(echo "$TARBALL_ENTRY" | awk '{print $2}')"
EXPECTED_SHA256="$(echo "$TARBALL_ENTRY" | awk '{print $1}')"

DIST_DIR_URL="${SHASUMS_URL%/SHASUMS256.txt}"
TARBALL_URL="${DIST_DIR_URL}/${TARBALL_NAME}"

echo "Downloading ${TARBALL_NAME}..."
TARBALL_PATH="$TMP_DIR/$TARBALL_NAME"
curl -fsSL "$TARBALL_URL" -o "$TARBALL_PATH"

echo "Verifying checksum..."
ACTUAL_SHA256="$(sha256sum "$TARBALL_PATH" | awk '{print $1}')"
if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
    echo "SHA256 mismatch!" >&2
    echo "  expected: $EXPECTED_SHA256" >&2
    echo "  actual:   $ACTUAL_SHA256" >&2
    exit 1
fi

echo "Installing to /usr/local/..."
tar -xJf "$TARBALL_PATH" -C /usr/local/ --strip-components=1

node --version
npm --version

# Clean up apt lists
apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null

echo 'Done!'
