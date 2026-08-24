#!/usr/bin/bash

set -e

VERSION="${VERSION:-stable}"
FMT="${FMT:-true}"
CLIPPY="${CLIPPY:-true}"
GCC="${GCC:-true}"

REMOTE_HOME="${_REMOTE_USER_HOME:-}"
if [ -z "$REMOTE_HOME" ]; then
    REMOTE_HOME="$(getent passwd "$_REMOTE_USER" | cut -d: -f6)"
fi
if [ -z "$REMOTE_HOME" ]; then
    echo "Could not determine home directory for $_REMOTE_USER." >&2
    exit 1
fi

export RUSTUP_HOME="$REMOTE_HOME/.rustup"
export CARGO_HOME="$REMOTE_HOME/.cargo"

apt-get update -y >/dev/null
apt-get -y install --no-install-recommends ca-certificates curl >/dev/null

if [ "$GCC" = "true" ]; then
    apt-get -y install --no-install-recommends gcc libc6-dev >/dev/null
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal --default-toolchain "$VERSION"

export PATH="$CARGO_HOME/bin:$PATH"

if [ "$FMT" = "true" ]; then
    rustup component add rustfmt
fi

if [ "$CLIPPY" = "true" ]; then
    rustup component add clippy
fi

cat > /etc/profile.d/rust.sh <<'EOF'
case ":${PATH}:" in
    *":${CARGO_HOME}/bin:"*) ;;
    *) export PATH="${CARGO_HOME}/bin:${PATH}" ;;
esac
EOF

REMOTE_GROUP="$(id -gn "$_REMOTE_USER")"
chown -R "$_REMOTE_USER:$REMOTE_GROUP" "$RUSTUP_HOME" "$CARGO_HOME"

rustc --version
cargo --version

apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null

echo 'Done!'
