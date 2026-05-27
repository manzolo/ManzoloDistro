# 🐧 ManzoloDistro

La mia distro Linux personale, distribuita come immagine OCI su GitHub Container Registry.

Ispirato a [MorrOS](https://github.com/morrolinux/morros) e al pattern [Universal Blue](https://github.com/ublue-os/image-template).

## 📦 Pull dell'immagine

```bash
# Ultima versione stabile
docker pull ghcr.io/manzolo/manzolodistro:latest

# Versione specifica per SHA commit (riproducibile)
docker pull ghcr.io/manzolo/manzolodistro:sha-a1b2c3d
```

## 🚀 Avvio rapido

```bash
# Shell interattiva
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest

# Con la tua home montata
docker run -it --rm -v $HOME:/home/user ghcr.io/manzolo/manzolodistro:latest

# Con Podman (consigliato per uso desktop)
podman run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

## 🔧 Struttura del repo

```
.
├── Containerfile          # Punto di ingresso build (Ubuntu 26.04)
├── Containerfile.arch     # Variante Arch Linux
├── build.sh               # Script di personalizzazione Ubuntu/Debian
├── build.arch.sh          # Script di personalizzazione Arch
├── config/                # (opzionale) File di configurazione di sistema
└── .github/
    └── workflows/
        └── build.yml      # GitHub Actions: build + push su GHCR
```

## ⚙️ Come personalizzare

### Aggiungere pacchetti
Modifica `build.sh` (Ubuntu) o `build.arch.sh` (Arch):

```bash
# Ubuntu/Debian
apt-get install -y il-tuo-pacchetto

# Arch
pacman -S --noconfirm il-tuo-pacchetto
```

### Cambiare base image
Nel `Containerfile`, modifica la riga `FROM`:

| Distro | FROM |
|--------|------|
| Ubuntu 26.04 LTS | `FROM ubuntu:26.04` |
| Ubuntu 24.04 LTS | `FROM ubuntu:24.04` |
| Ubuntu 22.04 LTS | `FROM ubuntu:22.04` |
| Debian Bookworm | `FROM debian:bookworm` |
| Debian Slim | `FROM debian:bookworm-slim` |
| Arch Linux | Usa `Containerfile.arch` |

### Copia file di configurazione
Decommenta nel `Containerfile`:
```dockerfile
COPY config/ /etc/mydistro/
```
e crea la cartella `config/` con i tuoi file.

## 🤖 CI/CD – Trigger di build

Il workflow `.github/workflows/build.yml` rebuilda l'immagine:

| Trigger | Quando |
|---------|--------|
| **Push** | Ogni push su `main` che modifica Containerfile, build.sh o config/ |
| **Schedule** | Ogni lunedì alle 04:00 UTC (aggiorna i pacchetti base) |
| **Manual** | Dalla tab "Actions" → "Run workflow" |

I tag generati automaticamente:

- `latest` → sempre l'ultima build di `main`
- `sha-XXXXXXX` → SHA breve del commit (build riproducibile)
- `YYYYMMDD` → data del build schedulato
- `v1.2.3` / `1.2` → se usi i tag Git (release)

## 🌍 Rendere l'immagine pubblica

Di default le immagini GHCR seguono la visibilità del repo.
Per renderla pubblica:

1. Vai su `https://github.com/manzolo?tab=packages`
2. Clicca sull'immagine → **Package settings**
3. Cambia visibilità in **Public**

## 📋 Prima configurazione

1. **Crea il repo** `ManzoloDistro` su GitHub sotto l'account `manzolo`
2. **Fai un push** su `main` → GitHub Actions si avvia automaticamente
3. Dopo il primo build, l'immagine sarà disponibile su:
   `https://github.com/manzolo/ManzoloDistro/pkgs/container/manzolodistro`

> **Nota:** Il `GITHUB_TOKEN` ha già i permessi per pushare su GHCR — non servono configurazioni extra.
