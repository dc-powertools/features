#!/usr/bin/env bash
# Verify the image-controlled package layout after installation or dcc preparation.
set -eu
_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
# shellcheck source=../dev-container-features-test-lib
source "$_LIB"
ROOT="${CODEX_HOME:-$HOME/.codex}"
check 'Codex CLI starts through relocated payload' codex --version
for CHILD in packages tmp; do
    check "$CHILD has the stable image target" test "$(readlink "$ROOT/$CHILD")" = "/opt/dcc-local/codex/$CHILD"
    check "$CHILD target is writable by remote user" test -w "$ROOT/$CHILD"
done
check 'daemon package exists in the image' test -x "$ROOT/packages/app-server-daemon/current/bin/codex"
check 'standalone package exists in the image' test -x "$ROOT/packages/standalone/current/bin/codex"
check 'socket control root stays durable' test ! -L "$ROOT/app-server-control"
check 'mixed daemon settings root stays durable' test ! -L "$ROOT/app-server-daemon"
check 'user plugin marketplace root stays durable' test ! -L "$ROOT/.tmp"
reportResults
