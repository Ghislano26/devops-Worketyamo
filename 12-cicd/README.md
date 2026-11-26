# Module 12 — CI/CD complet

## Pourquoi ce module ?

Vous savez écrire du code ([Git](../07-git-branching-interactif/README.md)), l'empaqueter ([Docker](../08-docker-approfondi/README.md)) et le faire tourner sur un cluster ([Kubernetes](../09-kubernetes-approfondi/README.md)). Reste la question : **comment livrer, souvent et sans peur ?** Ce module construit la **chaîne de livraison** : pipelines as code, artefacts versionnés et signés, tests automatisés, sécurité intégrée, stratégies de déploiement progressif et GitOps.

> 🗺️ **Place dans le parcours.** Ce module porte le **numéro 12** mais se lit **juste après Kubernetes (09)** et **avant** [Monitoring (10)](../10-monitoring-observabilite/README.md) et [SRE (11)](../11-sre-pratiques/README.md). La numérotation des dossiers est gelée pour éviter des renommages risqués ; l'ordre pédagogique est expliqué dans le [README principal](../README.md). La logique : **on livre d'abord** (CI/CD), **on observe ensuite** (Monitoring), **on définit la fiabilité** à partir de ce qu'on observe (SRE).

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [07 Git](../07-git-branching-interactif/README.md) | Branches, merge, pull requests : le déclencheur d'un pipeline |
| [08 Docker](../08-docker-approfondi/README.md) | Images, Dockerfile, registries : l'artefact produit par la CI |
| [09 Kubernetes](../09-kubernetes-approfondi/README.md) | Deployments, Services, probes : la cible des déploiements |
| [05 Outils DevOps](../05-devops-outils/README.md) | Introduction aux principes du CI/CD (ce module les approfondit) |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Introduction au CI/CD](cours/01-introduction-cicd.md) | ⭐⭐ | CI vs Continuous Delivery vs Continuous Deployment vs GitOps, pipeline typique, métriques DORA |
| 2 | [Pipeline as code avec GitHub Actions](cours/02-pipeline-as-code-github-actions.md) | ⭐⭐⭐ | Workflows, jobs, secrets, matrices, cache, artefacts, `needs`/`if`/`concurrency`, test local avec `act` |
| 3 | [GitLab CI et alternatives](cours/03-gitlab-ci-et-alternatives.md) | ⭐⭐⭐ | `.gitlab-ci.yml`, runners, comparaison des outils, Tekton, critères de choix |
| 4 | [Build, artefacts et registries](cours/04-build-artefacts-et-registries.md) | ⭐⭐⭐ | Artefacts immuables, registries, SemVer, `buildx` multi-arch, cosign, SLSA |
| 5 | [Tests automatisés dans la pipeline](cours/05-tests-automatises-dans-la-pipeline.md) | ⭐⭐⭐ | Pyramide des tests, ordre, parallélisation, tests flaky, couverture, Testcontainers |
| 6 | [Sécurité dans la CI](cours/06-securite-dans-la-ci.md) | ⭐⭐⭐⭐ | SAST, DAST, SCA, secrets, SBOM, signature, sécurisation de la CI elle-même |
| 7 | [Stratégies de déploiement](cours/07-strategies-de-deploiement.md) | ⭐⭐⭐⭐ | Rolling, blue/green, canary, A/B testing, feature flags, rollback |
| 8 | [GitOps et déploiement déclaratif](cours/08-gitops-et-deploiement-declaratif.md) | ⭐⭐⭐⭐⭐ | Principes GitOps, Argo CD, Flux, dépôt de configuration, Kustomize/Helm, secrets |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — Premier workflow GitHub Actions avec `act`](ateliers-killercoda/atelier-01-premier-workflow-actions/intro.md) (2 étapes) | `ubuntu` | ⭐⭐ | 2 |
| [Atelier 02 — Pipeline build, test et push](ateliers-killercoda/atelier-02-pipeline-build-test-push/intro.md) (3 étapes) | `ubuntu` | ⭐⭐⭐ | 3, 4, 5 |
| [Atelier 03 — Sécurité : scan Trivy et SBOM](ateliers-killercoda/atelier-03-securite-sast-sbom/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 6 |
| [Atelier 04 — Déploiement canary sur Kubernetes](ateliers-killercoda/atelier-04-deploiement-canary-kubernetes/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 7 |

Procédure de publication et note sur `act` : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 → Cours 03 → Cours 04 → Cours 05 → Atelier 02
        → Cours 06 → Atelier 03 → Cours 07 → Atelier 04 → Cours 08
```

> 💡 **Conseil** : appliquez chaque cours à **un petit projet fil rouge** (une API simple dans un dépôt GitHub) : commencez par un workflow qui exécute les tests, ajoutez le build d'image, puis les scans, puis le déploiement. À la fin, vous aurez une vraie chaîne de livraison à montrer.

## Ce que vous saurez faire à la fin

- Écrire une **pipeline as code** (GitHub Actions, GitLab CI) et la tester en local.
- Construire, **versionner, signer** et publier des artefacts dans un registre.
- Organiser les **tests** pour échouer vite et garder une pipeline fiable.
- **Sécuriser la CI** (SAST, SCA, secrets, SBOM, provenance).
- Déployer **sans risque excessif** (rolling, blue/green, canary, feature flags) avec un retour arrière prêt.
- Mettre en place **GitOps** avec Argo CD et un dépôt de configuration séparé.

## Navigation

- [← Module 09 — Kubernetes approfondi](../09-kubernetes-approfondi/README.md)
- [→ Module 10 — Monitoring et observabilité](../10-monitoring-observabilite/README.md) (étape suivante du parcours)
- [← README principal](../README.md)
