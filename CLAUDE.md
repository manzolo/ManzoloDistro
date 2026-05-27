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

Triggers:
- **Push** to `main` touching `Containerfile`, `Containerfile.arch`, `build.sh`, `build.arch.sh`, `config/**`, or the workflow file
- **Schedule**: every Monday at 04:00 UTC (keeps base packages current)
- **Manual** via `workflow_dispatch`

Automatic tags: `latest`, `sha-<short>`, `YYYYMMDD` (scheduled builds), semver tags on Git tag push.

The Arch job is limited to `linux/amd64` only — `archlinux:base-devel` has no official arm64 layer.

## Key Customization Points

### Adding packages
Edit `build.sh` (Ubuntu) or `build.arch.sh` (Arch). Both scripts use `set -euo pipefail` — a failing command aborts the build.

### Changing the base image
Edit the `FROM` line in `Containerfile`:
- `ubuntu:26.04` / `ubuntu:24.04`
- `debian:bookworm` / `debian:bookworm-slim`
- For Arch, edit `Containerfile.arch` instead

### Adding config/dotfiles to the image
1. Create a `config/` directory at the repo root
2. Uncomment `COPY config/ /etc/mydistro/` in `Containerfile`
3. The workflow `paths` trigger already watches `config/**`

### Multi-arch builds (Ubuntu only)
The Ubuntu job targets `linux/amd64,linux/arm64`. Remove architectures you don't need to speed up builds.
