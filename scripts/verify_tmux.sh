#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
#
# verify_tmux.sh [TMUX_BINARY]: the binary is static, reports the pinned
# version, and carries the terminfo search path of Debian, Ubuntu and Fedora.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

bin="${1:-${PREFIX}/bin/tmux}"

file "$bin"
file "$bin" | grep -qE 'statically linked|static-pie linked' || { echo "FAIL: $bin is not statically linked" >&2; exit 1; }
if ldd "$bin" >/dev/null 2>&1; then
    echo "FAIL: ldd finds a dynamic loader for $bin" >&2
    exit 1
fi

ver="$("$bin" -V)"
echo "$ver"
[[ "$ver" == "tmux ${TMUX_VERSION}" ]] || { echo "FAIL: expected 'tmux ${TMUX_VERSION}'" >&2; exit 1; }

strings "$bin" | grep -qx '/etc/terminfo:/lib/terminfo:/usr/share/terminfo' \
    || { echo "FAIL: terminfo search path not baked in" >&2; exit 1; }
echo "verify: ok"
