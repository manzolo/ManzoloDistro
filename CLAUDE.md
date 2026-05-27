# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation structure

| File | Content |
|------|---------|
| `README.md` | English — concise, links to docs/ |
| `README.it.md` | Italian — concise, links to docs/ |
| `docs/usage.md` / `docs/usage.it.md` | Usage modes (container, Distrobox, QEMU, bootc) |
| `docs/build.md` / `docs/build.it.md` | OCI build pipeline, GitHub Actions |
| `docs/customize.md` / `docs/customize.it.md` | Packages, base image, config files, Makefile |

All documentation is bilingual (EN + IT). When editing docs, always update both language files.

## Overview

ManzoloDistro is a personal Linux distribution packaged as OCI images and published to GitHub Container Registry (GHCR). Three variants are maintained in parallel:

| Variant | Containerfile | Build script | Base image | Default |
|---------|---------------|--------------|------------|---------|
| **Fedora Bootc** | `Containerfile.fedora` | `build.fedora.sh` | `quay.io/fedora/fedora-bootc:latest` | ✅ |
| Ubuntu | `Containerfile` | `build.sh` | `ubuntu:26.04` | `-ubuntu` suffix |
| Arch Linux | `Containerfile.arch` | `build.arch.sh` | `archlinux:base-devel` | `-arch` suffix |

**Fedora is the default** for `make build`, `make run`, `make test`, `make push`. The Fedora variant is based on `fedora-bootc` which is bootc-compatible — it can be converted to a bootable qcow2 disk or ISO via `bootc-image-builder` (`make qcow2` / `make iso`).

## Local Build Commands

```bash
# Build Fedora (default)
make build
# or directly:
podman build -f Containerfile.fedora -t manzolodistro-fedora:local .

# Build Ubuntu variant
make build-ubuntu

# Build Arch variant
make build-arch

# Build all three
make build-all

# Run interactively (Fedora default)
make run
make run-ubuntu
make run-arch

# Smoke test
make test        # Fedora
make test-all    # all three
```

> There is no test suite. The primary validation is a successful container build + smoke test.

## CI/CD (GitHub Actions – `.github/workflows/build.yml`)

Three jobs run in parallel on every trigger:

| Job | Containerfile | Published image |
|-----|---------------|-----------------|
| `build-fedora` | `Containerfile.fedora` | `ghcr.io/manzolo/manzolodistro-fedora` |
| `build-ubuntu` | `Containerfile` | `ghcr.io/manzolo/manzolodistro` |
| `build-arch` | `Containerfile.arch` | `ghcr.io/manzolo/manzolodistro-arch` |

A fourth job `smoke-test` runs after all three succeed, testing the exact `sha-XXXXXXX` tag.

### Rolling builds (`build.yml`)
- **Push** to `main` touching any Containerfile, build script, `config/**`, or the workflow file
- **Schedule**: every Monday at 04:00 UTC / 05:00 Italian time
- **Manual** via `workflow_dispatch`

Tags produced: `latest`, `sha-<short>`, `YYYYMMDD`.

### Versioned releases (`release.yml`)
- Triggered by pushing a `v*.*.*` tag (e.g. `git tag v0.1.0 && git push origin v0.1.0`)
- Tags produced: `v0.1.0`, `0.1.0`, `0.1` (all 3 variants)
- Also creates a GitHub Release automatically (via `softprops/action-gh-release`)
- Runs only after all image jobs succeed (`needs: [release-fedora, release-ubuntu, release-arch]`)

GHA layer cache uses separate scopes (`scope=fedora`, `scope=ubuntu`, `scope=arch`) to avoid cache collisions.

## Included packages

All three build scripts install equivalent packages where available:

| Category | Packages |
|----------|----------|
| **Shell / CLI** | `zsh`, `mc`, `fzf`, `ripgrep`, `tmux`, `tree`, `jq`, `yq`* |
| **Network** | `nmap`, `net-tools`, `ipcalc`, `whois`, `rclone`, `sshfs`, `rsync` |
| **Development** | `geany`, `git`, `gh`, `cmake`, `build-essential`, `shellcheck` |
| **Runtimes** | `python3` + pip + venv, `nodejs` + npm, `openjdk-21` |
| **Docker** | `docker-ce`, `docker-ce-cli`, `containerd.io`, `buildx`, `compose` |
| **Database** | `sqlite3`, `sqlitebrowser` |
| **Media** | `vlc`, `ffmpeg`, `imagemagick`, `audacity` |
| **Office** | `libreoffice`, `thunderbird`, `pdfarranger` |
| **Virtualisation** | `virt-manager`, `qemu`, `libvirt`, `ovmf/edk2-ovmf` |
| **Desktop** | `niri`, `dms`†, `fuzzel`, `ptyxis`, `alacritty`, `brightnessctl`, `playerctl` |

> \* `yq` is installed as the Go-based binary from GitHub releases (Mike Farah). Never use `apt-get install yq` (Python wrapper) or dnf's `yq`.  
> † `dms` (DankMaterialShell): Ubuntu via `ppa:avengemedia/danklinux` + `ppa:avengemedia/dms`; Arch via `dms-shell-niri`; Fedora via COPR `avengemedia/dms` (`quickshell dms greetd dms-greeter`, login manager is `greetd`). Ref: https://github.com/morrolinux/morros

## Key Customisation Points

### Adding packages
Edit the build script for the target variant. All scripts use `set -euo pipefail` — a failing command aborts the build.

### Changing the base image
- **Fedora**: edit `FROM` in `Containerfile.fedora` — use `fedora-bootc:latest` or pin to a version like `fedora-bootc:42`
- **Ubuntu**: edit `FROM` in `Containerfile` — `ubuntu:26.04`, `ubuntu:24.04`, `debian:bookworm`
- **Arch**: edit `Containerfile.arch`

### Adding config/dotfiles to the image
The `config/` directory mirrors the filesystem root and is copied verbatim into all three images:
```
config/etc/skel/.config/niri/   →   /etc/skel/.config/niri/
```
Files placed under `config/etc/skel/` are automatically copied to every new user's home at account creation. The niri config (including `dms/binds.kdl` with all keybindings) is already included there.

### Multi-arch builds
- Ubuntu: `linux/amd64,linux/arm64`
- Fedora Bootc: `linux/amd64` only (local VM use case)
- Arch Linux: `linux/amd64` only (no official arm64 base)

### VM image generation (qcow2 / ISO)
The Fedora variant is used for VM generation — `make qcow2` and `make iso` build it and pass it to `bootc-image-builder`. This requires root podman (`sudo podman`) because bootc-image-builder needs privileged access to `/var/lib/containers/storage`.
