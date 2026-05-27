# Come funziona la build

> 🇬🇧 [English version](build.md)

---

## Layer dell'immagine OCI

Ogni immagine è costruita da **layer** sovrapposti:

1. **Layer base** — sistema minimale scaricato dal registry pubblico corrispondente
2. **Layer di personalizzazione** — pacchetti installati dallo script della variante
3. **Layer di configurazione** — file copiati da `config/` (inclusa la config niri in `config/etc/skel/`)

I layer sono cached: se cambia solo lo script di build, Docker riusa il layer base e ricostruisce solo da quel punto in poi.

---

## Varianti

| Variante | Base image | Script build | Immagine su GHCR |
|----------|-----------|--------------|-----------------|
| **Fedora Bootc** (default) | `quay.io/fedora/fedora-bootc:latest` | `build.fedora.sh` | `ghcr.io/manzolo/manzolodistro-fedora` |
| Ubuntu | `ubuntu:26.04` | `build.sh` | `ghcr.io/manzolo/manzolodistro` |
| Arch Linux | `archlinux:base-devel` | `build.arch.sh` | `ghcr.io/manzolo/manzolodistro-arch` |

La variante Fedora è basata su `fedora-bootc` — un'immagine che include già kernel, ostree e bootc. Questo la rende direttamente compatibile con `bootc-image-builder` per produrre dischi qcow2 e ISO installatori.

---

## Pipeline

```
git push / tag / schedule / manuale
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
          └─ smoke-test ────► scarica il tag sha-XXXXXXX, verifica i binari chiave
                              (needs: [build-fedora, build-ubuntu, build-arch])
```

I tre job di build girano **in parallelo**. Lo smoke test parte solo dopo che tutti e tre hanno avuto successo, testando sempre il tag SHA esatto appena pushato — mai un `latest` obsoleto.

---

## Workflow

| File | Trigger | Tag prodotti |
|------|---------|--------------|
| `build.yml` | push su `main` (path filter), ogni lunedì 04:00 UTC, manuale | `latest`, `sha-XXXXXXX`, `YYYYMMDD` (tutte e 3) |
| `release.yml` | tag git `v*.*.*` | `v0.1.0`, `0.1.0`, `0.1` + GitHub Release (tutte e 3) |
| `test.yml` | solo manuale | smoke test su qualsiasi tag |

---

## Multi-arch

`docker buildx` costruisce l'immagine Ubuntu per `linux/amd64` e `linux/arm64` dallo stesso runner, usando l'emulazione QEMU. Arch Linux e Fedora Bootc sono solo `amd64`.

La cache GHA usa scope separati (`scope=ubuntu`, `scope=arch`, `scope=fedora`) per evitare collisioni.

---

## Repository esterni configurati a build time

### Fedora

| Pacchetto | Sorgente |
|-----------|----------|
| `docker-ce` + `buildx` + `compose` | repo dnf ufficiale docker.com |
| `gh` (GitHub CLI) | repo dnf ufficiale cli.github.com |
| `vlc`, `ffmpeg` | RPM Fusion Free |
| `dms`, `quickshell`, `greetd`, `dms-greeter` | COPR `avengemedia/dms` |
| `yq` | binario da GitHub releases (mikefarah/yq) |

### Ubuntu

| Pacchetto | Sorgente |
|-----------|----------|
| `docker-ce` + `buildx` + `compose` | repo apt ufficiale docker.com |
| `gh` (GitHub CLI) | repo apt ufficiale cli.github.com |
| `niri` + `dms` | `ppa:avengemedia/danklinux` + `ppa:avengemedia/dms` |
| `yq` | binario da GitHub releases (mikefarah/yq) — non il wrapper Python in apt |

### Arch Linux

| Pacchetto | Sorgente |
|-----------|----------|
| `docker` | repo ufficiali Arch |
| `gh` | repo ufficiali Arch |
| `dms-shell-niri` | repo ufficiali Arch |
| `yq` | binario da GitHub releases (mikefarah/yq) |
| `ocrmypdf` | `pip install --break-system-packages` (non nei repo Arch) |
