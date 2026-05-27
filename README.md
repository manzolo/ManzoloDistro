# 🐧 ManzoloDistro

My personal Linux distribution, packaged as an OCI image and published to GitHub Container Registry (GHCR).

Inspired by [MorrOS](https://github.com/morrolinux/morros) and the [Universal Blue](https://github.com/ublue-os/image-template) pattern.

---

## 📦 Pull the image

```bash
# Latest stable build
docker pull ghcr.io/manzolo/manzolodistro:latest

# Reproducible build pinned to a commit SHA
docker pull ghcr.io/manzolo/manzolodistro:sha-a1b2c3d

# Arch Linux variant
docker pull ghcr.io/manzolo/manzolodistro-arch:latest
```

## 🚀 Quick start

```bash
# Interactive shell
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest

# With your home directory mounted
docker run -it --rm -v $HOME:/home/user ghcr.io/manzolo/manzolodistro:latest

# With Podman (recommended for desktop use)
podman run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

## 🗂 Repository structure

```
.
├── Containerfile              # Ubuntu 26.04 build entry point
├── Containerfile.arch         # Arch Linux variant
├── build.sh                   # Ubuntu/Debian customisation script
├── build.arch.sh              # Arch customisation script
├── config/                    # (optional) system config files to embed
└── .github/
    └── workflows/
        └── build.yml          # GitHub Actions: build + push to GHCR
```

## 📦 Included packages

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

> \* `yq` is the Go-based binary by [Mike Farah](https://github.com/mikefarah/yq), installed from GitHub releases — **not** the Python `apt` wrapper of the same name.

## ⚙️ How to customise

### Add packages
Edit `build.sh` (Ubuntu) or `build.arch.sh` (Arch):

```bash
# Ubuntu/Debian
apt-get install -y your-package

# Arch
pacman -S --noconfirm your-package
```

### Change the base image
Edit the `FROM` line in `Containerfile`:

| Distro | FROM |
|--------|------|
| Ubuntu 26.04 LTS | `FROM ubuntu:26.04` |
| Ubuntu 24.04 LTS | `FROM ubuntu:24.04` |
| Debian Bookworm | `FROM debian:bookworm` |
| Arch Linux | use `Containerfile.arch` |

### Embed config files
Uncomment in `Containerfile`:
```dockerfile
COPY config/ /etc/manzolodistro/
```
then create the `config/` directory with your files.

## 🤖 CI/CD – Build triggers

Two jobs run **in parallel** on every trigger:

| Job | Containerfile | Published image |
|-----|---------------|-----------------|
| `build-ubuntu` | `Containerfile` | `ghcr.io/manzolo/manzolodistro` |
| `build-arch` | `Containerfile.arch` | `ghcr.io/manzolo/manzolodistro-arch` |

| Trigger | When |
|---------|------|
| **Push** | Any push to `main` touching `Containerfile*`, `build*.sh`, `config/**`, or the workflow file |
| **Schedule** | Every Monday at 04:00 UTC (keeps base packages up to date) |
| **Manual** | From the Actions tab → *Run workflow* |

Auto-generated tags:
- `latest` — always the latest `main` build
- `sha-XXXXXXX` — short commit SHA (reproducible)
- `YYYYMMDD` — date of scheduled builds
- `v1.2.3` / `1.2` — when a Git tag is pushed

---

## 🏗 How OCI image builds work

### What is an OCI image?

An **OCI image** (Open Container Initiative) is a standard, portable filesystem snapshot. It's the same format used by Docker and Podman. Instead of distributing an ISO to install, this project distributes a ready-to-use image you can pull and run in seconds.

Each image is made of **layers**:
1. **Base layer** — a minimal Ubuntu or Arch rootfs pulled from Docker Hub
2. **Build layer** — packages installed by `build.sh` / `build.arch.sh`
3. **Config layer** — optional files copied from `config/`

Layers are cached: if only `build.sh` changes, Docker reuses the base layer and only rebuilds from that point onward.

### Build pipeline

```
GitHub push / schedule / manual trigger
        │
        ▼
GitHub Actions runner (ubuntu-latest)
        │
        ├─ Job: build-ubuntu ──► docker buildx build -f Containerfile
        │                              └─ FROM ubuntu:26.04
        │                              └─ RUN build.sh
        │                              └─ push → ghcr.io/manzolo/manzolodistro
        │
        └─ Job: build-arch ────► docker buildx build -f Containerfile.arch
                                       └─ FROM archlinux:base-devel
                                       └─ RUN build.arch.sh
                                       └─ push → ghcr.io/manzolo/manzolodistro-arch
```

`docker buildx` enables **multi-platform builds**: the Ubuntu image is built for both `linux/amd64` and `linux/arm64` from the same runner. The Arch image is `linux/amd64` only (no official arm64 base image).

### How to use the image

**As an isolated shell environment** — run a command or open a shell without installing anything on the host:
```bash
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest bash
docker run --rm ghcr.io/manzolo/manzolodistro:latest python3 --version
```

**With persistent storage** — mount a host directory so files survive container restarts:
```bash
docker run -it --rm -v $HOME/projects:/workspace ghcr.io/manzolo/manzolodistro:latest
```

**As a base for other images** — use it in your own `Dockerfile`/`Containerfile`:
```dockerfile
FROM ghcr.io/manzolo/manzolodistro:latest
RUN apt-get install -y my-extra-package
```

**With Podman** (rootless, recommended for desktop):
```bash
podman run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

---

## 🌍 Make the image public

GHCR images inherit the repository's visibility by default.
To make the image publicly pullable without authentication:

1. Go to `https://github.com/manzolo?tab=packages`
2. Click the image → **Package settings**
3. Change visibility to **Public**

---

## 🇮🇹 Versione italiana

### Cos'è questa immagine?

ManzoloDistro è la mia distribuzione Linux personale distribuita come **immagine OCI** (lo stesso formato di Docker/Podman). Invece di un ISO da installare, si tratta di un ambiente Linux completo e pronto all'uso che puoi scaricare e avviare in pochi secondi.

### Come funziona la costruzione

L'immagine è composta da **strati (layer)**:
1. **Layer base** — un sistema Ubuntu 26.04 o Arch Linux minimale, scaricato da Docker Hub
2. **Layer di personalizzazione** — i pacchetti installati da `build.sh` (Ubuntu) o `build.arch.sh` (Arch) vengono "fotografati" e salvati come layer aggiuntivo
3. **Layer di configurazione** — file opzionali copiati dalla cartella `config/`

Quando modifichi `build.sh` e fai un push su GitHub, il workflow di **GitHub Actions** avvia automaticamente la build. Utilizza `docker buildx` che, da un singolo runner Linux, è in grado di costruire l'immagine per più architetture (`amd64` e `arm64`) contemporaneamente. L'immagine completata viene poi pubblicata su **GHCR** (GitHub Container Registry) con tag automatici.

I due job (`build-ubuntu` e `build-arch`) girano **in parallelo**, quindi entrambe le varianti sono pronte nello stesso tempo.

### Come si usa

**Shell interattiva** — apre un terminale nell'ambiente isolato:
```bash
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

**Con la home montata** — i file nella cartella host sopravvivono al riavvio del container:
```bash
docker run -it --rm -v $HOME/progetti:/workspace ghcr.io/manzolo/manzolodistro:latest
```

**Come base per altre immagini** — puoi usarla come punto di partenza nel tuo `Containerfile`:
```dockerfile
FROM ghcr.io/manzolo/manzolodistro:latest
RUN apt-get install -y il-mio-pacchetto
```

**Con Podman** (senza root, consigliato per uso desktop):
```bash
podman run -it --rm ghcr.io/manzolo/manzolodistro:latest
```
