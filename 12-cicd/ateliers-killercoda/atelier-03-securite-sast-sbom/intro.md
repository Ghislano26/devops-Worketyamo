# Sécurité dans la CI : scan d'image et SBOM

**Durée : ~25 minutes.** Compétence travaillée : **détecter les vulnérabilités** d'une image avec **Trivy** (avec un seuil bloquant) et produire un **SBOM CycloneDX** avec **Syft**.

```text
Image → scan (Trivy) → rapport JSON + seuil bloquant
Image → inventaire (Syft) → SBOM CycloneDX → réutilisable pour scanner
```

C'est la partie « sécurité » d'une pipeline ([cours 6](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/06-securite-dans-la-ci.md)) ; l'analyse du code (SAST) se fait de la même façon avec Semgrep ou CodeQL.

## Mise en place

Ce script installe `trivy` et `syft` (le téléchargement des binaires prend une minute) :

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
trivy --version | head -n 1
syft version | head -n 3
docker pull alpine:3.10
mkdir -p ~/sec
```{{exec}}
