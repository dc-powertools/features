#!/usr/bin/bash
# Sourced by run-scenarios.sh -- defines setup/teardown hooks.
# Snapshots installed apt packages before each scenario and purges
# any packages added during the scenario afterward.

_PACKAGES_BEFORE=""

if [ "$(id -u)" = "0" ]; then
    _SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    _SUDO="sudo"
else
    _SUDO=""
fi

setup() {
    _PACKAGES_BEFORE="$(dpkg --get-selections | awk '/\tinstall$/ {print $1}' | sort)"
}

teardown() {
    if [ -z "$_PACKAGES_BEFORE" ]; then
        return
    fi

    local after added
    after="$(dpkg --get-selections | awk '/\tinstall$/ {print $1}' | sort)"
    added="$(comm -13 <(echo "$_PACKAGES_BEFORE") <(echo "$after"))"

    if [ -z "$added" ]; then
        return
    fi

    echo "Removing $(echo "$added" | wc -l) package(s) added by scenario"
    echo "$added" | xargs $_SUDO apt-get purge -y >/dev/null 2>&1 || true
    $_SUDO apt-get autoremove -y >/dev/null 2>&1 || true
}
