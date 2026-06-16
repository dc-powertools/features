#!/usr/bin/bash
# Copy features that have no published git tag for their current version into
# .publish-staging/, so devcontainers/action only publishes what is new.
# Outputs: needs_publish=N to $GITHUB_OUTPUT (or /dev/null when run locally).
set -e

STAGING="${GITHUB_WORKSPACE:-.}/.publish-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
NEEDS_PUBLISH=0

for feature_json in src/*/devcontainer-feature.json; do
    feature="$(basename "$(dirname "$feature_json")")"
    version="$(jq -r .version "$feature_json")"
    tag="${feature}@${version}"

    if git tag --list "$tag" | grep -qF "$tag"; then
        echo "${feature} ${version}: already published"
    else
        cp -r "src/${feature}" "$STAGING/"
        echo "${feature} ${version}: queued for publishing"
        NEEDS_PUBLISH=$((NEEDS_PUBLISH + 1))
    fi
done

echo "needs_publish=${NEEDS_PUBLISH}" >> "${GITHUB_OUTPUT:-/dev/null}"
