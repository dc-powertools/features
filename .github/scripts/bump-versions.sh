#!/usr/bin/bash
# Bump the patch version in devcontainer-feature.json for any feature
# whose src/ files changed since BEFORE_SHA without a corresponding version update.
# Usage: bump-versions.sh <before-sha>
set -e

BEFORE_SHA="${1?Usage: $0 <before-sha>}"

if [ "$BEFORE_SHA" = "0000000000000000000000000000000000000000" ]; then
    echo "Initial push — skipping version bump check."
    echo "bumped=0" >> "${GITHUB_OUTPUT:-/dev/null}"
    exit 0
fi

BUMPED=0

for feature_json in src/*/devcontainer-feature.json; do
    feature="$(basename "$(dirname "$feature_json")")"

    # No changes in src/<feature>/ since BEFORE_SHA → nothing to do
    if git diff --quiet "${BEFORE_SHA}" HEAD -- "src/${feature}/"; then
        continue
    fi

    current_version="$(jq -r .version "$feature_json")"
    before_version="$(git show "${BEFORE_SHA}:${feature_json}" 2>/dev/null | jq -r '.version // empty' || echo "")"

    # Version was already updated in this push → skip
    if [ -n "$before_version" ] && [ "$current_version" != "$before_version" ]; then
        echo "${feature}: version already bumped (${before_version} → ${current_version})"
        continue
    fi

    # Bump patch component: major.minor.patch → major.minor.(patch+1)
    IFS='.' read -r major minor patch <<< "$current_version"
    new_version="${major}.${minor}.$((patch + 1))"

    tmp="$(mktemp)"
    jq --arg v "$new_version" '.version = $v' "$feature_json" > "$tmp"
    mv "$tmp" "$feature_json"

    echo "${feature}: ${current_version} → ${new_version}"
    BUMPED=$((BUMPED + 1))
done

echo "bumped=${BUMPED}" >> "${GITHUB_OUTPUT:-/dev/null}"
