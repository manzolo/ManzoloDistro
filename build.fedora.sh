#!/bin/bash
# ============================================================
# build.fedora.sh – Personalizzazione della variante Fedora Bootc
# Viene eseguito durante il build dell'immagine.
# Ref desktop: https://github.com/morrolinux/morros
# ============================================================
set -euo pipefail

echo "==> Inizio personalizzazione manzolodistro (Fedora Bootc)..."

# ── Ottimizzazione dnf ────────────────────────────────────────
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

# ── Aggiornamento sistema ─────────────────────────────────────
dnf -y upgrade

# ── Repo aggiuntivi ───────────────────────────────────────────

# RPM Fusion (free + nonfree) — necessario per ffmpeg completo, ecc.
dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Docker CE (repo ufficiale)
curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo \
    -o /etc/yum.repos.d/docker-ce.repo

# GitHub CLI (repo ufficiale)
curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo \
    -o /etc/yum.repos.d/gh-cli.repo

# DankMaterialShell – COPR avengemedia/dms (stesso autore del PPA Ubuntu)
# Ref: https://github.com/morrolinux/morros
curl --output-dir "/etc/yum.repos.d/" --remote-name \
    "https://copr.fedorainfracloud.org/coprs/avengemedia/dms/repo/fedora-$(rpm -E %fedora)/avengemedia-dms-fedora-$(rpm -E %fedora).repo"

dnf -y makecache

# ── Pacchetti di sistema essenziali ──────────────────────────
dnf install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    btop \
    tree \
    unzip \
    zip \
    jq \
    tmux \
    bash-completion \
    ca-certificates \
    gnupg2 \
    cmake \
    gcc \
    gcc-c++ \
    make

# ── Strumenti CLI ─────────────────────────────────────────────
dnf install -y \
    mc \
    zsh \
    fzf \
    ripgrep \
    ShellCheck \
    rclone \
    fuse-sshfs \
    ipcalc \
    whois

# ── Strumenti di rete ────────────────────────────────────────
dnf install -y \
    net-tools \
    iputils \
    bind-utils \
    openssh-clients \
    rsync \
    nmap

# ── Sviluppo ─────────────────────────────────────────────────
dnf install -y \
    geany \
    python3-pip \
    python3-virtualenv \
    nodejs \
    npm \
    java-latest-openjdk-devel \
    sqlite \
    sqlitebrowser

# ── yq (Go-based, Mike Farah) ────────────────────────────────
# NOTA: yq in dnf è il wrapper Python — si installa dal binario ufficiale.
YQ_VERSION=$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# ── Docker CE ────────────────────────────────────────────────
dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# ── GitHub CLI ───────────────────────────────────────────────
dnf install -y gh

# ── Media ────────────────────────────────────────────────────
dnf install -y \
    vlc \
    ffmpeg \
    ImageMagick \
    audacity

# ── Office / documenti ────────────────────────────────────────
dnf install -y \
    libreoffice \
    thunderbird \
    pdfarranger

# ── Virtualizzazione ─────────────────────────────────────────
dnf install -y \
    virt-manager \
    qemu-kvm \
    libvirt \
    edk2-ovmf

# ── Desktop: niri + DankMaterialShell ────────────────────────
# niri dai repo ufficiali Fedora
# dms (quickshell + dms + greetd + dms-greeter) dal COPR avengemedia/dms
dnf install -y niri
dnf install -y quickshell dms greetd dms-greeter --allowerasing

# Companion desktop
dnf install -y \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    fuzzel \
    ptyxis \
    alacritty \
    brightnessctl \
    playerctl \
    nautilus

# ── Configurazione greetd (login manager) ────────────────────
mkdir -p /etc/greetd/
cat > /etc/greetd/config.toml << 'EOF'
[terminal]
vt = 1
[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF
rm -f /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service
systemctl enable --force greetd.service

# ── Sessione dms per nuovi utenti (via skel) ─────────────────
mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -s /usr/lib/systemd/user/dms.service \
    /etc/skel/.config/systemd/user/graphical-session.target.wants/

# ── Podman socket ─────────────────────────────────────────────
systemctl enable podman.socket

# ── Configurazione locale e timezone ─────────────────────────
ln -snf /usr/share/zoneinfo/Europe/Rome /etc/localtime
echo "LANG=it_IT.UTF-8" > /etc/locale.conf

# ── Git alias globali ────────────────────────────────────────
git config --system alias.co checkout

# ── Alias e customizzazioni shell globali ────────────────────
cat >> /etc/bashrc << 'EOF'

# === ManzoloDistro customizations ===
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gp='git pull'
alias ..='cd ..'
alias ...='cd ../..'
export HISTSIZE=10000
export HISTFILESIZE=20000
EOF

# ── Pulizia ──────────────────────────────────────────────────
dnf5 -y clean all
rm -rf /run/dnf /run/selinux-policy /var/lib/dnf

echo "==> Build Fedora completato!"
