#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
# Adapted from https://github.com/tmux/tmux-builds (see LICENSE).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

export CC="${CC:-${PREFIX}/bin/musl-gcc -static}"

mkdir -p "$PREFIX/src"
cd "$PREFIX/src"
fetch_verified "https://invisible-island.net/archives/ncurses/ncurses-${NCURSES_VERSION}.tar.gz" \
    "$NCURSES_SHA256" "ncurses-${NCURSES_VERSION}.tar.gz"
tar xzf "ncurses-${NCURSES_VERSION}.tar.gz"
cd "ncurses-${NCURSES_VERSION}"

# The terminfo search path is baked in: Debian, Ubuntu and Fedora layouts.
./configure \
    --prefix="${PREFIX}" \
    --includedir="${PREFIX}/include" \
    --libdir="${PREFIX}/lib" \
    --without-ada \
    --without-cxx \
    --without-cxx-binding \
    --without-tests \
    --without-manpages \
    --without-debug \
    --disable-lib-suffixes \
    --disable-db-install \
    --with-termlib \
    --with-default-terminfo-dir=/usr/share/terminfo \
    --with-terminfo-dirs=/etc/terminfo:/lib/terminfo:/usr/share/terminfo

make -j"$(ncpu)"
make install

rm -rf "$PREFIX/src"
