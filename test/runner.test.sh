#!/usr/bin/env bash
# Offline regression: sudo discards inherited options, as on the CI runner.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/test/probe" "$FIXTURE/src/probe" "$FIXTURE/bin"
cp "$REPO_ROOT/test/run.sh" "$REPO_ROOT/test/run-scenarios.sh" "$FIXTURE/test/"
cat > "$FIXTURE/bin/id" <<'SCRIPT'
#!/usr/bin/env bash
if [ "$1" = -u ]; then printf '%s\n' "${RUNNER_TEST_UID:-1000}"; else /usr/bin/id "$@"; fi
SCRIPT
cat > "$FIXTURE/bin/sudo" <<'SCRIPT'
#!/usr/bin/env bash
# Reproduce sudo accepting explicit assignments but ignoring -E.
if [ "${1:-}" = -E ]; then shift; fi
exec env -i PATH="$PATH" "$@"
SCRIPT
chmod +x "$FIXTURE/bin/id" "$FIXTURE/bin/sudo"
export PATH="$FIXTURE/bin:$PATH"
export _REMOTE_USER=runner _REMOTE_USER_HOME='/home/test runner'
export _CONTAINER_USER=container _CONTAINER_USER_HOME='/home/test container'
unset UNSETOPTION

cat > "$FIXTURE/src/probe/devcontainer-feature.json" <<'JSON'
{"options":{"version":{},"trustWorkspaceRecursively":{},"package":{},"browsers":{},"fmt":{},"value":{},"emptyOption":{},"unsetOption":{}}}
JSON
cat > "$FIXTURE/src/probe/install.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
[ "$VERSION" = '1.2.3' ]
[ "$TRUSTWORKSPACERECURSIVELY" = true ]
[ "$PACKAGE" = shellcheck ]
[ "$BROWSERS" = all ]
[ "$FMT" = false ]
[ "$VALUE" = $'spaces = and \'quotes\'\nsecond line $(false)' ]
[ "${EMPTYOPTION+x}" = x ] && [ -z "$EMPTYOPTION" ]
[ "${UNSETOPTION+x}" != x ]
[ "$_REMOTE_USER" = runner ] && [ "$_REMOTE_USER_HOME" = '/home/test runner' ]
[ "$_CONTAINER_USER" = container ] && [ "$_CONTAINER_USER_HOME" = '/home/test container' ]
printf 'installed\n' > "$(dirname "$0")/installed"
SCRIPT
cat > "$FIXTURE/test/probe/check.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
test "$(cat "$(dirname "$0")/../../src/probe/installed")" = installed
SCRIPT
jq -n --arg value $'spaces = and \'quotes\'\nsecond line $(false)' \
    '{check:{features:{probe:{version:"1.2.3",trustWorkspaceRecursively:true,package:"shellcheck",browsers:"all",fmt:false,value:$value,emptyOption:""}}}}' \
    > "$FIXTURE/test/probe/scenarios.json"

# Exercise direct callers with arbitrary values, including newlines, without
# relying on the scenario reader's separate line-oriented JSON conversion.
for RUNNER_TEST_UID in 0 1000; do
    export RUNNER_TEST_UID
    env VERSION=1.2.3 TRUSTWORKSPACERECURSIVELY=true PACKAGE=shellcheck \
        BROWSERS=all FMT=false EMPTYOPTION='' \
        VALUE=$'spaces = and \'quotes\'\nsecond line $(false)' \
        "$FIXTURE/test/run.sh" probe "$FIXTURE/test/probe/check.sh"
done

# Full scenario path, using the same conversion as real Feature CI.
# Newlines are outside that reader's existing line-oriented assignment format.
jq '.["check"].features.probe.value = "spaces = and quotes $(false)"' \
    "$FIXTURE/test/probe/scenarios.json" > "$FIXTURE/scenarios.json"
mv "$FIXTURE/scenarios.json" "$FIXTURE/test/probe/scenarios.json"
# Adapt the probe's expected value; preserve literal shell syntax in the probe.
# shellcheck disable=SC2016
sed -i '/^\[ "$VALUE" = /c\[ "$VALUE" = '\''spaces = and quotes $(false)'\'' ]' \
    "$FIXTURE/src/probe/install.sh"
"$FIXTURE/test/run-scenarios.sh" probe
printf 'Runner option forwarding passed for root, stripped sudo, and scenarios.\n'
