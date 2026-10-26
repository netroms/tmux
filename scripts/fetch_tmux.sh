#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
#
# Check out upstream tmux at the pinned tag into $TMUX_SRC (default
# $PREFIX/src/tmux) and verify the tag still points at the pinned commit.
# No tmux source line is changed: patches, if ever added, live in patches/ and
# are applied by build_tmux.sh, never here.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TMUX_SRC="${TMUX_SRC:-${PREFIX}/src/tmux}"
rm -rf "$TMUX_SRC"
mkdir -p "$(dirname "$TMUX_SRC")"
git clone --quiet --depth 1 --branch "$TMUX_VERSION" https://github.com/tmux/tmux.git "$TMUX_SRC"
got="$(git -C "$TMUX_SRC" rev-parse "${TMUX_VERSION}^{commit}")"
if [[ "$got" != "$TMUX_COMMIT" ]]; then
    echo "Error: upstream tag ${TMUX_VERSION} is ${got}, versions.env pins ${TMUX_COMMIT}" >&2
    exit 1
fi
echo "tmux ${TMUX_VERSION} at ${got}"
