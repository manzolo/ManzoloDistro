#!/bin/bash
# ============================================================
# build.arch.sh – Personalizzazione per la variante Arch Linux
# ============================================================
set -euo pipefail

echo "==> Inizio personalizzazione manzolodistro (Arch)..."

# ── Pacchetti di sistema essenziali ─────────────────────────
pacman -S --noconfirm \
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
    cmake \
    base-devel

# ── Strumenti CLI ────────────────────────────────────────────
pacman -S --noconfirm \
    mc \
    zsh \
    fzf \
    ripgrep \
    shellcheck \
    rclone \
    sshfs \
    ipcalc \
    whois \
    mitmproxy

# ── Strumenti di rete ────────────────────────────────────────
pacman -S --noconfirm \
    net-tools \
    iputils \
    bind \
    openssh \
    rsync \
    nmap

# ── Sviluppo ────────────────────────────────────────────────
pacman -S --noconfirm \
    geany \
    python \
    python-pip \
    nodejs \
    npm \
    jdk21-openjdk \
    sqlite \
    sqlitebrowser

# ── yq (Go-based, Mike Farah) ────────────────────────────────
# NOTA: 'go-yq' è in AUR; si installa dal binario ufficiale per semplicità.
YQ_VERSION=$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# ── Docker CE ────────────────────────────────────────────────
pacman -S --noconfirm \
    docker \
    docker-buildx \
    docker-compose

# ── GitHub CLI ───────────────────────────────────────────────
pacman -S --noconfirm github-cli

# ── Media ────────────────────────────────────────────────────
pacman -S --noconfirm \
    vlc \
    ffmpeg \
    imagemagick \
    audacity

# ── Office / documenti ───────────────────────────────────────
pacman -S --noconfirm \
    libreoffice-fresh \
    pdfarranger \
    thunderbird

# ocrmypdf non è nei repo ufficiali Arch (solo AUR): installa via pip
pip install --break-system-packages ocrmypdf

# ── Virtualizzazione ─────────────────────────────────────────
pacman -S --noconfirm \
    virt-manager \
    qemu-desktop \
    libvirt \
    edk2-ovmf

# ── Desktop / compositor ─────────────────────────────────────
# niri + DankMaterialShell (dms-shell-niri) + dipendenze companion
# Ref: https://github.com/niri-wm/niri/wiki/Getting-Started
pacman -S --noconfirm \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    alacritty \
    dms-shell-niri \
    matugen \
    qt6-multimedia-ffmpeg

# ── Timezone e locale ────────────────────────────────────────
ln -snf /usr/share/zoneinfo/Europe/Rome /etc/localtime
echo "LANG=it_IT.UTF-8" > /etc/locale.conf
echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# ── Alias globali ────────────────────────────────────────────
cat >> /etc/bash.bashrc << 'EOF'

# === ManzoloDistro Arch customizations ===
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias gs='git status'
alias gp='git pull'
alias ..='cd ..'
alias ...='cd ../..'
alias pac='pacman -S'
alias pacu='pacman -Syu'
alias pacr='pacman -Rns'
export HISTSIZE=10000
export HISTFILESIZE=20000
EOF

echo "==> Build Arch completato!"
