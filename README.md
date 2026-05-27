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

---

## 🚀 How to use the image

### 1 — As a container (immediate use)

The simplest mode: start the image with Docker or Podman and get a full Linux terminal with all your tools pre-installed:

```bash
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

Use this mode to get a **reproducible working environment** on any machine — CI runners, remote servers, colleagues' laptops — without installing anything on the host.

```bash
# With a host directory mounted for persistent storage
docker run -it --rm -v $HOME/projects:/workspace ghcr.io/manzolo/manzolodistro:latest

# With Podman (rootless, recommended for desktop)
podman run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

---

### 2 — As a desktop distro with Distrobox

[Distrobox](https://distrobox.it/) is the most convenient way to use an OCI image as if it were a real distribution integrated into your desktop:

```bash
distrobox create --name manzolodistro --image ghcr.io/manzolo/manzolodistro:latest
distrobox enter manzolodistro
```

Distrobox integrates the container with your host desktop: it **shares the home directory, display, audio, and USB devices**. GUI apps (Geany, VLC, LibreOffice, …) appear in the system application menu as if they were installed natively on the host.

This is the **recommended daily-driver mode**: keep your host OS as-is and use ManzoloDistro as an isolated, always up-to-date working environment, identical across every machine.

---

### 3 — As an immutable OS (Universal Blue style)

The [Universal Blue](https://universal-blue.org/) pattern that inspired this project allows using an OCI image as the **operating system itself**, via [`bootc`](https://containers.github.io/bootc/) (image-based Linux):

```bash
# Install directly from the OCI image onto hardware or a VM
sudo bootc switch ghcr.io/manzolo/manzolodistro:latest
```

With this approach the OS becomes **immutable and atomic**: it updates like a container pull, rolls back instantly if something breaks, and is 100% reproducible. This is exactly how [Fedora Silverblue](https://fedoraproject.org/silverblue/) and uBlue derivatives work.

> **Note:** `bootc` on Ubuntu is currently experimental. This mode works best with Fedora/CentOS-based images. It is documented here for completeness and future compatibility.

---

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
| **Desktop** | `niri` (Wayland compositor), `dms` |

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

### Rolling builds (`build.yml`)

| Trigger | When |
|---------|------|
| **Push** | Any push to `main` touching `Containerfile*`, `build*.sh`, `config/**`, or the workflow file |
| **Schedule** | Every Monday at 05:00 Italian time / 04:00 UTC (keeps base packages up to date) |
| **Manual** | From the Actions tab → *Run workflow* |

Tags produced: `latest`, `sha-XXXXXXX`, `YYYYMMDD`

### Versioned releases (`release.yml`)

Push a semver tag to trigger a dedicated release build:

```bash
git tag v0.1.0
git push origin v0.1.0
```

Tags produced: `v0.1.0`, `0.1.0`, `0.1`

A GitHub Release is also created automatically with pull instructions for both variants.

## 🌍 Make the image public

GHCR images inherit the repository's visibility by default.
To make the image publicly pullable without authentication:

1. Go to `https://github.com/manzolo?tab=packages`
2. Click the image → **Package settings**
3. Change visibility to **Public**

---

## 🏗 How OCI image builds work

### What is an OCI image?

An **OCI image** (Open Container Initiative) is a standard, portable filesystem snapshot — the same format used by Docker and Podman. Instead of distributing an ISO to install, this project distributes a ready-to-use image you can pull and run in seconds.

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
        │                                        (linux/amd64 + linux/arm64)
        │
        └─ Job: build-arch ────► docker buildx build -f Containerfile.arch
                                       └─ FROM archlinux:base-devel
                                       └─ RUN build.arch.sh
                                       └─ push → ghcr.io/manzolo/manzolodistro-arch
                                                 (linux/amd64 only)
```

`docker buildx` enables **multi-platform builds**: the Ubuntu image is built for both `linux/amd64` and `linux/arm64` from the same runner. The Arch image is `linux/amd64` only (no official arm64 base image).

---

## 🇮🇹 Versione italiana

### Cos'è questa immagine?

ManzoloDistro è la mia distribuzione Linux personale distribuita come **immagine OCI** (lo stesso formato di Docker/Podman). Invece di un ISO da installare, si tratta di un ambiente Linux completo e pronto all'uso che puoi scaricare e avviare in pochi secondi.

---

### Come si usa

#### 1 — Come container (uso immediato)

Il modo più semplice: avvii l'immagine con Docker o Podman e hai un terminale Linux completo con tutti i pacchetti già installati:

```bash
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

Usi questa modalità per avere un **ambiente di lavoro riproducibile** su qualsiasi macchina — CI, server remoto, computer di colleghi — senza installare nulla sull'host.

---

#### 2 — Come "distro desktop" con Distrobox

[Distrobox](https://distrobox.it/) è lo strumento più comodo per usare un'immagine OCI come se fosse una vera distribuzione integrata nel desktop:

```bash
distrobox create --name manzolodistro --image ghcr.io/manzolo/manzolodistro:latest
distrobox enter manzolodistro
```

Distrobox integra il container con il tuo desktop host: **condivide la home, il display, i dispositivi audio e USB**. Le applicazioni GUI (Geany, VLC, LibreOffice…) appaiono nel menu di sistema come se fossero installate nativamente sull'host.

Questa è la **modalità consigliata per l'uso quotidiano**: tieni il tuo OS host com'è e usi ManzoloDistro come ambiente di lavoro isolato e sempre aggiornabile, identico su ogni macchina.

---

#### 3 — Come sistema operativo immutabile (Universal Blue style)

Il pattern [Universal Blue](https://universal-blue.org/) da cui ManzoloDistro è ispirato permette di usare l'immagine OCI come **sistema operativo vero e proprio**, tramite [`bootc`](https://containers.github.io/bootc/) (Linux image-based):

```bash
sudo bootc switch ghcr.io/manzolo/manzolodistro:latest
```

Con questo approccio l'OS diventa **immutabile e atomico**: si aggiorna come un container pull, torna indietro istantaneamente in caso di problemi ed è 100% riproducibile. È esattamente così che funzionano [Fedora Silverblue](https://fedoraproject.org/silverblue/) e i derivati uBlue.

> **Nota:** `bootc` su Ubuntu è attualmente sperimentale. Questo approccio funziona meglio con immagini basate su Fedora/CentOS. È documentato qui per completezza e compatibilità futura.

---

### Come funziona la costruzione

L'immagine è composta da **strati (layer)**:
1. **Layer base** — un sistema Ubuntu 26.04 o Arch Linux minimale, scaricato da Docker Hub
2. **Layer di personalizzazione** — i pacchetti installati da `build.sh` (Ubuntu) o `build.arch.sh` (Arch)
3. **Layer di configurazione** — file opzionali copiati dalla cartella `config/`

Quando modifichi `build.sh` e fai un push su GitHub, il workflow di **GitHub Actions** avvia automaticamente la build. Usa `docker buildx` che, da un singolo runner Linux, costruisce l'immagine per più architetture (`amd64` e `arm64`) contemporaneamente. I due job (`build-ubuntu` e `build-arch`) girano **in parallelo**, quindi entrambe le varianti sono pronte nello stesso tempo.
