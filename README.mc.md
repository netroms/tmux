<!-- Author: Morten (Morty) <netroms@gmail.com> -->

# tmux builds for Mission Control (`mc/release`)

This branch of `netroms/tmux` builds **unmodified upstream tmux** as static musl
binaries for the Mission Control fleet and publishes them as GitHub Releases. It
exists because the distro tmux on the fleet is 3.6, which has no
`#{pane_pb_state}` (OSC 9;4, added in 3.7) and lacks the control-mode fixes of 3.8.

No tmux source line differs from upstream: the workflow clones `tmux/tmux` at the
tag pinned in `versions.env` and refuses a tag that no longer points at the pinned
commit. The scripts are adapted from [tmux/tmux-builds](https://github.com/tmux/tmux-builds)
(license notice in `LICENSE`). The patch branches `osc-7501-*` of the same
repository stay parked; if a patch is ever shipped it goes in `patches/*.patch`,
applied by `scripts/build_tmux.sh` after `fetch_tmux.sh`, and the release suffix
says so.

## What a release contains

Release tag `<tmux version>-mc.<n>`, for example `3.8-mc.1`:

| Asset | Content |
|---|---|
| `tmux-3.8-mc.1-linux-x86_64.tar.gz` | one static `tmux` binary at the archive root |
| `tmux-3.8-mc.1-linux-arm64.tar.gz` | same, aarch64 |
| `SHA256SUMS` | `sha256sum` of every asset above and `LICENSES.tar.gz` |
| `LICENSES.tar.gz` | tmux, libevent, musl, ncurses license texts and the tmux-builds notice |

`tmux -V` of the binary prints `tmux 3.8` (the upstream version, without the
`-mc.<n>` suffix). The terminfo search path is baked in:
`/etc/terminfo:/lib/terminfo:/usr/share/terminfo` (Debian, Ubuntu, Fedora).

Install by hand:

```sh
curl -fsSLO https://github.com/netroms/tmux/releases/download/3.8-mc.1/tmux-3.8-mc.1-linux-x86_64.tar.gz
curl -fsSLO https://github.com/netroms/tmux/releases/download/3.8-mc.1/SHA256SUMS
sha256sum -c --ignore-missing SHA256SUMS
tar -xzf tmux-3.8-mc.1-linux-x86_64.tar.gz tmux
install -m 0755 tmux ~/.local/bin/tmux.new && mv -f ~/.local/bin/tmux.new ~/.local/bin/tmux
```

Installing never touches a running tmux server: the old server keeps its own
binary until it exits. Mission Control's `scripts/deploy-peers.sh` and the infra
Ansible role `tmux` do this for the fleet.

## CI

`.github/workflows/release.yml`, on every push to `mc/release`, on tag push and by
hand:

1. **build** on `ubuntu-24.04` (linux-x86_64) and `ubuntu-24.04-arm` (linux-arm64):
   musl, libevent, ncurses, then tmux with `--enable-static`; every download is
   checked against the sha256 in `versions.env`.
2. `scripts/verify_tmux.sh`: `file` reports a static binary, `ldd` finds no loader,
   `tmux -V` equals the pin, the terminfo path is baked in.
3. `scripts/smoke_pb_state.sh`: a server on a throwaway socket, `printf '\033]9;4;3\007'`
   in a pane, `#{pane_pb_state}` must become non-empty.
4. **compat** on `ubuntu-26.04` and `ubuntu-26.04-arm` (distro tmux 3.6a, the fleet's
   version): `scripts/smoke_compat.sh` runs the built client against a 3.6 server:
   `list-panes`, `display -p`, `send-keys -H`, `capture-pane -p`, `pipe-pane`,
   `save-buffer -`, and a persistent `-C` control client with `-f no-output` running
   `send-keys -H` (the pattern of Mission Control's `internal/tmux/control.go`).
5. **release** (tag push only): `SHA256SUMS`, GitHub Release with the four assets.

A tag is accepted only as `<TMUX_VERSION>-mc.<n>` matching `versions.env`.

## Upgrade recipe

1. Pick the upstream tag (`git ls-remote --tags https://github.com/tmux/tmux`) and its
   commit (`git ls-remote https://github.com/tmux/tmux 'refs/tags/<tag>^{}'`).
2. Edit `versions.env`: `TMUX_VERSION`, `TMUX_COMMIT`; dependency versions and sha256
   only when they change.
3. Commit on `mc/release`, push; the branch run builds and smokes without publishing.
4. Tag `<tag>-mc.1` (`.2` for a rebuild of the same tmux version), push the tag:
   `git tag 3.9-mc.1 && git push netroms 3.9-mc.1`. Watch with `gh run watch`.
5. Check the release assets and `SHA256SUMS`.
6. Bump the pin in Mission Control (`scripts/tmux-release.env`) and infra
   (`ansible/group_vars/all/main.yml`: `tmux_version` plus checksums), then roll out.

Local build on a Linux host (build-essential, automake, bison, pkg-config, curl, git):

```sh
PREFIX=/tmp/build scripts/build_all.sh
```

## Remotes

`origin` is `tmux/tmux` (upstream), `netroms` is the public fork this branch is
pushed to. `master` and the `osc-7501-*` branches are upstream history and the parked
patch work; `mc/release` is an orphan branch with nothing from them.
