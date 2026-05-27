# 🐧 ManzoloDistro

La mia distribuzione Linux personale, distribuita come immagini OCI su GitHub Container Registry.

> 🇬🇧 [English version → README.md](README.md)

---

## Scarica le immagini

```bash
docker pull ghcr.io/manzolo/manzolodistro-fedora:latest  # Fedora Bootc (default)
docker pull ghcr.io/manzolo/manzolodistro:latest          # Ubuntu 26.04
docker pull ghcr.io/manzolo/manzolodistro-arch:latest     # Arch Linux
```

## Avvio rapido

```bash
# Shell interattiva (Fedora – default)
docker run -it --rm ghcr.io/manzolo/manzolodistro-fedora:latest

# Con Distrobox (consigliato per uso desktop)
distrobox create --name manzolodistro --image ghcr.io/manzolo/manzolodistro-fedora:latest
distrobox enter manzolodistro
```

## Sviluppo locale

```bash
make              # mostra tutti i comandi disponibili
make build        # build Fedora (default)
make build-all    # build tutte e tre le varianti
make test         # smoke test Fedora
make qcow2        # genera qcow2 bootabile via bootc install to-disk
make run-qcow2    # avvia il qcow2 con QEMU
```

> **Generare il qcow2** usa `bootc install to-disk` — l'immagine installa se stessa su un loop device, poi `qemu-img` converte in qcow2. Richiede `sudo` e `qemu-utils`. Dimensione disco: 60G default con file sparso (il disco reale cresce solo con i dati scritti; override con `make qcow2 DISK_SIZE=80G`).

## Varianti

| Variante | Containerfile | Base image | Arch | Uso |
|----------|---------------|-----------|------|-----|
| **Fedora Bootc** (default) | `Containerfile.fedora` | `fedora-bootc:latest` | amd64 | Immagini VM (qcow2/ISO), Distrobox |
| Ubuntu | `Containerfile` | `ubuntu:26.04` | amd64 + arm64 | Distrobox, container |
| Arch Linux | `Containerfile.arch` | `archlinux:base-devel` | amd64 | Distrobox, container |

> La variante Fedora è basata su `quay.io/fedora/fedora-bootc` — un'immagine bootc-compatible convertibile in qcow2/ISO tramite `bootc-image-builder`.

## Pacchetti inclusi

| Categoria | Pacchetti |
|-----------|-----------|
| **Shell / CLI** | `zsh`, `mc`, `fzf`, `ripgrep`, `tmux`, `jq`, `yq`* |
| **Rete** | `nmap`, `net-tools`, `ipcalc`, `whois`, `rclone`, `sshfs` |
| **Sviluppo** | `geany`, `git`, `gh`, `cmake`, `shellcheck`, `sqlite3` |
| **Runtime** | `python3`, `nodejs`, `openjdk-21` |
| **Docker** | `docker-ce`, `buildx`, `compose` |
| **Media** | `vlc`, `ffmpeg`, `imagemagick`, `audacity` |
| **Office** | `libreoffice`, `thunderbird`, `pdfarranger` |
| **Virtualizzazione** | `virt-manager`, `qemu`, `libvirt` |
| **Desktop** | `niri`, `dms`†, `fuzzel`, `ptyxis`, `alacritty` |

> \* `yq` è il binario Go di Mike Farah — non il wrapper Python omonimo in apt.  
> † `dms` (DankMaterialShell): Ubuntu via PPA, Arch via repo ufficiali, Fedora via COPR `avengemedia/dms` + `greetd`.

## Documentazione

- [Come usare l'immagine](docs/usage.it.md) — container, Distrobox, QEMU, bootc/OS immutabile
- [Come funziona la build](docs/build.it.md) — layer OCI, pipeline GitHub Actions, multi-arch
- [Come personalizzare](docs/customize.it.md) — pacchetti, base image, file di config, Makefile

## CI/CD

| Workflow | Trigger | Produce |
|----------|---------|---------|
| `build.yml` | push su `main`, ogni lunedì alle 04:00 UTC | `latest`, `sha-*` (tutte e 3 le varianti) |
| `release.yml` | tag git `v*.*.*` | `v0.1.0`, `0.1.0`, `0.1` + GitHub Release |
| `test.yml` | manuale | smoke test su qualsiasi tag |
| `qcow2.yml` | manuale (scegli il tag) | artifact qcow2 (scaricabile per 7 giorni) |
