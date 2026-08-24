# Dev Container Powertools - Features

## Repo and Feature Structure

Similar to the [`devcontainers/features`](https://github.com/devcontainers/features) repo, this repository has a `src` folder.  Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`. 

```
├── src
│   ├ <feature>
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
...
```

[dcc](https://github.com/dc-powertools/dcc) will composite [the documented dev container properties](https://containers.dev/implementors/features/#devcontainer-feature-json-properties) from the feature's `devcontainer-feature.json` file, execute the `install.sh` entrypoint during `dcc build`, and store feature runtime metadata in the image's `devcontainer.metadata` label. dcc-specific runtime behavior lives under `customizations.dcc`, including named commands and declared state.

## Distributing Features

### Versioning

Features are individually versioned by the `version` attribute in a Feature's `devcontainer-feature.json`.  Features are versioned according to the semver specification. More details can be found in [the dev container Feature specification](https://containers.dev/implementors/features/#versioning).

### Publishing

Features are easily sharable units of dev container configuration and installation code.  

This repo contains a **GitHub Action** [workflow](.github/workflows/release.yaml) that will publish each Feature to GHCR. 

Each Feature will be prefixed with the `<owner>/<repo>` namespace:

```
ghcr.io/dc-powertools/features/<feature>:1
```

The `release` GitHub Action will also publish a third "metadata" package with just the namespace: `ghcr.io/dc-powertools/features`.  This contains information useful for tools aiding in Feature discovery.
