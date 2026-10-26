#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
#
# Shared helpers, sourced by the other scripts. Adapted from
# https://github.com/tmux/tmux-builds (see LICENSE): versions come from
# versions.env, every download is verified against a pinned sha256.

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../versions.env
source "${SCRIPTDIR}/../versions.env"

PREFIX="${PREFIX:-/tmp/build}"
export PREFIX

# fetch_verified URL SHA256 FILE: download URL to FILE and check its sha256.
fetch_verified() {
    local url="$1" sha="$2" file="$3"
    curl -fsSL --retry 3 --retry-delay 2 -o "$file" "$url"
    echo "${sha}  ${file}" | sha256sum -c -
}

# Number of CPUs for make -j.
ncpu() {
    nproc 2>/dev/null || getconf _NPROCESSORS_ONLN
}
