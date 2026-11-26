# Bravo !

Vous avez construit une chaîne de livraison complète, en local :

| Étape | Commande | Garde-fou |
|---|---|---|
| Test | `make test` | Aucune image sans tests verts |
| Build | `make build` | Image non root, tags de version |
| Publication | `make push` | Artefact versionné dans un registre |

## Défi bonus : la même chaîne dans un workflow

1. Écrivez `.github/workflows/ci.yml` dont chaque étape appelle `make test`, `make build` et `make push`.
2. Ajoutez un `services: registry` ou poussez vers GHCR avec `docker/login-action`.
3. Étiquetez avec le SHA du commit : `make push VERSION=sha-$(git rev-parse --short HEAD)`.
4. Ajoutez l'étiquette `org.opencontainers.image.revision` au `docker build` et vérifiez-la avec `docker inspect`.

## Pour aller plus loin

- [Build, artefacts et registries](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/04-build-artefacts-et-registries.md) · [Tests automatisés](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/05-tests-automatises-dans-la-pipeline.md).
- Suite : [atelier 3 — sécurité : SAST, SBOM et scan d'image](https://github.com/Ghislano26/devops-Worketyamo/tree/main/12-cicd/ateliers-killercoda/atelier-03-securite-sast-sbom).
