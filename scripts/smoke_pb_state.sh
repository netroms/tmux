#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
#
# smoke_pb_state.sh TMUX_BINARY: the build understands OSC 9;4. Starts a
# server on a throwaway socket, emits `ESC ] 9 ; 4 ; 3 BEL` in a pane and
# asserts #{pane_pb_state} becomes non-empty. Never touches another server.
set -euo pipefail

bin="${1:?usage: smoke_pb_state.sh TMUX_BINARY}"
T="$(mktemp -d)"
S="${T}/tmux.sock"
tm() { env -u TMUX -u TMUX_PANE "$bin" -S "$S" "$@"; }
cleanup() { tm kill-server 2>/dev/null || true; rm -rf "$T"; }
trap cleanup EXIT

tm -f /dev/null new-session -d -s smoke -x 80 -y 24 \
    "sh -c 'printf \"\\033]9;4;3\\007\"; sleep 60'"

state=""
for _ in $(seq 1 50); do
    state="$(tm display-message -p -t smoke: '#{pane_pb_state}')"
    [[ -n "$state" ]] && break
    sleep 0.2
done
echo "pane_pb_state=[${state}]"
[[ -n "$state" ]] || { echo "FAIL: #{pane_pb_state} stayed empty" >&2; exit 1; }
echo "smoke_pb_state: ok"
