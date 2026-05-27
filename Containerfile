# ============================================================
# ManzoloDistro – Ubuntu-based custom OCI image
# Cambia FROM per usare Debian (debian:bookworm) o Arch (archlinux:base)
# ============================================================
FROM ubuntu:26.04

LABEL org.opencontainers.image.title="manzolodistro"
LABEL org.opencontainers.image.description="My custom Linux distro"
LABEL org.opencontainers.image.source="https://github.com/manzolo/ManzoloDistro"

# Evita prompt interattivi durante il build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Rome

# ── 1. Aggiornamento base ────────────────────────────────────
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y

# ── 2. Script di personalizzazione principale ────────────────
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh && rm /tmp/build.sh

# ── 3. Copia dotfiles/config di sistema (opzionale) ─────────
# COPY config/ /etc/mydistro/

# ── 4. Pulizia finale cache apt ──────────────────────────────
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Default shell
CMD ["/bin/bash"]
