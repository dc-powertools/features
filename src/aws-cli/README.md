# AWS CLI Feature

This feature installs AWS CLI v2 and caches the full `$HOME/.aws` directory by
mounting `${localCacheFolder}/.aws` at `${containerEnv:HOME}/.aws`.

The feature assumes AWS CLI path-related environment variables are left at their
default behavior, so AWS config, credentials, SSO cache, CLI history, and related
files stay under `$HOME/.aws`.

If `AWS_CONFIG_FILE`, `AWS_SHARED_CREDENTIALS_FILE`, `AWS_CLI_HISTORY_FILE`, or
`AWS_DATA_PATH` are set to paths outside `$HOME/.aws`, those files may bypass
the cached directory. This feature does not reset or override those variables.
