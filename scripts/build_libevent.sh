#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
# Adapted from https://github.com/tmux/tmux-builds (see LICENSE).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

export CC="${CC:-${PREFIX}/bin/musl-gcc -static}"

mkdir -p "$PREFIX/src"
cd "$PREFIX/src"
fetch_verified \
    "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz" \
    "$LIBEVENT_SHA256" "libevent-${LIBEVENT_VERSION}-stable.tar.gz"
tar xzf "libevent-${LIBEVENT_VERSION}-stable.tar.gz"
cd "libevent-${LIBEVENT_VERSION}-stable"

./configure \
    --prefix="$PREFIX" \
    --includedir="${PREFIX}/include" \
    --libdir="${PREFIX}/lib" \
    --disable-shared \
    --disable-openssl \
    --disable-libevent-regress \
    --disable-samples

make -j"$(ncpu)"
make install

rm -rf "$PREFIX/src"
