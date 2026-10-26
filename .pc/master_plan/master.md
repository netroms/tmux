---
type: master-plan
id: tmux-mc-builds
title: "tmux builds for Mission Control: Master Plan"
description: Static, unmodified upstream tmux releases for the Mission Control fleet, built and published from the mc/release branch of github.com/netroms/tmux.
status: ongoing
parent: null
created: 2026-10-26
updated: 2026-10-26
profile_version: 1
---

<!-- Author: Morten (Morty) <netroms@gmail.com> -->

# tmux builds for Mission Control

Mission Control (MC) supervises agents inside tmux. Its needs-input fallback reads `#{pane_pb_state}` (OSC 9;4), which needs tmux 3.7 or newer, and its input client benefits from the 3.8 control-mode fixes. Ubuntu 26.04 ships 3.6, so this project builds our own releases.

- Source: unmodified upstream tmux at the tag pinned in `versions.env` (stock 3.8, decision D2 of MC plan `mc-fleet-verdict-health`, 2026-10-26).
- Output: musl-static `linux-x86_64` and `linux-arm64` tarballs plus `SHA256SUMS` as GitHub Releases on `github.com/netroms/tmux`, tags `<version>-mc.<n>` (first: `3.8-mc.1`, 2026-10-26).
- Consumers: MC's `scripts/deploy-peers.sh` tmux step (installs into `~/.local/bin/tmux`, never touches a running server) and infra's Ansible `tmux` role (`/usr/local/bin/tmux`). macOS uses Homebrew.
- Patches: none. The parked `osc-7501-*` branches would ship as `patches/*.patch` with a release suffix that says so.

How to bump and release: `README.mc.md`. Origin of this project: MC plan `mc-fleet-verdict-health` Stage 2 (MISSON-CONTROL-1013).
