#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
#
# package.sh RELEASE ARCH: dist/tmux-RELEASE-linux-ARCH.tar.gz holding the
# single static `tmux` binary at the archive root.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

release="${1:?usage: package.sh RELEASE ARCH}"
arch="${2:?usage: package.sh RELEASE ARCH}"
mkdir -p dist
out="dist/tmux-${release}-linux-${arch}.tar.gz"
tar --owner=0 --group=0 --numeric-owner -czf "$out" -C "${PREFIX}/bin" tmux
echo "$out"
