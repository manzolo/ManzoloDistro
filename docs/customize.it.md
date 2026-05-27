# Come personalizzare ManzoloDistro

> 🇬🇧 [English version](customize.md)

---

## Varianti

| Variante | Containerfile | Script build | Default |
|----------|---------------|--------------|---------|
| **Fedora Bootc** | `Containerfile.fedora` | `build.fedora.sh` | ✅ (`make build`) |
| Ubuntu | `Containerfile` | `build.sh` | `make build-ubuntu` |
| Arch Linux | `Containerfile.arch` | `build.arch.sh` | `make build-arch` |

La variante Fedora è il default perché è **bootc-compatible** — può essere convertita in disco qcow2 o ISO tramite `bootc-image-builder` (`make qcow2` / `make iso`).

---

## Aggiungere o rimuovere pacchetti

Modifica lo script di build della variante che vuoi cambiare:

| Variante | Script | Package manager |
|----------|--------|----------------|
| Fedora | `build.fedora.sh` | `dnf install -y` |
| Ubuntu | `build.sh` | `apt-get install -y` |
| Arch | `build.arch.sh` | `pacman -S --noconfirm` |

Tutti gli script usano `set -euo pipefail` — qualsiasi errore interrompe la build.

---

## Cambiare la base image

### Fedora (default)
Modifica la riga `FROM` in `Containerfile.fedora`:

| Base | Note |
|------|------|
| `quay.io/fedora/fedora-bootc:latest` | Ultima Fedora (rolling, bootc-compatible) |
| `quay.io/fedora/fedora-bootc:42` | Versione Fedora fissa |

### Ubuntu
Modifica la riga `FROM` in `Containerfile`:

| Distro | FROM |
|--------|------|
| Ubuntu 26.04 LTS | `FROM ubuntu:26.04` |
| Ubuntu 24.04 LTS | `FROM ubuntu:24.04` |
| Debian Bookworm | `FROM debian:bookworm` |

### Arch Linux
Modifica `Containerfile.arch`.

---

## Aggiungere file di configurazione / dotfile

La cartella `config/` rispecchia il filesystem root e viene copiata nell'immagine alla build (tutte le varianti):

```
config/etc/skel/.config/niri/   →   /etc/skel/.config/niri/
config/etc/skel/.bashrc         →   /etc/skel/.bashrc
config/usr/share/backgrounds/   →   /usr/share/backgrounds/
```

I file sotto `config/etc/skel/` vengono automaticamente copiati nella home di ogni nuovo utente alla creazione dell'account. La configurazione di niri (keybinding, layout dms, colori) è già inclusa lì.

---

## Aggiornare la config niri

La config niri si trova in `config/etc/skel/.config/niri/`. Modifica i file lì e fai push — la build successiva incorporerà la config aggiornata nell'immagine.

File principali:

| File | Funzione |
|------|---------|
| `config.kdl` | Config principale niri (layout, output, keybinding base) |
| `dms/binds.kdl` | Keybinding DankMaterialShell (Super+E → nautilus, Mod+T → ptyxis, …) |
| `dms/colors.kdl` | Schema colori |
| `dms/layout.kdl` | Layout della shell |

> `dms` è disponibile su tutte e tre le varianti. Su Fedora viene installato dal COPR `avengemedia/dms` (stesso autore del PPA Ubuntu), usando `greetd` come login manager.

---

## Riferimento Makefile

```bash
make                     # mostra questo aiuto
make build               # build Fedora (default)
make build-ubuntu        # build solo Ubuntu
make build-arch          # build solo Arch
make build-all           # build tutte e tre

make run                 # shell interattiva Fedora (default)
make run-ubuntu          # shell interattiva Ubuntu
make run-arch            # shell interattiva Arch
make run-home            # Fedora con $HOME montata

make test                # smoke test Fedora (default)
make test-ubuntu         # smoke test Ubuntu
make test-arch           # smoke test Arch
make test-all            # smoke test tutte e tre

make qcow2               # genera output/qcow2/disk.qcow2 (Fedora Bootc)
make iso                 # genera output/bootiso/install.iso (Fedora Bootc)
make run-qcow2           # avvia il qcow2 con QEMU (KVM + UEFI)
make run-iso             # avvia la ISO con QEMU (KVM + UEFI)

make push                # pusha Fedora su GHCR (default)
make push-ubuntu         # pusha Ubuntu su GHCR
make push-arch           # pusha Arch su GHCR
make push-all            # pusha tutte e tre

make clean               # rimuove immagini locali e output/

# Override
RUNTIME=docker make build          # usa docker invece di podman
TAG=v0.1.2 make build              # build con tag specifico
QEMU_MEM=8G QEMU_CPUS=4 make run-qcow2
```

---

## Rilasciare una nuova versione

```bash
git tag v0.2.0
git push origin v0.2.0
```

GitHub Actions (`release.yml`) builderà tutte e tre le immagini, pubblicherà i tag versionati (`v0.2.0`, `0.2.0`, `0.2`) e creerà automaticamente una GitHub Release.
