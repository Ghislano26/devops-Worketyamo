# Pipeline build, test et push

**Durée : ~30 minutes.** Compétence travaillée : enchaîner **test → build → push** avec un `Makefile`, vers un **registry** que vous hébergez.

```text
make test  →  make build (dépend de test)  →  make push (dépend de build)
```

Le fichier de pipeline d'une vraie CI (GitHub Actions, GitLab CI…) n'aurait plus qu'à appeler ces trois commandes : c'est la manière de **limiter le verrouillage** sur un outil ([cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/03-gitlab-ci-et-alternatives.md)).

## Mise en place

```bash
mkdir -p ~/cicd-app
docker --version
make --version | head -n 1 || apt-get install -y make
python3 --version
```{{exec}}

Le registry utilise l'image officielle `registry:2` (simple, sans interface ni authentification : **uniquement pour apprendre**, [cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/04-build-artefacts-et-registries.md)).
