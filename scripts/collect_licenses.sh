#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
# Adapted from https://github.com/tmux/tmux-builds (see LICENSE).
#
# $PREFIX/LICENSES.tar.gz: the license texts of tmux, libevent, musl and
# ncurses at the pinned versions.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/licenses"

echo "Collecting libevent license..."
curl -fsSL "https://raw.githubusercontent.com/libevent/libevent/release-${LIBEVENT_VERSION}-stable/LICENSE" \
    -o "$work/licenses/LICENSE.libevent"

echo "Collecting musl license..."
fetch_verified "https://musl.libc.org/releases/musl-${MUSL_VERSION}.tar.gz" "$MUSL_SHA256" "$work/musl.tar.gz"
tar xzf "$work/musl.tar.gz" -C "$work" "musl-${MUSL_VERSION}/COPYRIGHT"
cp "$work/musl-${MUSL_VERSION}/COPYRIGHT" "$work/licenses/COPYRIGHT.musl"

echo "Collecting ncurses license..."
fetch_verified "https://invisible-island.net/archives/ncurses/ncurses-${NCURSES_VERSION}.tar.gz" \
    "$NCURSES_SHA256" "$work/ncurses.tar.gz"
tar xzf "$work/ncurses.tar.gz" -C "$work" "ncurses-${NCURSES_VERSION}/COPYING"
cp "$work/ncurses-${NCURSES_VERSION}/COPYING" "$work/licenses/COPYING.ncurses"

echo "Collecting tmux license..."
curl -fsSL "https://raw.githubusercontent.com/tmux/tmux/${TMUX_COMMIT}/COPYING" \
    -o "$work/licenses/COPYING.tmux"

cp "${SCRIPTDIR}/../LICENSE" "$work/licenses/LICENSE.tmux-builds"

mkdir -p "$PREFIX"
tar czf "${PREFIX}/LICENSES.tar.gz" -C "$work/licenses" .
echo "Licenses collected in ${PREFIX}/LICENSES.tar.gz"
