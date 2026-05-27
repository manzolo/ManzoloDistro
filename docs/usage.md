# How to use ManzoloDistro

> 🇮🇹 [Versione italiana](usage.it.md)

---

## 1 — As a container (immediate use)

The simplest mode. Pull and run without installing anything on the host:

```bash
docker run -it --rm ghcr.io/manzolo/manzolodistro:latest

# Mount a host directory for persistent storage
docker run -it --rm -v $HOME/projects:/workspace ghcr.io/manzolo/manzolodistro:latest

# With Podman (rootless)
podman run -it --rm ghcr.io/manzolo/manzolodistro:latest
```

Use this mode to get a **reproducible environment** on any machine — CI runners, remote servers, colleagues' laptops.

---

## 2 — As a desktop distro with Distrobox

[Distrobox](https://distrobox.it/) integrates the container with your host desktop: shared home directory, display, audio, USB devices. GUI apps (Geany, VLC, LibreOffice…) appear in the system application menu as if installed natively.

```bash
distrobox create --name manzolodistro --image ghcr.io/manzolo/manzolodistro:latest
distrobox enter manzolodistro
```

**This is the recommended daily-driver mode.**

---

## 3 — As a VM with QEMU (local testing)

Generate a bootable disk and launch it in QEMU directly from the Makefile:

```bash
# Build the image locally, then generate the qcow2
make qcow2

# Boot it in QEMU (KVM + UEFI, 4 GB RAM, 2 CPUs)
make run-qcow2

# Or with custom resources
make run-qcow2 QEMU_MEM=8G QEMU_CPUS=4
```

The disk is launched with `-snapshot`, so no changes are written back to the file.
You can also import `output/qcow2/disk.qcow2` directly into **virt-manager**.

```bash
# ISO variant
make iso
make run-iso
```

---

## 4 — As an immutable OS with bootc

The [Universal Blue](https://universal-blue.org/) pattern this project is inspired by allows using the OCI image as the **operating system itself** via [`bootc`](https://containers.github.io/bootc/):

```bash
sudo bootc switch ghcr.io/manzolo/manzolodistro:latest
```

The OS becomes **atomic and immutable**: updates like a container pull, instant rollback if something breaks.

> **Note:** `bootc` on Ubuntu is currently experimental. This mode works best with Fedora/CentOS-based images.
