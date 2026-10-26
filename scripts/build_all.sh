#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
#
# Local build of everything the workflow builds, on a Linux host with
# build-essential, automake, bison, pkg-config, curl and git:
#   PREFIX=/tmp/build scripts/build_all.sh
# The binary lands in $PREFIX/bin/tmux.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

"${SCRIPTDIR}/build_musl.sh"
export CC="${PREFIX}/bin/musl-gcc -static"
"${SCRIPTDIR}/build_libevent.sh"
"${SCRIPTDIR}/build_ncurses.sh"
"${SCRIPTDIR}/build_tmux.sh"
"${SCRIPTDIR}/verify_tmux.sh"
"${SCRIPTDIR}/smoke_pb_state.sh" "${PREFIX}/bin/tmux"
