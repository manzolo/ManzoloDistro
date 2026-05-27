#!/bin/bash
# ============================================================
# build.sh – Personalizzazione della tua distro
# Questo file viene eseguito durante il build dell'immagine.
# Aggiungi qui tutti i pacchetti e le configurazioni che vuoi.
# ============================================================
set -euo pipefail

echo "==> Inizio personalizzazione mydistro..."

# ── Pacchetti di sistema essenziali ─────────────────────────
apt-get install -y \
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
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential

# ── Strumenti di rete ────────────────────────────────────────
apt-get install -y \
    net-tools \
    iputils-ping \
    dnsutils \
    openssh-client \
    rsync \
    nmap

# ── Sviluppo (decommentare ciò che serve) ───────────────────
# apt-get install -y python3 python3-pip python3-venv
# apt-get install -y nodejs npm
# apt-get install -y golang-go
# apt-get install -y default-jdk

# ── Aggiunta repository esterni (esempio: Docker CLI) ────────
# install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
#     | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
#     https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
#     > /etc/apt/sources.list.d/docker.list
# apt-get update && apt-get install -y docker-ce-cli

# ── Configurazioni di sistema ────────────────────────────────
# Imposta locale italiana
apt-get install -y locales
locale-gen it_IT.UTF-8
update-locale LANG=it_IT.UTF-8

# Imposta timezone
ln -snf /usr/share/zoneinfo/Europe/Rome /etc/localtime
echo "Europe/Rome" > /etc/timezone

# ── Alias e customizzazioni shell globali ────────────────────
cat >> /etc/bash.bashrc << 'EOF'

# === MyDistro customizations ===
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

echo "==> Build completato!"
