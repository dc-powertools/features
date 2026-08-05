#!/usr/bin/bash

set -e

REMOTE_USER="${_REMOTE_USER:-}"
if [ -z "$REMOTE_USER" ]; then
    echo "_REMOTE_USER is required to install mo." >&2
    exit 1
fi

REMOTE_HOME="$(getent passwd "$REMOTE_USER" | cut -d: -f6)"
if [ -z "$REMOTE_HOME" ]; then
    echo "Could not determine home directory for $REMOTE_USER." >&2
    exit 1
fi

REMOTE_GROUP="$(id -gn "$REMOTE_USER")"
HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"

apt-get update -y >/dev/null
apt-get -y install --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    file \
    git \
    procps \
    >/dev/null

if ! command -v brew >/dev/null 2>&1 && [ ! -x "$HOMEBREW_PREFIX/bin/brew" ]; then
    rm -rf "$HOMEBREW_PREFIX/Homebrew"
    mkdir -p "$HOMEBREW_PREFIX/bin"
    chown -R "$REMOTE_USER:$REMOTE_GROUP" /home/linuxbrew
    su "$REMOTE_USER" -s /usr/bin/bash -c \
        "HOME='$REMOTE_HOME' git clone --depth=1 https://github.com/Homebrew/brew '$HOMEBREW_PREFIX/Homebrew'"
    ln -sf ../Homebrew/bin/brew "$HOMEBREW_PREFIX/bin/brew"
    chown -h "$REMOTE_USER:$REMOTE_GROUP" "$HOMEBREW_PREFIX/bin/brew"
fi

if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
elif [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
    BREW_BIN="$HOMEBREW_PREFIX/bin/brew"
else
    echo "Homebrew installation failed." >&2
    exit 1
fi

su "$REMOTE_USER" -s /usr/bin/bash -c \
    "HOME='$REMOTE_HOME' HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 '$BREW_BIN' install momentohq/tap/mo"

BREW_PREFIX="$("$BREW_BIN" --prefix)"
ln -sf "$BREW_PREFIX/bin/mo" /usr/local/bin/mo

mkdir -p /usr/local/share/mo/
cp "$(dirname "$0")/onCreate.sh" /usr/local/share/mo/onCreate.sh

apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null

echo 'Done!'
