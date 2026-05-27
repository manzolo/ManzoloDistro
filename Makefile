# ============================================================
# ManzoloDistro – Makefile
# Operazioni comuni per build, test e generazione immagini VM
#
# Default: variante Fedora Bootc (bootc-image-builder compatible)
# ============================================================

REGISTRY := ghcr.io/manzolo
# Variante default: Fedora Bootc (bootc-image-builder compatible)
IMAGE_F  := manzolodistro-fedora
IMAGE_U  := manzolodistro
IMAGE_A  := manzolodistro-arch
TAG      ?= local
OUTPUT   := output

# Output file paths di bootc-image-builder
QCOW2_FILE := $(OUTPUT)/qcow2/disk.qcow2
ISO_FILE   := $(OUTPUT)/bootiso/install.iso

# QEMU – parametri override con: make run-qcow2 QEMU_MEM=8G QEMU_CPUS=4
QEMU_MEM   ?= 4G
QEMU_CPUS  ?= 2
OVMF_CODE  ?= /usr/share/OVMF/OVMF_CODE.fd

# docker o podman – rilevato automaticamente, override con: make build RUNTIME=podman
RUNTIME  ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)

.PHONY: all build build-ubuntu build-arch build-all \
        run run-ubuntu run-arch \
        test test-ubuntu test-arch test-all \
        qcow2 iso run-qcow2 run-iso \
        push push-ubuntu push-arch push-all \
        clean clean-all help

all: help

# ── Build ────────────────────────────────────────────────────
# Default: Fedora Bootc
build:
	$(RUNTIME) build -f Containerfile.fedora -t $(IMAGE_F):$(TAG) .

build-ubuntu:
	$(RUNTIME) build -f Containerfile -t $(IMAGE_U):$(TAG) .

build-arch:
	$(RUNTIME) build -f Containerfile.arch -t $(IMAGE_A):$(TAG) .

build-all: build build-ubuntu build-arch

# ── Run ──────────────────────────────────────────────────────
# Default: Fedora
run:
	$(RUNTIME) run -it --rm $(IMAGE_F):$(TAG)

run-ubuntu:
	$(RUNTIME) run -it --rm $(IMAGE_U):$(TAG)

run-arch:
	$(RUNTIME) run -it --rm $(IMAGE_A):$(TAG)

run-home:
	$(RUNTIME) run -it --rm -v $(HOME):/home/user $(IMAGE_F):$(TAG)

# ── Smoke test ───────────────────────────────────────────────
# Default: Fedora
test:
	@echo "==> Smoke test Fedora ($(IMAGE_F):$(TAG))..."
	@$(RUNTIME) run --rm $(IMAGE_F):$(TAG) sh -c '\
		set -e; \
		echo "── Shell & CLI ──────────────────"; \
		zsh --version; fzf --version; rg --version; jq --version; yq --version; \
		echo "── Sviluppo ─────────────────────"; \
		git --version; \
		git config --system --list | grep "alias.co"; \
		gh --version; python3 --version; node --version; \
		echo "── Docker CLI ───────────────────"; \
		docker --version; \
		echo "── Desktop ──────────────────────"; \
		niri --version; fuzzel --version; brightnessctl --version; playerctl --version; \
		echo "── Media ────────────────────────"; \
		ffmpeg -version 2>&1 | head -1; \
		echo "✅ Fedora OK"; \
	'

test-ubuntu:
	@echo "==> Smoke test Ubuntu ($(IMAGE_U):$(TAG))..."
	@$(RUNTIME) run --rm $(IMAGE_U):$(TAG) sh -c '\
		set -e; \
		echo "── Shell & CLI ──────────────────"; \
		zsh --version; fzf --version; rg --version; jq --version; yq --version; \
		echo "── Sviluppo ─────────────────────"; \
		git --version; \
		git config --system --list | grep "alias.co"; \
		gh --version; python3 --version; node --version; \
		echo "── Docker CLI ───────────────────"; \
		docker --version; \
		echo "── Desktop ──────────────────────"; \
		niri --version; fuzzel --version; brightnessctl --version; playerctl --version; \
		echo "── Media ────────────────────────"; \
		ffmpeg -version 2>&1 | head -1; \
		echo "✅ Ubuntu OK"; \
	'

test-arch:
	@echo "==> Smoke test Arch ($(IMAGE_A):$(TAG))..."
	@$(RUNTIME) run --rm $(IMAGE_A):$(TAG) sh -c '\
		set -e; \
		echo "── Shell & CLI ──────────────────"; \
		zsh --version; fzf --version; rg --version; jq --version; yq --version; \
		echo "── Sviluppo ─────────────────────"; \
		git --version; \
		git config --system --list | grep "alias.co"; \
		gh --version; python --version; node --version; \
		echo "── Docker CLI ───────────────────"; \
		docker --version; \
		echo "── Desktop ──────────────────────"; \
		niri --version; fuzzel --version; brightnessctl --version; playerctl --version; \
		echo "── Media ────────────────────────"; \
		ffmpeg -version 2>&1 | head -1; \
		echo "✅ Arch OK"; \
	'

test-all: test test-ubuntu test-arch

# ── VM image via bootc install to-disk ───────────────────────
# Approccio: l'immagine Fedora Bootc installa se stessa su un loop device
# tramite "bootc install to-disk" (bootc è già incluso in fedora-bootc).
# Non usa BIB né osbuild → nessun problema overlay-su-overlay su Ubuntu.
# Il risultato raw viene poi convertito in qcow2 con qemu-img.
#
# Richiede: qemu-img (apt install qemu-utils)
$(OUTPUT):
	mkdir -p $(OUTPUT)

# Dimensione disco raw (override: make qcow2 DISK_SIZE=80G)
# L'immagine compressa è ~6.5 GB ma ostree scrive gli oggetti decompressi → 25-35 GB.
# Si usa truncate (file sparso) → occupa su disco solo i dati effettivamente scritti.
DISK_SIZE ?= 60G

qcow2: build $(OUTPUT)
	@echo "==> Carico $(IMAGE_F):$(TAG) in root podman storage..."
	$(RUNTIME) save $(IMAGE_F):$(TAG) | sudo podman load
	@echo "==> Creo disco raw ($(DISK_SIZE))..."
	@mkdir -p $(OUTPUT)/qcow2
	truncate -s $(DISK_SIZE) $(OUTPUT)/disk.raw
	@echo "==> Setup loop device..."
	LOOP=$$(sudo losetup --find --show --partscan $(OUTPUT)/disk.raw); \
	echo "   Loop device: $$LOOP"; \
	echo "==> bootc install to-disk → $$LOOP ..."; \
	sudo podman run --rm -it --privileged \
		--pid=host \
		-v /dev:/dev \
		localhost/$(IMAGE_F):$(TAG) \
		bootc install to-disk \
			--target-imgref $(REGISTRY)/$(IMAGE_F):latest \
			--skip-fetch-check \
			--generic-image \
			--filesystem xfs \
			$$LOOP; \
	EXIT=$$?; \
	sudo losetup -d $$LOOP 2>/dev/null || true; \
	sudo podman rmi localhost/$(IMAGE_F):$(TAG) 2>/dev/null || true; \
	if [ $$EXIT -ne 0 ]; then rm -f $(OUTPUT)/disk.raw; exit $$EXIT; fi
	@echo "==> Conversione raw → qcow2..."
	qemu-img convert -f raw -O qcow2 $(OUTPUT)/disk.raw $(QCOW2_FILE)
	rm -f $(OUTPUT)/disk.raw
	@echo "✅ qcow2 disponibile in $(QCOW2_FILE)"
	@ls -lh $(QCOW2_FILE)

iso:
	@echo "⚠️  La generazione ISO richiede bootc-image-builder su host Fedora/RHEL."
	@echo "   Su Ubuntu usa il workflow GitHub Actions 'Build qcow2' (seleziona type=iso)."
	@exit 1

# ── QEMU – avvio rapido per test locale ──────────────────────
_check-ovmf:
	@test -f $(OVMF_CODE) || { \
		echo "❌ OVMF non trovato in $(OVMF_CODE)"; \
		echo "   Installa: sudo apt install ovmf"; \
		echo "   Oppure: make run-qcow2 OVMF_CODE=/percorso/OVMF_CODE.fd"; \
		exit 1; \
	}

run-qcow2: _check-ovmf
	@test -f $(QCOW2_FILE) || { echo "❌ $(QCOW2_FILE) non trovato — esegui prima: make qcow2"; exit 1; }
	@echo "==> Avvio $(QCOW2_FILE) con QEMU ($(QEMU_MEM) RAM, $(QEMU_CPUS) CPU)..."
	qemu-system-x86_64 \
		-enable-kvm \
		-m $(QEMU_MEM) \
		-smp $(QEMU_CPUS) \
		-cpu host \
		-machine q35 \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive file=$(QCOW2_FILE),format=qcow2,snapshot=on \
		-vga virtio \
		-display gtk,zoom-to-fit=on \
		-device virtio-net-pci,netdev=net0 \
		-netdev user,id=net0

run-iso: _check-ovmf
	@test -f $(ISO_FILE) || { echo "❌ $(ISO_FILE) non trovato — esegui prima: make iso"; exit 1; }
	@echo "==> Avvio $(ISO_FILE) con QEMU ($(QEMU_MEM) RAM, $(QEMU_CPUS) CPU)..."
	qemu-system-x86_64 \
		-enable-kvm \
		-m $(QEMU_MEM) \
		-smp $(QEMU_CPUS) \
		-cpu host \
		-machine q35 \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-cdrom $(ISO_FILE) \
		-boot order=d \
		-vga virtio \
		-display gtk,zoom-to-fit=on \
		-device virtio-net-pci,netdev=net0 \
		-netdev user,id=net0

# ── Push su GHCR ─────────────────────────────────────────────
# Default: Fedora
push:
	$(RUNTIME) tag $(IMAGE_F):$(TAG) $(REGISTRY)/$(IMAGE_F):latest
	$(RUNTIME) push $(REGISTRY)/$(IMAGE_F):latest

push-ubuntu: build-ubuntu
	$(RUNTIME) tag $(IMAGE_U):$(TAG) $(REGISTRY)/$(IMAGE_U):latest
	$(RUNTIME) push $(REGISTRY)/$(IMAGE_U):latest

push-arch: build-arch
	$(RUNTIME) tag $(IMAGE_A):$(TAG) $(REGISTRY)/$(IMAGE_A):latest
	$(RUNTIME) push $(REGISTRY)/$(IMAGE_A):latest

push-all: push push-ubuntu push-arch

# ── Pulizia ──────────────────────────────────────────────────
clean:
	$(RUNTIME) rmi $(IMAGE_F):$(TAG) $(IMAGE_U):$(TAG) $(IMAGE_A):$(TAG) 2>/dev/null || true
	rm -rf $(OUTPUT)

clean-all: clean
	$(RUNTIME) system prune -f

# ── Help ─────────────────────────────────────────────────────
help:
	@echo ""
	@echo "ManzoloDistro – comandi disponibili"
	@echo "  (default: variante Fedora Bootc)"
	@echo ""
	@echo "  Build"
	@echo "    make build            Build Fedora Bootc (default)"
	@echo "    make build-ubuntu     Build Ubuntu"
	@echo "    make build-arch       Build Arch Linux"
	@echo "    make build-all        Build tutte e tre"
	@echo ""
	@echo "  Run"
	@echo "    make run              Shell interattiva Fedora (default)"
	@echo "    make run-ubuntu       Shell interattiva Ubuntu"
	@echo "    make run-arch         Shell interattiva Arch"
	@echo "    make run-home         Fedora con \$$HOME montata"
	@echo ""
	@echo "  Test"
	@echo "    make test             Smoke test Fedora (default)"
	@echo "    make test-ubuntu      Smoke test Ubuntu"
	@echo "    make test-arch        Smoke test Arch"
	@echo "    make test-all         Smoke test tutte e tre"
	@echo ""
	@echo "  VM image  (variante Fedora Bootc)"
	@echo "    make qcow2            Installa via 'bootc install to-disk' → qcow2"
	@echo "                          (richiede: sudo, qemu-img; DISK_SIZE=60G default)"
	@echo "    make run-qcow2        Avvia il qcow2 con QEMU (KVM + UEFI)"
	@echo "    make iso              Non supportato localmente (vedi workflow GHA)"
	@echo ""
	@echo "  Push"
	@echo "    make push             Pusha Fedora su GHCR (default)"
	@echo "    make push-ubuntu      Pusha Ubuntu su GHCR"
	@echo "    make push-arch        Pusha Arch su GHCR"
	@echo "    make push-all         Pusha tutte e tre"
	@echo ""
	@echo "  Pulizia"
	@echo "    make clean            Rimuove immagini locali e output/"
	@echo "    make clean-all        clean + docker/podman system prune"
	@echo ""
	@echo "  Opzioni"
	@echo "    RUNTIME=docker make …        Forza docker (default: podman se disponibile)"
	@echo "    TAG=v0.1.2 make build        Build con tag specifico"
	@echo "    QEMU_MEM=8G make run-qcow2   Cambia RAM per QEMU (default: 4G)"
	@echo "    QEMU_CPUS=4 make run-qcow2   Cambia CPU per QEMU (default: 2)"
	@echo ""
