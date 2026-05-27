# 🐧 ManzoloDistro

> ⚠️ **PROGETTO ARCHIVIATO / PROJECT ARCHIVED**
>
> This project has been abandoned. The VM image generation (`make qcow2`) could not be made to work on an Ubuntu host — `bootc-image-builder` fails due to nested overlay restrictions, and `bootc install to-disk` fails with an undiagnosed ENOSPC error during ostree hardlinking. A Fedora host would be required to continue. The code is kept here for reference.

---

My personal Linux distribution, packaged as OCI images and published to GitHub Container Registry.

> 🇮🇹 [Versione italiana → README.it.md](README.it.md)

## Variants

| Variant | Containerfile | Base image | Arch |
|---------|---------------|-----------|------|
| **Fedora Bootc** (default) | `Containerfile.fedora` | `fedora-bootc:latest` | amd64 |
| Ubuntu | `Containerfile` | `ubuntu:26.04` | amd64 + arm64 |
| Arch Linux | `Containerfile.arch` | `archlinux:base-devel` | amd64 |

## What works

- `make build` / `make test` / `make run` — all three variants
- CI/CD GitHub Actions (build, release)

## What does not work

- `make qcow2` — broken on Ubuntu host, unresolved
