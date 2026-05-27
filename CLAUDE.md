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
docker build -f Containerfile -t mydistro:local .
# or with Podman
podman build -f Containerfile -t mydistro:local .

# Build Arch variant
docker build -f Containerfile.arch -t mydistro-arch:local .

# Run interactively
docker run -it --rm mydistro:local
docker run -it --rm -v $HOME:/home/user mydistro:local
```

> There is no test suite. The primary validation is a successful container build.

## CI/CD (GitHub Actions – `build.yml`)

The workflow builds and pushes to `ghcr.io/<owner>/mydistro` on:
- **Push** to `main` touching `Containerfile`, `build.sh`, `config/**`, or the workflow file itself
- **Schedule**: every Monday at 04:00 UTC (keeps base packages current)
- **Manual** via `workflow_dispatch`

Automatic tags generated: `latest`, `sha-<short>`, `YYYYMMDD` (scheduled), and semver tags when Git tags are pushed.

## Key Customization Points

### Adding packages
Edit `build.sh` (Ubuntu) or `build.arch.sh` (Arch). Both scripts use `set -euo pipefail` — a failing command aborts the build.

### Changing the base image
Edit the `FROM` line in `Containerfile`:
- `ubuntu:24.04` / `ubuntu:22.04`
- `debian:bookworm` / `debian:bookworm-slim`
- For Arch, swap to `Containerfile.arch` entirely

### Adding config/dotfiles to the image
1. Create a `config/` directory at the repo root
2. Uncomment `COPY config/ /etc/mydistro/` in `Containerfile`
3. The `build.yml` `paths` trigger already watches `config/**`

### Multi-arch builds
`build.yml` targets `linux/amd64,linux/arm64` by default. Remove architectures you don't need to speed up builds.

## First-time Setup

Replace the placeholder `TUOUSERNAME` with your actual GitHub username in:
- `Containerfile` (the `LABEL org.opencontainers.image.source` line)
- `Containerfile.arch` (same label)
- `README.md` (pull/run examples)
