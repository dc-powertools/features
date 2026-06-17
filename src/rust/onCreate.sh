#!/usr/bin/bash

set -e

if [ -z "$(find "$RUSTUP_HOME" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    mkdir -p "$RUSTUP_HOME"
    cp -a /usr/local/rustup/. "$RUSTUP_HOME/"
fi

if [ -z "$(find "$CARGO_HOME" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    mkdir -p "$CARGO_HOME"
    cp -a /usr/local/cargo/. "$CARGO_HOME/"
fi
