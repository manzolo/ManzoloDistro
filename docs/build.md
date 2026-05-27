# How the build works

> 🇮🇹 [Versione italiana](build.it.md)

---

## OCI image layers

Each image is built from stacked **layers**:

1. **Base layer** — the upstream OS rootfs from a public registry
2. **Build layer** — packages installed by the variant's build script
3. **Config layer** — files copied from `config/` (including the niri configuration under `config/etc/skel/`)

Layers are cached: if only the build script changes, Docker reuses the base layer and rebuilds only from that point.

---

## Variants

| Variant | Base image | Build script | Registry image |
|---------|-----------|--------------|----------------|
| **Fedora Bootc** (default) | `quay.io/fedora/fedora-bootc:latest` | `build.fedora.sh` | `ghcr.io/manzolo/manzolodistro-fedora` |
| Ubuntu | `ubuntu:26.04` | `build.sh` | `ghcr.io/manzolo/manzolodistro` |
| Arch Linux | `archlinux:base-devel` | `build.arch.sh` | `ghcr.io/manzolo/manzolodistro-arch` |

The Fedora variant is based on `fedora-bootc` — an image that already includes a kernel, ostree and bootc. This makes it directly compatible with `bootc-image-builder` to produce qcow2 disks and ISO installers.

---

## Pipeline

```
git push / tag / schedule / manual
          │
          ▼
  GitHub Actions runner
          │
          ├─ build-fedora ───► docker buildx build -f Containerfile.fedora
          │                          FROM fedora-bootc → build.fedora.sh
          │                          push → ghcr.io/manzolo/manzolodistro-fedora
          │                                (linux/amd64)
          │
          ├─ build-ubuntu ──► docker buildx build -f Containerfile
          │                          FROM ubuntu:26.04 → build.sh
          │                          push → ghcr.io/manzolo/manzolodistro
          │                                (linux/amd64 + linux/arm64)
          │
          ├─ build-arch ────► docker buildx build -f Containerfile.arch
          │                          FROM archlinux:base-devel → build.arch.sh
          │                          push → ghcr.io/manzolo/manzolodistro-arch
          │                                (linux/amd64 only)
          │
          └─ smoke-test ────► pulls sha-XXXXXXX tag, verifies key binaries
                              (needs: [build-fedora, build-ubuntu, build-arch])
```

The three build jobs run **in parallel**. The smoke test runs only after all three succeed, always testing the exact SHA tag just pushed — never a stale `latest`.

---

## Workflows

| File | Trigger | Tags produced |
|------|---------|---------------|
| `build.yml` | push to `main` (path filter), weekly Monday 04:00 UTC, manual | `latest`, `sha-XXXXXXX`, `YYYYMMDD` (all 3) |
| `release.yml` | git tag `v*.*.*` | `v0.1.0`, `0.1.0`, `0.1` + GitHub Release (all 3) |
| `test.yml` | manual only | smoke test on any tag |

---

## Multi-arch

`docker buildx` builds the Ubuntu image for both `linux/amd64` and `linux/arm64` from the same runner using QEMU emulation. Arch Linux and Fedora Bootc are `amd64` only.

GHA layer cache uses separate scopes (`scope=ubuntu`, `scope=arch`, `scope=fedora`) to avoid collisions.

---

## External repositories configured at build time

### Fedora

| Package | Source |
|---------|--------|
| `docker-ce` + `buildx` + `compose` | docker.com official dnf repo |
| `gh` (GitHub CLI) | cli.github.com official dnf repo |
| `vlc`, `ffmpeg` | RPM Fusion Free |
| `dms`, `quickshell`, `greetd`, `dms-greeter` | COPR `avengemedia/dms` |
| `yq` | GitHub releases binary (mikefarah/yq) |

### Ubuntu

| Package | Source |
|---------|--------|
| `docker-ce` + `buildx` + `compose` | docker.com official apt repo |
| `gh` (GitHub CLI) | cli.github.com official apt repo |
| `niri` + `dms` | `ppa:avengemedia/danklinux` + `ppa:avengemedia/dms` |
| `yq` | GitHub releases binary (mikefarah/yq) |

### Arch Linux

| Package | Source |
|---------|--------|
| `docker` | official Arch repos |
| `gh` | official Arch repos |
| `dms-shell-niri` | official Arch repos |
| `yq` | GitHub releases binary (mikefarah/yq) |
| `ocrmypdf` | `pip install --break-system-packages` (not in Arch repos) |
