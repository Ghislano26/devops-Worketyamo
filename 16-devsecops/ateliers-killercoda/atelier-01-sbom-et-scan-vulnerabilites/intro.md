# SBOM et scan de vulnérabilités

**Durée : ~25 minutes.** Compétence travaillée : produire la **nomenclature logicielle (SBOM)** d'une image avec **Syft**, la **scanner** avec **Trivy**, **comparer** les résultats et **lire une CVE**.

Rappel du [cours Sécurité de la chaîne d'approvisionnement](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/02-supply-chain-security.md) :

```text
Image  ──Syft──►  SBOM (CycloneDX, SPDX)  ──Trivy──►  vulnérabilités connues (CVE)
Image  ─────────────────────Trivy───────────────────►  vulnérabilités connues (CVE)
```

On étudie volontairement une **image ancienne** (`debian:10-slim`, en fin de vie) qui contient des vulnérabilités connues, et une image **récente** et minimale (`alpine:3.20`) pour comparer.

> 🌐 **Réseau** : le scénario télécharge Syft et Trivy (`raw.githubusercontent.com`, releases GitHub), des images (Docker Hub) et la **base de vulnérabilités de Trivy** (quelques dizaines de Mo, depuis `ghcr.io`) au **premier scan**. Comptez 2 à 3 minutes.

## Mise en place

```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq jq curl >/dev/null
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin v1.14.0
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.57.0
syft version | head -n 3
trivy --version | head -n 1
```{{exec}}
