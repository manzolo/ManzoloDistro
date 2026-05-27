# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

ManzoloDistro is a personal Linux distribution packaged as an OCI image and published to GitHub Container Registry (GHCR). It follows the [Universal Blue](https://github.com/ublue-os/image-template) pattern. Two variants are maintained in parallel:

| Variant | Containerfile | Build script | Base image |
|---------|---------------|--------------|------------|
| Ubuntu (default) | `Containerfile` | `build.sh` | `ubuntu:26.04` |
| Arch Linux | `Containerfile.arch` | `build.arch.sh` | `archlinux:base-devel` |

## Local Build Commands

```bash
# Build Ubuntu variant
docker build -f Containerfile -t manzolodistro:local .
# or with Podman
podman build -f Containerfile -t manzolodistro:local .

# Build Arch variant
docker build -f Containerfile.arch -t manzolodistro-arch:local .

# Run interactively
docker run -it --rm manzolodistro:local
docker run -it --rm -v $HOME:/home/user manzolodistro:local
```

> There is no test suite. The primary validation is a successful container build.

## CI/CD (GitHub Actions – `.github/workflows/build.yml`)

Two jobs run in parallel on every trigger:

| Job | Containerfile | Published image |
|-----|---------------|-----------------|
| `build-ubuntu` | `Containerfile` | `ghcr.io/manzolo/manzolodistro` |
| `build-arch` | `Containerfile.arch` | `ghcr.io/manzolo/manzolodistro-arch` |

### Rolling builds (`build.yml`)
- **Push** to `main` touching `Containerfile`, `Containerfile.arch`, `build.sh`, `build.arch.sh`, `config/**`, or the workflow file
- **Schedule**: every Monday at 04:00 UTC / 05:00 Italian time
- **Manual** via `workflow_dispatch`

Tags produced: `latest`, `sha-<short>`, `YYYYMMDD`.

### Versioned releases (`release.yml`)
- Triggered by pushing a `v*.*.*` tag (e.g. `git tag v0.1.0 && git push origin v0.1.0`)
- Tags produced: `v0.1.0`, `0.1.0`, `0.1`
- Also creates a GitHub Release automatically (via `softprops/action-gh-release`)
- Runs only after both image jobs succeed (`needs: [release-ubuntu, release-arch]`)

The Arch job is limited to `linux/amd64` only — `archlinux:base-devel` has no official arm64 layer.

GHA layer cache uses separate scopes (`scope=ubuntu`, `scope=arch`) to avoid cache collisions between the two jobs.

## Included packages

Both `build.sh` (Ubuntu) and `build.arch.sh` (Arch) install equivalent packages:

| Category | Packages |
|----------|----------|
| **Shell / CLI** | `zsh`, `mc`, `fzf`, `ripgrep`, `tmux`, `tree`, `jq`, `yq`* |
| **Network** | `nmap`, `net-tools`, `ipcalc`, `whois`, `mitmproxy`, `rclone`, `sshfs`, `rsync` |
| **Development** | `geany`, `git`, `gh`, `cmake`, `build-essential`, `shellcheck` |
| **Runtimes** | `python3` + pip + venv, `nodejs` + npm, `openjdk-21` |
| **Docker** | `docker-ce`, `docker-ce-cli`, `containerd.io`, `buildx`, `compose` |
| **Database** | `sqlite3`, `sqlitebrowser` |
| **Media** | `vlc`, `ffmpeg`, `imagemagick`, `audacity` |
| **Office** | `libreoffice`, `thunderbird`, `pdfarranger`, `ocrmypdf` |
| **Virtualisation** | `virt-manager`, `qemu-system-x86`, `libvirt`, `ovmf` |
| **Desktop** | `niri`, `dms` ([DankMaterialShell](https://danklinux.com/docs/dankmaterialshell/installation)), `fuzzel`, `ptyxis`, `alacritty`, `brightnessctl`, `playerctl` |

> \* `yq` is installed as the Go-based binary from GitHub releases (Mike Farah). The `apt` package named `yq` on Ubuntu is a different Python wrapper — **do not use `apt-get install yq`**.

External repos configured at build time: Docker CE official repo, GitHub CLI official repo.

## Key Customisation Points

### Adding packages
Edit `build.sh` (Ubuntu) or `build.arch.sh` (Arch). Both scripts use `set -euo pipefail` — a failing command aborts the build.

### Changing the base image
Edit the `FROM` line in `Containerfile`:
- `ubuntu:26.04` / `ubuntu:24.04`
- `debian:bookworm` / `debian:bookworm-slim`
- For Arch, edit `Containerfile.arch` instead

### Adding config/dotfiles to the image
The `config/` directory mirrors the filesystem root and is copied verbatim into the image:
```
config/etc/skel/.config/niri/   →   /etc/skel/.config/niri/
```
Files placed under `config/etc/skel/` are automatically copied to every new user's home at account creation. The niri config (including `dms/binds.kdl` with all keybindings) is already included there.

### Multi-arch builds (Ubuntu only)
The Ubuntu job targets `linux/amd64,linux/arm64`. Remove architectures you don't need to speed up builds.
