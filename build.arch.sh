#!/bin/bash
# ============================================================
# build.arch.sh – Personalizzazione per la variante Arch Linux
# ============================================================
set -euo pipefail

echo "==> Inizio personalizzazione mydistro (Arch)..."

# ── Pacchetti base ───────────────────────────────────────────
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
    man-db \
    openssh \
    rsync \
    nmap \
    net-tools \
    bind

# ── Sviluppo (decommentare ciò che serve) ───────────────────
# pacman -S --noconfirm python python-pip nodejs npm go jdk-openjdk

# ── yay (AUR helper) – richiede un utente non-root ──────────
# Crea utente builder temporaneo per compilare yay
# useradd -m builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# su builder -c "git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm"
# userdel -r builder

# ── Timezone e locale ────────────────────────────────────────
ln -snf /usr/share/zoneinfo/Europe/Rome /etc/localtime
echo "LANG=it_IT.UTF-8" > /etc/locale.conf
echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# ── Alias globali ────────────────────────────────────────────
cat >> /etc/bash.bashrc << 'EOF'

# === MyDistro Arch customizations ===
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias gs='git status'
alias ..='cd ..'
alias ...='cd ../..'
alias pac='pacman -S'
alias pacu='pacman -Syu'
alias pacr='pacman -Rns'
EOF

echo "==> Build Arch completato!"
