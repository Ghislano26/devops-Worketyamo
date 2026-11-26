# Ateliers Killercoda — CI/CD complet

Quatre scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** : un serveur Ubuntu (Docker préinstallé) ou un cluster Kubernetes, dans le navigateur. Rien à installer.

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-premier-workflow-actions`](atelier-01-premier-workflow-actions/) | `ubuntu` | ~25 min | ⭐⭐ | Workflow YAML, `matrix`, `needs`, exécution locale avec `act` | [2](../cours/02-pipeline-as-code-github-actions.md) |
| [`atelier-02-pipeline-build-test-push`](atelier-02-pipeline-build-test-push/) | `ubuntu` | ~30 min | ⭐⭐⭐ | `registry:2`, `Makefile` test → build → push, image non root, tags de version | [3](../cours/03-gitlab-ci-et-alternatives.md), [4](../cours/04-build-artefacts-et-registries.md), [5](../cours/05-tests-automatises-dans-la-pipeline.md) |
| [`atelier-03-securite-sast-sbom`](atelier-03-securite-sast-sbom/) | `ubuntu` | ~25 min | ⭐⭐⭐ | Scan Trivy (rapport JSON, seuil bloquant), SBOM CycloneDX avec Syft | [6](../cours/06-securite-dans-la-ci.md) |
| [`atelier-04-deploiement-canary-kubernetes`](atelier-04-deploiement-canary-kubernetes/) | `kubernetes-kubeadm-1node` | ~30 min | ⭐⭐⭐⭐ | Canari par labels partagés, mesure de répartition, promotion | [7](../cours/07-strategies-de-deploiement.md) |

**Lisez le cours associé avant chaque atelier.** Les cours 1 (introduction), 3 (GitLab CI) et 8 (GitOps) sont surtout théoriques ; ils se pratiquent sur un vrai dépôt.

## Prérequis

- Les modules [08 Docker](../../08-docker-approfondi/README.md) (images, registries) et [09 Kubernetes](../../09-kubernetes-approfondi/README.md) (Deployments, Services).
- Aucun compte GitHub n'est nécessaire dans les ateliers : tout s'exécute **dans Killercoda**.

## Note sur `act` (atelier 1)

> **Killercoda ne peut pas déclencher de vrais workflows GitHub** : il n'est pas relié à votre dépôt et n'a pas vos secrets. L'atelier 1 utilise donc [`act`](https://github.com/nektos/act), qui exécute les fichiers `.github/workflows/*.yml` **dans des conteneurs Docker locaux**.

- `act` **imite** GitHub sans être identique : images de runners approximatives, pas de vrais secrets ni d'OIDC, comportement simplifié du cache et des artefacts ([limites détaillées](../cours/02-pipeline-as-code-github-actions.md)).
- L'atelier configure `~/.actrc` avec une image **légère** (`node:20-bookworm-slim`) qui suffit pour les étapes `run:`. Pour des actions tierces (`actions/checkout`, `setup-python`…), utilisez plutôt `catthehacker/ubuntu:act-22.04` (plus volumineuse).
- C'est un outil de **mise au point rapide** ; la validation finale se fait sur GitHub.

## Backends utilisés

| Backend (`imageid`) | Ateliers | Ce qu'il fournit |
|---|---|---|
| **`ubuntu`** | 1, 2 et 3 | Machine Ubuntu avec **Docker** ; les outils (`act`, `trivy`, `syft`) sont installés par l'introduction de chaque scénario |
| **`kubernetes-kubeadm-1node`** | 4 | Cluster **kubeadm à un nœud**, `kubectl` configuré |

## Vérifications

- **Atelier 1** : fichiers de workflow, présence de `matrix` et `needs`, et **journaux d'exécution d'`act`** (`Job succeeded`, un par job).
- **Atelier 2** : registre répondant, Makefile avec ses cibles, **`make test` exécuté** par la vérification, image non root, tags présents dans `curl localhost:5000/v2/...`.
- **Atelier 3** : rapport Trivy **JSON valide** avec au moins une vulnérabilité, SBOM avec `bomFormat: CycloneDX` et des composants.
- **Atelier 4** : deux Deployments aux bonnes images et réplicas, Service sur le label partagé `app=web`, puis état final promu.

> Les ateliers 1 à 3 **téléchargent** des outils et des bases (`act`, `trivy`, `syft`, images Docker) : prévoyez une connexion et quelques minutes au premier lancement.

## Publier sur Killercoda

Procédure complète (dépôt GitHub, `structure.json`, mises à jour, tests) dans [**`KILLERCODA.md`**](../../KILLERCODA.md). Contrôle local avant de pousser :

```bash
python3 scripts/check-killercoda.py
```

> ⚠️ **Attention** : l'atelier 3 scanne une image **volontairement ancienne** (`alpine:3.10`) : ne la déployez jamais. L'atelier 4 modifie des Deployments : ne l'exécutez pas sur un cluster partagé.

[← Retour au module 12](../README.md)
