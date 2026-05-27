# 🐧 ManzoloDistro

My personal Linux distribution, packaged as OCI images and published to GitHub Container Registry.

> 🇮🇹 [Versione italiana → README.it.md](README.it.md)

---

## Pull the images

```bash
docker pull ghcr.io/manzolo/manzolodistro-fedora:latest  # Fedora Bootc (default)
docker pull ghcr.io/manzolo/manzolodistro:latest          # Ubuntu 26.04
docker pull ghcr.io/manzolo/manzolodistro-arch:latest     # Arch Linux
```

## Quick start

```bash
# Interactive shell (Fedora – default)
docker run -it --rm ghcr.io/manzolo/manzolodistro-fedora:latest

# With Distrobox (recommended for desktop use)
distrobox create --name manzolodistro --image ghcr.io/manzolo/manzolodistro-fedora:latest
distrobox enter manzolodistro
```

## Local development

```bash
make              # show all available commands
make build        # build Fedora image (default)
make build-all    # build all three variants
make test         # smoke test Fedora
make qcow2        # generate bootable qcow2 via bootc install to-disk
make run-qcow2    # boot the qcow2 in QEMU
```

> **Generating qcow2** uses `bootc install to-disk` — the image installs itself to a loop device, then `qemu-img` converts to qcow2. Requires `sudo` and `qemu-utils`. Disk size defaults to 60G using a sparse raw file (actual disk usage grows only as data is written; override with `make qcow2 DISK_SIZE=80G`).

## Variants

| Variant | Containerfile | Base image | Arch | Use case |
|---------|---------------|-----------|------|----------|
| **Fedora Bootc** (default) | `Containerfile.fedora` | `fedora-bootc:latest` | amd64 | VM images (qcow2/ISO), Distrobox |
| Ubuntu | `Containerfile` | `ubuntu:26.04` | amd64 + arm64 | Distrobox, containers |
| Arch Linux | `Containerfile.arch` | `archlinux:base-devel` | amd64 | Distrobox, containers |

> The Fedora variant is based on `quay.io/fedora/fedora-bootc` — a bootc-compatible image that can be converted to qcow2/ISO via `bootc-image-builder`.

## Included packages

| Category | Packages |
|----------|----------|
| **Shell / CLI** | `zsh`, `mc`, `fzf`, `ripgrep`, `tmux`, `jq`, `yq`* |
| **Network** | `nmap`, `net-tools`, `ipcalc`, `whois`, `rclone`, `sshfs` |
| **Development** | `geany`, `git`, `gh`, `cmake`, `shellcheck`, `sqlite3` |
| **Runtimes** | `python3`, `nodejs`, `openjdk-21` |
| **Docker** | `docker-ce`, `buildx`, `compose` |
| **Media** | `vlc`, `ffmpeg`, `imagemagick`, `audacity` |
| **Office** | `libreoffice`, `thunderbird`, `pdfarranger` |
| **Virtualisation** | `virt-manager`, `qemu`, `libvirt` |
| **Desktop** | `niri`, `dms`†, `fuzzel`, `ptyxis`, `alacritty` |

> \* `yq` is the Go-based binary by Mike Farah — not the Python `apt` wrapper.  
> † `dms` (DankMaterialShell): Ubuntu via PPA, Arch via official repos, Fedora via COPR `avengemedia/dms` + `greetd`.

## Documentation

- [How to use](docs/usage.md) — container, Distrobox, QEMU, bootc/immutable OS
- [How the build works](docs/build.md) — OCI layers, GitHub Actions pipeline, multi-arch
- [How to customise](docs/customize.md) — packages, base image, config files, Makefile

## CI/CD

| Workflow | Trigger | Produces |
|----------|---------|----------|
| `build.yml` | push to `main`, every Monday 04:00 UTC | `latest`, `sha-*` (all 3 variants) |
| `release.yml` | git tag `v*.*.*` | `v0.1.0`, `0.1.0`, `0.1` + GitHub Release |
| `test.yml` | manual | smoke test on any tag |
| `qcow2.yml` | manual (choose tag) | qcow2 artifact (7-day download) |
