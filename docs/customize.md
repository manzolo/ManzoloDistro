# How to customise ManzoloDistro

> 🇮🇹 [Versione italiana](customize.it.md)

---

## Variants

| Variant | Containerfile | Build script | Default |
|---------|---------------|--------------|---------|
| **Fedora Bootc** | `Containerfile.fedora` | `build.fedora.sh` | ✅ (`make build`) |
| Ubuntu | `Containerfile` | `build.sh` | `make build-ubuntu` |
| Arch Linux | `Containerfile.arch` | `build.arch.sh` | `make build-arch` |

The Fedora variant is the default because it is **bootc-compatible** — it can be converted to a bootable qcow2 disk or ISO via `bootc-image-builder` (`make qcow2` / `make iso`).

---

## Add or remove packages

Edit the build script for the variant you want to change:

| Variant | Script | Package manager |
|---------|--------|----------------|
| Fedora | `build.fedora.sh` | `dnf install -y` |
| Ubuntu | `build.sh` | `apt-get install -y` |
| Arch | `build.arch.sh` | `pacman -S --noconfirm` |

All scripts run with `set -euo pipefail` — any error aborts the build.

---

## Change the base image

### Fedora (default)
Edit the `FROM` line in `Containerfile.fedora`:

| Base | Notes |
|------|-------|
| `quay.io/fedora/fedora-bootc:latest` | Latest Fedora (rolling, bootc-compatible) |
| `quay.io/fedora/fedora-bootc:42` | Pin to a specific Fedora version |

### Ubuntu
Edit the `FROM` line in `Containerfile`:

| Distro | FROM |
|--------|------|
| Ubuntu 26.04 LTS | `FROM ubuntu:26.04` |
| Ubuntu 24.04 LTS | `FROM ubuntu:24.04` |
| Debian Bookworm | `FROM debian:bookworm` |

### Arch Linux
Edit `Containerfile.arch` instead.

---

## Add config files / dotfiles

The `config/` directory mirrors the filesystem root and is copied verbatim into the image at build time (all variants):

```
config/etc/skel/.config/niri/   →   /etc/skel/.config/niri/
config/etc/skel/.bashrc         →   /etc/skel/.bashrc
config/usr/share/backgrounds/   →   /usr/share/backgrounds/
```

Files placed under `config/etc/skel/` are automatically copied to every new user's home directory at account creation. The niri configuration (keybindings, dms layout, colours) is already included there.

---

## Update the niri config

The niri config lives in `config/etc/skel/.config/niri/`. Edit the files there and push — the next build will bake the updated config into the image.

Key files:

| File | Purpose |
|------|---------|
| `config.kdl` | Main niri config (layout, outputs, base keybindings) |
| `dms/binds.kdl` | DankMaterialShell keybindings (Super+E → nautilus, Mod+T → ptyxis, …) |
| `dms/colors.kdl` | Colour scheme |
| `dms/layout.kdl` | Shell layout |

> `dms` is available on all three variants. On Fedora it is installed from the `avengemedia/dms` COPR (same author as the Ubuntu PPA), using `greetd` as the login manager.

---

## Makefile reference

```bash
make                     # show this help
make build               # build Fedora (default)
make build-ubuntu        # build Ubuntu only
make build-arch          # build Arch only
make build-all           # build all three variants

make run                 # interactive shell (Fedora – default)
make run-ubuntu          # interactive shell (Ubuntu)
make run-arch            # interactive shell (Arch)
make run-home            # Fedora with $HOME mounted

make test                # smoke test Fedora (default)
make test-ubuntu         # smoke test Ubuntu
make test-arch           # smoke test Arch
make test-all            # smoke test all three

make qcow2               # generate output/qcow2/disk.qcow2 (Fedora Bootc)
make iso                 # generate output/bootiso/install.iso (Fedora Bootc)
make run-qcow2           # boot qcow2 in QEMU (KVM + UEFI)
make run-iso             # boot ISO in QEMU (KVM + UEFI)

make push                # push Fedora to GHCR (default)
make push-ubuntu         # push Ubuntu to GHCR
make push-arch           # push Arch to GHCR
make push-all            # push all three

make clean               # remove local images and output/

# Overrides
RUNTIME=docker make build          # use docker instead of podman
TAG=v0.1.2 make build              # build with a specific tag
QEMU_MEM=8G QEMU_CPUS=4 make run-qcow2
```

---

## Release a new version

```bash
git tag v0.2.0
git push origin v0.2.0
```

GitHub Actions (`release.yml`) will build all three images, publish versioned tags (`v0.2.0`, `0.2.0`, `0.2`) and create a GitHub Release automatically.
