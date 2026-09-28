#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_FOLDER="${1:?workspace folder argument is required}"

if [ "$(cat "$SCRIPT_DIR/install-on-start")" != "true" ]; then
    exit 0
fi
cd "$WORKSPACE_FOLDER"
if [ ! -f package.json ]; then
    echo "Node: no package.json in workspace; skipping npm install."
    exit 0
fi

PACKAGE_MANAGER="$(node -e '
    const fs = require("node:fs");
    const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
    const manager = pkg.packageManager || pkg.devEngines?.packageManager?.name;
    if (manager) {
        console.log(manager.split("@")[0]);
    } else if (fs.existsSync("package-lock.json") || fs.existsSync("npm-shrinkwrap.json")) {
        console.log("npm");
    } else if (["pnpm-lock.yaml", "yarn.lock", "bun.lock", "bun.lockb"].some(p => fs.existsSync(p))) {
        console.log("other");
    } else {
        console.log("npm");
    }
')"
if [ "$PACKAGE_MANAGER" != "npm" ]; then
    echo "Node: project uses $PACKAGE_MANAGER; skipping npm install."
    exit 0
fi

echo "Node: installing workspace packages."
npm install --no-audit --no-fund
