# Agent Guide

This repository contains [devcontainer features](https://containers.dev/implementors/features/) for [dcc](https://github.com/dc-powertools/dcc).

## Reference docs

- [ARCHITECTURE.md](readme/ARCHITECTURE.md) — feature structure, the dcc variable system, test infrastructure, and CI/CD pipeline
- [DEVELOPMENT.md](readme/DEVELOPMENT.md) — how to add a feature, run tests, lint shell scripts, and commit changes

## Key rules

- Every shell script must pass `shellcheck` before committing.
- Run `test/run.sh <feature> test/<feature>/test_debian.sh` for any feature whose `src/` files were modified.
- Use `ln -sf` (not `ln -s`) for all symlinks so installs are idempotent.
- Verify SHA256 checksums before extracting any downloaded archive.
- Write sudoers drop-in files with mode `0440`.
- Periodically review the full project for correctness, consistency, and stale pinned versions — see the "Periodic Code Review" section in DEVELOPMENT.md.
