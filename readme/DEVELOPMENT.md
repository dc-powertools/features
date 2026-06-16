# Development Guide

## Prerequisites

- [dcc](https://github.com/dc-powertools/dcc) — to build and run features locally
- `shellcheck` — shell script linter (`apt install shellcheck` / `brew install shellcheck`)
- `bash` 4+ and standard POSIX utilities (`awk`, `grep`, `sha256sum`, `tar`)

---

## Adding a New Feature

1. Create `src/<feature>/devcontainer-feature.json` with at minimum `id`, `version`, `name`, and `description`. See [ARCHITECTURE.md](ARCHITECTURE.md) for field reference.
2. Create `src/<feature>/install.sh`. Mark it executable (`chmod +x`). Follow the existing pattern: install deps, download and verify the tool, expose it on PATH, clean up apt lists.
3. Create `.devcontainer/<feature>.json` pointing at `../src/<feature>` so the feature can be run locally with `dcc run <feature>`.
4. Create `test/<feature>/scenarios.json`, `test/<feature>/test.sh`, and `test/<feature>/test_debian.sh`. Add a `test_specific_version.sh` if the feature accepts a `version` option.
5. Add the feature's test jobs to `.github/workflows/test.yaml`.

---

## Running Tests

### Inside a dcc container (feature pre-installed)

```bash
dcc run <feature> -- bash test/<feature>/test.sh
```

The workspace is mounted inside the container. The test script finds `test/dev-container-features-test-lib` via its relative-path source line, so no extra setup is required.

### With `test/run.sh` (installs then tests)

```bash
# Default version
test/run.sh <feature> test/<feature>/test_debian.sh

# Pinned version
VERSION=22.14.0 test/run.sh <feature> test/<feature>/test_specific_version.sh
```

`test/run.sh` installs the feature using root or sudo (whichever is available), adds `test/` to `PATH`, then runs the test script.

---

## Linting

All shell scripts (`install.sh`, `bootstrap.sh`, `onCreate.sh`, `test/run.sh`, test scripts) must pass `shellcheck` before committing.

```bash
# Lint a single file
shellcheck src/<feature>/install.sh

# Lint everything at once
find src test -name '*.sh' -o -name 'dev-container-features-test-lib' \
  | xargs shellcheck -x
```

Common issues to watch for:

- Unquoted variables (`"$VAR"` not `$VAR`)
- `set -e` at the top of every script
- `ln -sf` not `ln -s` (idempotent symlinks)
- No hardcoded paths where `$_REMOTE_USER` or a variable should be used

---

## Committing Changes

Run the following before every commit:

1. **Lint** all modified shell scripts:
   ```bash
   shellcheck <changed files>
   ```

2. **Test** every feature whose `src/` files changed:
   ```bash
   test/run.sh <feature> test/<feature>/test_debian.sh
   ```
   Run the specific-version scenario too if the feature has one.

3. **Commit** with a message that describes *why* the change was made, not just what changed. Include the feature name in the subject when the change is scoped to one feature.

   Good: `node: add libatomic1 to prerequisites`
   Avoid: `fix install script`

---

## Periodic Code Review

Every few weeks (or before any release), review the full project with fresh eyes:

- **Correctness**: do all install scripts handle errors explicitly (`set -e`, non-zero exit on bad input)? Are SHA256 checksums verified before extracting archives?
- **Idempotency**: can each `install.sh` be run twice without failing? (`ln -sf`, `mkdir -p`, apt being re-runnable)
- **Security**: are downloaded binaries verified before execution? Are sudoers files written with `0440` permissions?
- **Consistency**: do all features follow the same apt cleanup pattern (`apt-get clean` + remove `/var/lib/apt/lists/*`)? Do all `ln` calls use `-sf`?
- **Test coverage**: does each feature have at least a default scenario and a version-pinned scenario? Are test assertions specific enough to catch regressions?
- **Stale versions**: are pinned versions in `scenarios.json` and `test_specific_version.sh` still downloadable? Update them when old releases are removed upstream.
- **Dead code**: are there any orphaned scripts, unused variables, or commented-out blocks that should be removed?

When issues are found, fix them in a dedicated cleanup commit rather than bundling them with unrelated changes.
