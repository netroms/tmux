#!/usr/bin/env bash
# Author: Morten (Morty) <netroms@gmail.com>
#
# smoke_compat.sh NEW_CLIENT OLD_SERVER: a new tmux client (the release build)
# drives a server started by an older tmux (the distro 3.6a the fleet runs).
# Covers what Mission Control uses: list-panes, display -p, send-keys -H,
# capture-pane -p, pipe-pane, save-buffer -, and one persistent `-C` control
# client with `-f no-output` that runs send-keys -H (internal/tmux/control.go
# in Mission Control). Throwaway socket and directory; no other server is
# touched.
set -euo pipefail

new="${1:?usage: smoke_compat.sh NEW_CLIENT OLD_SERVER}"
old="${2:?usage: smoke_compat.sh NEW_CLIENT OLD_SERVER}"
T="$(mktemp -d)"
S="${T}/tmux.sock"
ctl_pid=""
oldtm() { env -u TMUX -u TMUX_PANE "$old" -S "$S" "$@"; }
newtm() { env -u TMUX -u TMUX_PANE "$new" -S "$S" "$@"; }
cleanup() {
    [[ -n "$ctl_pid" ]] && kill "$ctl_pid" 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
    oldtm kill-server 2>/dev/null || true
    rm -rf "$T"
}
trap cleanup EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
# wait_for DESCRIPTION COMMAND...: poll up to 10 s.
wait_for() {
    local what="$1"; shift
    for _ in $(seq 1 50); do
        if "$@" >/dev/null 2>&1; then return 0; fi
        sleep 0.2
    done
    fail "timed out waiting for ${what}"
}

echo "server binary: $("$old" -V), client binary: $("$new" -V)"

# The old tmux starts the server; the pane copies its keyboard input to a file.
oldtm -f /dev/null new-session -d -s smoke -x 100 -y 30 "cat > ${T}/feed"
sver="$(newtm display-message -p '#{version}')"
echo "server #{version}=${sver}"
[[ "$sver" == "$("$old" -V | awk '{print $2}')" ]] || fail "the server is not the old tmux (got ${sver})"

echo "== list-panes"
newtm list-panes -a -F '#{session_name}:#{pane_index} #{pane_pid}' | grep -q '^smoke:0 [0-9]' || fail "list-panes"

echo "== display -p"
[[ "$(newtm display-message -p -t smoke: '#{session_name}')" == "smoke" ]] || fail "display -p"

echo "== send-keys -H"
newtm send-keys -t smoke: -H 68 69 0a   # "hi\n"
wait_for "the pane to receive hi" grep -qx hi "${T}/feed"

echo "== capture-pane -p"
newtm capture-pane -p -t smoke: | grep -q hi || fail "capture-pane -p"

echo "== pipe-pane"
newtm pipe-pane -O -t smoke: "cat > ${T}/piped"
newtm send-keys -t smoke: -H 7a 7a 0a   # "zz\n", echoed by the pty
wait_for "pipe-pane output" grep -q zz "${T}/piped"
newtm pipe-pane -t smoke:

echo "== save-buffer -"
newtm capture-pane -b smokebuf -t smoke:
newtm save-buffer -b smokebuf - | grep -q hi || fail "save-buffer -"

echo "== control client, -f no-output"
mkfifo "${T}/ctl.in"
"$new" -S "$S" -N -C new-session -A -f no-output -s mc_input_smoke "sleep 2147483647" \
    < "${T}/ctl.in" > "${T}/ctl.out" 2> "${T}/ctl.err" &
ctl_pid=$!
exec 9> "${T}/ctl.in"
printf 'refresh-client -f no-output\n' >&9
wait_for "the control handshake" grep -q '^%end ' "${T}/ctl.out"
printf 'send-keys -t =smoke: -H 63 74 6c 0a\n' >&9   # "ctl\n"
wait_for "control send-keys to reach the pane" grep -qx ctl "${T}/feed"
! grep -q '^%output' "${T}/ctl.out" || fail "-f no-output still queued %output"
grep -q '^%error' "${T}/ctl.out" && fail "control client got %error: $(grep -m1 '^%error' "${T}/ctl.out")"
exec 9>&-
echo "smoke_compat: ok"
