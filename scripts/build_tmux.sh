#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
# Adapted from https://github.com/tmux/tmux-builds (see LICENSE).
#
# Static musl build of the pinned upstream tmux into $PREFIX/bin/tmux. Needs
# build_musl.sh, build_libevent.sh and build_ncurses.sh to have run.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

export CC="${CC:-${PREFIX}/bin/musl-gcc -static}"

"${SCRIPTDIR}/fetch_tmux.sh"
cd "${PREFIX}/src/tmux"
sh autogen.sh

./configure \
    --prefix="${PREFIX}" \
    --includedir="${PREFIX}/include" \
    --libdir="${PREFIX}/lib" \
    --enable-static \
    LIBEVENT_LIBS="-L${PREFIX}/lib -levent" \
    LIBNCURSES_CFLAGS="-I${PREFIX}/include/ncurses" \
    LIBNCURSES_LIBS="-L${PREFIX}/lib -lncurses" \
    LIBTINFO_CFLAGS="-I${PREFIX}/include/ncurses" \
    LIBTINFO_LIBS="-L${PREFIX}/lib -ltinfo" \
    CFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CPPFLAGS="-I${PREFIX}/include"

make -j"$(ncpu)"
make install

rm -rf "${PREFIX}/src"
