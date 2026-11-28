# Bravo !

Vous avez fait le travail de base de la sécurité de la chaîne d'approvisionnement :

| Étape | Ce que vous avez vu |
|---|---|
| **SBOM** | L'inventaire d'une image, en **CycloneDX** et **SPDX** |
| **Recherche** | Retrouver un composant (`openssl`) sans enquête : c'est l'intérêt d'une SBOM |
| **Scan** | Trivy sur l'image **et** sur la SBOM ; comptage par gravité |
| **Priorisation** | Filtrer sur `HIGH`, `CRITICAL` et **corrigeable** (`--ignore-unfixed`) |
| **Comparaison** | Image ancienne chargée de CVE, image minimale presque propre |

## Défi bonus

1. Générez une SBOM de **votre propre image** (`docker build`, puis `syft`) et scannez-la.
2. Faites échouer un build : `trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed debian:10-slim ; echo $?`. Intégrez cette commande à une CI ([cours 2](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/02-supply-chain-security.md)).
3. Créez un fichier `.trivyignore` avec **une CVE, une justification en commentaire et une date d'expiration**, et vérifiez qu'elle disparaît du rapport.
4. Scannez le système de fichiers d'un dépôt (`trivy fs .`) et les **secrets** (`--scanners secret`).

## Pour aller plus loin

- [Introduction au DevSecOps](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/01-introduction-devsecops.md) · [Sécurité de la chaîne d'approvisionnement](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/02-supply-chain-security.md).
- Suite : [atelier 2 — signature d'image avec cosign](https://github.com/Ghislano26/devops-Worketyamo/tree/main/16-devsecops/ateliers-killercoda/atelier-02-signature-image-cosign).
