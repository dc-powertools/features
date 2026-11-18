# Codex persistence layout

The Codex Feature in `src/codex` uses image-controlled executable packages from
Feature version 0.2.0 and requires dcc 0.4.0 or newer. It defaults to Codex `latest`.
Its metadata uses the `directory-with-exclusions` state type so older dcc versions
reject it. This promotes the former local T-0108 pilot; the remaining platform and
updater qualification is deferred by the maintainer for this release.

The persistent CODEX_HOME excludes only `packages` and `tmp`, linked to stable writable image directories under
`/opt/dcc-local/codex`. The Feature installs both standalone and daemon packages
before relocating them in the same installation layer. Scratch targets start empty
and owned by the remote user. Runtime updates remain ephemeral; rebuilding is the
supported durable upgrade and rollback mechanism. Installer and daemon pruning
skip symlink package roots, so repeated runtime updates can accumulate releases
until container replacement. Explicit installer selection 0.169.0 → 0.168.0 →
0.169.0 succeeded through the package symlink, including daemon package selection;
the installer emitted the expected skipped-pruning warning. This verifies explicit
version reselection, not automatic updater failure recovery or rollback.

Keep `.tmp` persistent: it includes installed user marketplaces, plugin caches,
share-local-path records and trusted Git staging that must stay under CODEX_HOME.
Keep `app-server-control` persistent: upstream rejects a symlink socket parent
with "socket directory path exists and is not a directory". Anonymous-volume
fallback or upstream support is needed before that scratch directory can be
excluded. Its stale sockets are handled by upstream, rather than deleted by dcc.

Keep runtime `app-server-daemon` persistent: settings save atomically through a
sibling temporary file, and `loaded-threads.json` is recovery state. A file bind or
settings symlink cannot safely split that directory. The Feature does not delete
process records, locks, logs or unknown files. Upstream validates process identity
and recovers stale PID records under its locks. Provisioning the daemon in the
image is necessary: stale logs plus a missing ephemeral daemon package otherwise
make both `bootstrap` and `start` demand installation repair after recreation.

Linux ARM64 investigation used Codex 0.169.0, Docker 29.9.3, classic overlay2 and
upstream source revision `662a634e88fcc809d77da393d75572c3d814cb27`.
Disposable-container checks verified concurrent daemon bootstrap, replacement
with retained preferences and stale process records, and ephemeral marker reset.
With default Docker seccomp, sandbox setup fails before execution for both layouts.
With seccomp unconfined in disposable test containers, relocated payload executed
`codex sandbox -- /bin/echo sandbox-ok`; the unmodified baseline failed executing
its protected CODEX_HOME package. This is a scoped qualification, not a reason to
change dcc security defaults. macOS/Desktop, authenticated remote control,
cross-version daemon migration and automatic updater rollback remain unqualified.

Primary implementation references (paths at the revision above):

- [Installer](https://github.com/openai/codex/blob/662a634e88fcc809d77da393d75572c3d814cb27/scripts/install/install.sh): daemon-only provisioning, install locks and symlink pruning guards.
- [Daemon settings](https://github.com/openai/codex/blob/662a634e88fcc809d77da393d75572c3d814cb27/codex-rs/app-server-daemon/src/settings.rs): preferences and atomic replacement.
- [Daemon preparation](https://github.com/openai/codex/blob/662a634e88fcc809d77da393d75572c3d814cb27/codex-rs/app-server-daemon/src/prepare_install.rs): missing-package versus previous-launch detection.
- [PID backend](https://github.com/openai/codex/blob/662a634e88fcc809d77da393d75572c3d814cb27/codex-rs/app-server-daemon/src/backend/pid.rs): serialized stale-record recovery.
- [Plugin storage](https://github.com/openai/codex/blob/662a634e88fcc809d77da393d75572c3d814cb27/codex-rs/core-plugins/src/installed_marketplaces.rs): `.tmp/marketplaces` user installations.

Run `bash test/codex/test_debian.sh` inside the prepared image; it includes
`test/codex/persistence.sh` layout checks. Integration must use an isolated profile/cache,
never existing user credentials or history.

## Coordinated Linux integration

Compatible dcc source: `0331498d5fe4d86125ec692e9907426b3b71a59f` (0.3.0).
Final frozen CLI SHA256:
`35bf36c0e808c50f86426a4df5b4529b9158832af4a758766f8f7e801b9f3b6e`.
The local-reference profile built image
`sha256:5293f5feec835c314ddc711513646f46961d46fd76d06d9a099e922aa2e2afd3`.
Layout checks (10/10), existing Debian checks (2/2), daemon operation, rebuild and
replacement passed with retained preferences/history/marketplace caches and reset
package/tmp markers. This is historical pilot evidence, not qualification of the promoted release.
The compatible dcc 0.4.0 release is available; remaining qualification is deferred.
