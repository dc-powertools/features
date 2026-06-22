#!/usr/bin/bash

set -e

export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo

VERSION="${VERSION:-stable}"
FMT="${FMT:-true}"
CLIPPY="${CLIPPY:-true}"
GCC="${GCC:-true}"

apt-get update -y >/dev/null
apt-get -y install --no-install-recommends ca-certificates curl >/dev/null

if [ "$GCC" = "true" ]; then
    apt-get -y install --no-install-recommends gcc >/dev/null
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

mkdir -p /usr/local/share/rust
cp "$(dirname "$0")/onCreate.sh" /usr/local/share/rust/onCreate.sh

cat > /etc/profile.d/rust.sh <<'EOF'
export PATH="${CARGO_HOME}/bin:${PATH}"
EOF

chown -R "$_REMOTE_USER:$_REMOTE_USER" "$RUSTUP_HOME" "$CARGO_HOME"

rustc --version
cargo --version

apt-get clean >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null

echo 'Done!'
