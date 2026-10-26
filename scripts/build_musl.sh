#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
# Adapted from https://github.com/tmux/tmux-builds (see LICENSE).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "$PREFIX/src"
cd "$PREFIX/src"
fetch_verified "https://musl.libc.org/releases/musl-${MUSL_VERSION}.tar.gz" \
    "$MUSL_SHA256" "musl-${MUSL_VERSION}.tar.gz"
tar xzf "musl-${MUSL_VERSION}.tar.gz"
cd "musl-${MUSL_VERSION}"

./configure \
    --enable-gcc-wrapper \
    --disable-shared \
    --prefix="${PREFIX}"

make -j"$(ncpu)"
make install

rm -rf "$PREFIX/src"
