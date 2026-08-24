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
    devcontainer-feature.json   # metadata, options, env, mounts, dcc customizations
    install.sh                  # entrypoint, runs as root at build time
    [bootstrap.sh]              # optional: delegated installer (runs as remote user)
    [postStart.sh]              # optional: runs when a dcc profile container starts

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
| `containerEnv` | Environment variables baked into the image before `install.sh` runs |
| `remoteEnv` | Environment variables set at runtime; use for values derived from `${containerEnv:HOME}` |
| `mounts` | Additional bind mounts or volumes added to the container |
| `customizations.dcc.commands` | Named commands exposed through `dcc run <feature>:<name>` |
| `customizations.dcc.state` | Container paths persisted under the profile cache and seeded from the image |
| `onCreateCommand`, `updateContentCommand`, `postCreateCommand` | Build-preparation hooks run during `dcc build` |
| `postStartCommand` | Runtime startup hook run when a profile container starts |

### `install.sh`

Runs as **root** inside the container during the build step. The devcontainer runtime injects two additional variables beyond the feature's own options:

- `$_REMOTE_USER` — the container user that will use the container (e.g. `dev`)
- `$_REMOTE_USER_HOME` — that user's home directory
- `$_CONTAINER_USER` / `$_CONTAINER_USER_HOME` — aliases supplied for compatibility with current dcc
- `$VERSION` — the value of the `version` option (if the feature declares one)

Install scripts follow a consistent pattern:

1. `apt-get install` runtime dependencies
2. Download, verify (SHA256), and install the tool
3. Expose the binary on PATH (symlink into `/usr/local/bin/` or extract tarball to `/usr/local/`)
4. `apt-get clean` / remove apt lists

### `bootstrap.sh`

Used by `claude` and `codex` because those installers must run as the remote user (they install into `~/.local/bin`). `install.sh` delegates to `bootstrap.sh` via `su "$_REMOTE_USER" -c "HOME='$_REMOTE_USER_HOME' ..."`, then creates a system-wide symlink as root.

### `postStart.sh`

Used for runtime synchronization that needs profile mounts or host files. `git` copies the mounted host git config, and `aws-cli` seeds the persisted AWS config directory. These hooks are registered as `postStartCommand` because current dcc runs `onCreateCommand` during build preparation.

---

## dcc Variable System

dcc extends the standard devcontainer variable set with cache-aware variables:

| Variable | Resolves to | Notes |
|---|---|---|
| `${containerCacheFolder}` | `/cache` inside the container | Persistent across `dcc run` invocations; backed by a host-side bind mount |
| `${localCacheFolder}` | `.dcc/<profile>/` on the host | Host-side source for the above; dcc auto-creates subdirectories used in mounts |
| `${containerWorkspaceFolder}` | Workspace path inside the container | Standard devcontainer variable |

### State and cache usage patterns

The preferred way to preserve tool state is `customizations.dcc.state`. State
paths are container paths, can use `${containerEnv:HOME}` for arbitrary
`containerUser` support, and are seeded from the built image before build-prep
hooks run.

```json
"remoteEnv": {
    "CLAUDE_CONFIG_DIR": "${containerEnv:HOME}/.claude"
},
"customizations": {
    "dcc": {
        "state": [
            "${containerEnv:HOME}/.claude"
        ]
    }
}
```

Explicit bind mounts are still useful for host files or non-state mount shapes.
Mount sources under `${localCacheFolder}` are created automatically. For normal
workspace artifacts, prefer state:

```json
"customizations": {
    "dcc": {
        "state": [
            "${containerWorkspaceFolder}/node_modules"
        ]
    }
}
```

---

## Features

| Feature | What it installs | Cache strategy |
|---|---|---|
| `aws-cli` | AWS CLI v2 | state: `${containerEnv:HOME}/.aws`; seeded in `postStartCommand` |
| `claude` | Claude Code CLI | state: `${containerEnv:HOME}/.claude`; `CLAUDE_CONFIG_DIR` in `remoteEnv` |
| `codex` | OpenAI Codex CLI | state: `${containerEnv:HOME}/.codex`; `CODEX_HOME` in `remoteEnv` |
| `linux-package` | A system package via apt/dnf/yum | none |
| `mo` | mo coding harness | state: `${containerEnv:HOME}/.mo`; `MO_HOME` in `remoteEnv` |
| `node` | Node.js (system-wide) | state: `${containerWorkspaceFolder}/node_modules` |
| `playwright` | Playwright browser system dependencies | depends on `node`; browser packages live in Node-managed `node_modules` |
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
