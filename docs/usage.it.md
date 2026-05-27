# Come usare ManzoloDistro

> 🇬🇧 [English version](usage.md)

---

## 1 — Come container (uso immediato)

Il modo più semplice. Pull e avvio senza installare nulla sull'host:

```bash
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest

# Con una cartella host montata per storage persistente
docker run -it --rm -v $HOME/progetti:/workspace ghcr.io/manzolo/manzolodistro:latest

# Con Podman (rootless)
podman run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

Usa questa modalità per avere un **ambiente riproducibile** su qualsiasi macchina — CI, server remoti, computer di colleghi.

---

## 2 — Come distro desktop con Distrobox

[Distrobox](https://distrobox.it/) integra il container con il desktop host: home condivisa, display, audio, dispositivi USB. Le app GUI (Geany, VLC, LibreOffice…) appaiono nel menu di sistema come se fossero installate nativamente.

```bash
distrobox create --name manzolodistro --image ghcr.io/manzolo/manzolodistro:latest
distrobox enter manzolodistro
```

**Questa è la modalità consigliata per l'uso quotidiano.**

---

## 3 — Come VM con QEMU (test locale)

Genera un disco bootabile e avvialo in QEMU direttamente dal Makefile:

```bash
# Build locale dell'immagine + generazione qcow2
make qcow2

# Avvio in QEMU (KVM + UEFI, 4 GB RAM, 2 CPU)
make run-qcow2

# Oppure con risorse personalizzate
make run-qcow2 QEMU_MEM=8G QEMU_CPUS=4
```

Il disco viene avviato con `-snapshot`, quindi nessuna modifica viene scritta sul file originale.
Puoi anche importare `output/qcow2/disk.qcow2` direttamente in **virt-manager**.

```bash
# Variante ISO
make iso
make run-iso
```

---

## 4 — Come OS immutabile con bootc

Il pattern [Universal Blue](https://universal-blue.org/) da cui ManzoloDistro è ispirato permette di usare l'immagine OCI come **sistema operativo vero e proprio** tramite [`bootc`](https://containers.github.io/bootc/):

```bash
sudo bootc switch ghcr.io/manzolo/manzolodistro:latest
```

L'OS diventa **atomico e immutabile**: si aggiorna come un container pull, ritorno immediato all'immagine precedente in caso di problemi.

> **Nota:** `bootc` su Ubuntu è attualmente sperimentale. Questo approccio funziona meglio con immagini basate su Fedora/CentOS.
