# 🐧 ManzoloDistro

> ⚠️ **PROGETTO ARCHIVIATO**
>
> Questo progetto è stato abbandonato. La generazione delle immagini VM (`make qcow2`) non è stata resa funzionante su host Ubuntu — `bootc-image-builder` fallisce per restrizioni overlay annidati, e `bootc install to-disk` fallisce con un errore ENOSPC non diagnosticato durante le hardlink ostree. Sarebbe necessario un host Fedora per continuare. Il codice è conservato a scopo di riferimento.

---

La mia distribuzione Linux personale, distribuita come immagini OCI su GitHub Container Registry.

> 🇬🇧 [English version → README.md](README.md)

## Varianti

| Variante | Containerfile | Base image | Arch |
|----------|---------------|-----------|------|
| **Fedora Bootc** (default) | `Containerfile.fedora` | `fedora-bootc:latest` | amd64 |
| Ubuntu | `Containerfile` | `ubuntu:26.04` | amd64 + arm64 |
| Arch Linux | `Containerfile.arch` | `archlinux:base-devel` | amd64 |

## Cosa funziona

- `make build` / `make test` / `make run` — tutte e tre le varianti
- CI/CD GitHub Actions (build, release)

## Cosa non funziona

- `make qcow2` — non funzionante su host Ubuntu, causa non risolta
