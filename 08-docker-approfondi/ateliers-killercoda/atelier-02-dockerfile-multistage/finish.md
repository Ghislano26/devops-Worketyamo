# Bravo !

Vous avez réduit votre image de plusieurs centaines de Mo, et elle ne s'exécute plus en root. Résumé :

| | `api:naive` | `api:optimise` |
|---|---|---|
| Base | `python:3.12` (~1 Go) | `python:3.12-slim` (~150 Mo) |
| Dépendances | installées dans l'image finale | environnement virtuel copié depuis l'étape `build` |
| Utilisateur | root | UID 10001 |
| `CMD` | forme *shell* | forme *exec* |

## Pour aller plus loin

- Ajoutez un `HEALTHCHECK` et un `.dockerignore`.
- Passez à `--mount=type=cache,target=/root/.cache/pip` (BuildKit) pour accélérer les builds.
- Scannez l'image : `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image api:optimise`.
- Poursuivez avec l'[atelier 3 : Compose et réseau](https://github.com/Ghislano26/devops-Worketyamo/tree/main/08-docker-approfondi/ateliers-killercoda/atelier-03-compose-reseau).
