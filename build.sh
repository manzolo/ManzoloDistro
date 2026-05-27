#!/bin/bash
# ============================================================
# build.sh – Personalizzazione della tua distro
# Questo file viene eseguito durante il build dell'immagine.
# ============================================================
set -euo pipefail

echo "==> Inizio personalizzazione manzolodistro..."

apt-get update

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
    build-essential \
    cmake

# ── Strumenti CLI ────────────────────────────────────────────
apt-get install -y \
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
apt-get install -y \
    net-tools \
    iputils-ping \
    dnsutils \
    openssh-client \
    rsync \
    nmap

# ── Sviluppo ────────────────────────────────────────────────
apt-get install -y \
    geany \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    openjdk-21-jdk \
    sqlite3 \
    sqlitebrowser

# ── yq (Go-based, Mike Farah) ────────────────────────────────
# NOTA: il pacchetto 'yq' in apt è il wrapper Python (kislyuk),
# diverso dal yq Go-based più diffuso. Si installa dal binario ufficiale.
YQ_VERSION=$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# ── Docker CE ────────────────────────────────────────────────
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# ── GitHub CLI ───────────────────────────────────────────────
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
apt-get update && apt-get install -y gh

# ── Media ────────────────────────────────────────────────────
apt-get install -y \
    vlc \
    ffmpeg \
    imagemagick \
    audacity

# ── Office / documenti ───────────────────────────────────────
apt-get install -y \
    libreoffice \
    pdfarranger \
    ocrmypdf \
    thunderbird

# ── Virtualizzazione ─────────────────────────────────────────
apt-get install -y \
    virt-manager \
    qemu-system-x86 \
    libvirt-daemon-system \
    ovmf

# ── Desktop / compositor e dipendenze keybinding ────────────
# niri (Wayland compositor) + dms (DankMaterialShell) – entrambi dallo stesso PPA
# Ref: https://github.com/niri-wm/niri/wiki/Getting-Started
#      https://danklinux.com/docs/dankmaterialshell/installation
add-apt-repository -y ppa:avengemedia/danklinux
add-apt-repository -y ppa:avengemedia/dms
apt-get update && apt-get install -y \
    niri \
    dms \
    fuzzel \
    ptyxis \
    alacritty \
    brightnessctl \
    playerctl

# ── Configurazioni di sistema ────────────────────────────────
apt-get install -y locales
locale-gen it_IT.UTF-8
update-locale LANG=it_IT.UTF-8
ln -snf /usr/share/zoneinfo/Europe/Rome /etc/localtime
echo "Europe/Rome" > /etc/timezone

# ── Alias e customizzazioni shell globali ────────────────────
cat >> /etc/bash.bashrc << 'EOF'

# === ManzoloDistro customizations ===
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gp='git pull'
alias gco='git checkout'
alias ..='cd ..'
alias ...='cd ../..'
export HISTSIZE=10000
export HISTFILESIZE=20000
EOF

# ── Pulizia ──────────────────────────────────────────────────
apt-get autoremove -y

echo "==> Build completato!"
