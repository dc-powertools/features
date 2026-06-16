# Architecture

## Overview

This repository publishes [devcontainer features](https://containers.dev/implementors/features/) for use with [dcc](https://github.com/dc-powertools/dcc), a CLI that manages ephemeral devcontainers. Each feature is a self-contained unit of installation logic and configuration that dcc composes into a container at build time.

Features are published to GitHub Container Registry (GHCR) and referenced in devcontainer configurations by their OCI image path:

```
ghcr.io/dc-powertools/features/<feature>:<version>
```

---

## Repository Layout

```
src/
  <feature>/
    devcontainer-feature.json   # metadata, options, env, mounts
    install.sh                  # entrypoint, runs as root at build time
    [bootstrap.sh]              # optional: delegated installer (runs as remote user)
    [onCreate.sh]               # optional: runs inside container after creation

test/
  dev-container-features-test-lib   # bundled test library (check / reportResults)
  run.sh                            # test runner: installs a feature then runs a script
  <feature>/
    scenarios.json              # maps scenario names to feature option sets
    test.sh                     # default test script
    test_debian.sh              # scenario-specific scripts (name matches scenarios.json key)
    test_specific_version.sh

.devcontainer/
  <feature>.json                # local devcontainer profile for developing each feature

.github/workflows/
  test.yaml                     # CI: runs on push/PR, installs features and runs tests
  release.yaml                  # manual: publishes features to GHCR
```

---

## Feature Anatomy

### `devcontainer-feature.json`

The manifest consumed by dcc and the devcontainers spec. Key fields:

| Field | Purpose |
|---|---|
| `id` | Short identifier; must match the directory name |
| `version` | Semver string; increment on every published change |
| `options` | Named parameters users can pass; injected as uppercase env vars into `install.sh` (e.g. `version` → `VERSION`) |
| `containerEnv` | Environment variables set inside the container at runtime |
| `mounts` | Additional bind mounts or volumes added to the container |
| `command` | Binary that dcc verifies exists after installation |
| `onCreateCommand` | Script run inside the container after it is first created |

### `install.sh`

Runs as **root** inside the container during the build step. The devcontainer runtime injects two additional variables beyond the feature's own options:

- `$_REMOTE_USER` — the non-root user that will use the container (e.g. `dev`)
- `$VERSION` — the value of the `version` option (if the feature declares one)

Install scripts follow a consistent pattern:

1. `apt-get install` runtime dependencies
2. Download, verify (SHA256), and install the tool
3. Expose the binary on PATH (symlink into `/usr/local/bin/` or extract tarball to `/usr/local/`)
4. `apt-get clean` / remove apt lists

### `bootstrap.sh`

Used by `claude` and `codex` because those installers must run as the remote user (they install into `~/.local/bin`). `install.sh` delegates to `bootstrap.sh` via `su "$_REMOTE_USER" -c "..."`, then creates a system-wide symlink as root.

### `onCreate.sh`

Used by `codex` to create `$CODEX_HOME` the first time the container starts. Registered via `onCreateCommand` in the manifest so dcc runs it after creation but before first use.

---

## dcc Variable System

dcc extends the standard devcontainer variable set with cache-aware variables:

| Variable | Resolves to | Notes |
|---|---|---|
| `${containerCacheFolder}` | `/cache` inside the container | Persistent across `dcc run` invocations; backed by a host-side bind mount |
| `${localCacheFolder}` | `.dcc/<profile>/` on the host | Host-side source for the above; dcc auto-creates subdirectories used in mounts |
| `${containerWorkspaceFolder}` | Workspace path inside the container | Standard devcontainer variable |

### Cache usage patterns

**Environment variable** (claude, codex): point a tool's state directory at the cache folder so it survives container rebuilds.

```json
"containerEnv": {
    "CLAUDE_CONFIG_DIR": "${containerCacheFolder}/.claude"
}
```

**Bind mount** (node): overlay a cache-backed directory on top of the workspace, so `node_modules` installed by `npm install` persists across runs without being committed to the repository.

```json
"mounts": [
    {
        "source": "${localCacheFolder}/node_modules",
        "target": "${containerWorkspaceFolder}/node_modules",
        "type": "bind"
    }
]
```

---

## Features

| Feature | What it installs | Cache strategy |
|---|---|---|
| `claude` | Claude Code CLI | `CLAUDE_CONFIG_DIR` → `${containerCacheFolder}/.claude` |
| `codex` | OpenAI Codex CLI | `CODEX_HOME` → `${containerCacheFolder}/.codex` |
| `node` | Node.js (system-wide) | bind mount `node_modules` from `${localCacheFolder}/node_modules` |
| `sudo` | sudo + passwordless grant for `$_REMOTE_USER` | none |

---

## Test Infrastructure

### `test/dev-container-features-test-lib`

A bundled implementation of the two functions all test scripts use:

- `check "<description>" <command> [args]` — runs a command; records pass/fail
- `reportResults` — prints a summary and exits non-zero if any check failed

This file exists so tests work outside the devcontainers testing framework (e.g. inside a CI container, or via `dcc run`). The real framework library shadows it when present. Test scripts source it via a relative path so they resolve it regardless of the working directory:

```bash
_LIB="$(cd "$(dirname "$0")/.." && pwd)/dev-container-features-test-lib"
[ -f "$_LIB" ] && source "$_LIB" || source dev-container-features-test-lib
```

### `test/run.sh`

Installs a feature and then runs a test script. Handles three privilege contexts:

- **Root** (inside a devcontainer) — runs `install.sh` directly
- **Has sudo** (GitHub Actions `ubuntu-latest`) — runs `install.sh` via `sudo env ...`
- **Neither** (pre-built dcc container) — skips install, warns, runs the test script against the already-installed feature

```
[VERSION=...] test/run.sh <feature> <test_script>
```

### CI Workflows

**`test.yaml`** runs on every push and pull request to `main`. For each feature it runs `test/run.sh` with the default version and with any pinned-version scenarios. Uses `ubuntu-latest` runners — no Docker required.

**`release.yaml`** is triggered manually and only runs on `main`. Uses `devcontainers/action` to publish all features to GHCR.
