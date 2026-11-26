# Bravo !

Vous avez mis en place deux garde-fous d'une pipeline sécurisée :

| Contrôle | Outil | Résultat |
|---|---|---|
| Scan de vulnérabilités | Trivy | Rapport JSON et seuil `HIGH,CRITICAL` bloquant |
| Inventaire des composants | Syft | SBOM CycloneDX exploitable par d'autres outils |

## Défi bonus : le correctif et le SAST

1. Comparez avec une image **récente** : `trivy image --severity HIGH,CRITICAL alpine:3.20`. Combien de failles ont disparu en changeant simplement l'image de base ?
2. Ajoutez `--ignore-unfixed` et comparez les nombres.
3. Installez **Semgrep** (`pip install semgrep`) et lancez `semgrep --config p/python .` sur le dossier `~/cicd-app` de l'atelier 2.
4. Recherchez des secrets avec **gitleaks** (`gitleaks detect --no-git --source .`).

## Pour aller plus loin

- [Sécurité dans la CI](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/06-securite-dans-la-ci.md) · [Build, artefacts et signature](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/04-build-artefacts-et-registries.md).
- Suite : [atelier 4 — déploiement canary sur Kubernetes](https://github.com/Ghislano26/devops-Worketyamo/tree/main/12-cicd/ateliers-killercoda/atelier-04-deploiement-canary-kubernetes).
