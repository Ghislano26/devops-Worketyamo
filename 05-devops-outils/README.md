# Module 05 — Outils DevOps : Git, Docker et CI/CD

## Pourquoi ce module ?

Une fois la console Linux maîtrisée ([modules 01 à 04](../01-linux-fondamentaux/PARCOURS.md)), ce module vous ouvre la porte des **outils DevOps** : versionner son travail avec **Git**, empaqueter une application avec **Docker**
et automatiser sa livraison avec un **pipeline CI/CD**. C'est une **introduction** : chaque sujet est ensuite approfondi dans un module dédié.

| Sujet | Introduction (ce module) | Approfondissement |
|---|---|---|
| Git | [Git et workflows collaboratifs](cours/01-git-workflow.md) | [Module 07 — Git branching interactif](../07-git-branching-interactif/README.md) |
| Docker | [Docker : les fondamentaux](cours/02-docker-fondamentaux.md) | [Module 08 — Docker approfondi](../08-docker-approfondi/README.md) |
| CI/CD | [Principes du CI/CD](cours/03-ci-cd-principes.md) | [Module 12 — CI/CD complet](../12-cicd/README.md) (pipelines, sécurité, déploiements, GitOps ; se lit après Kubernetes) |

## Prérequis

- Les modules 00 à 02 (VM Ubuntu, console, permissions, processus, SSH) ; les modules 03 et 04 sont un plus.
- Une VM Ubuntu 24.04 avec accès Internet et `sudo` ; un snapshot avant chaque atelier.

## Cours

| # | Cours |
|---|---|
| 1 | [Git et workflows collaboratifs](cours/01-git-workflow.md) |
| 2 | [Docker : les fondamentaux](cours/02-docker-fondamentaux.md) |
| 3 | [Principes du CI/CD](cours/03-ci-cd-principes.md) |

## Ateliers guidés

| Atelier | Cours associé |
|---|---|
| [Atelier 01 — Git : commits, branches, fusions et conflits](ateliers/atelier-01-git-branches.md) | 1 |
| [Atelier 02 — Votre premier Dockerfile](ateliers/atelier-02-premier-dockerfile.md) | 2 |
| [Atelier 03 — Un pipeline CI/CD simple](ateliers/atelier-03-pipeline-simple.md) | 3 |

Ce module n'a pas d'ateliers Killercoda : la pratique Git interactive se trouve au [module 07](../07-git-branching-interactif/interactif/index.html), la pratique Docker au [module 08](../08-docker-approfondi/ateliers-killercoda/README.md).

## Parcours recommandé

```text
Cours 01 → Atelier 01 → Cours 02 → Atelier 02 → Cours 03 → Atelier 03
```

## Ce que vous saurez faire à la fin

- Travailler avec Git : commits atomiques, branches, fusions, résolution de conflits, annulation.
- Écrire un `Dockerfile`, construire et exécuter une image, utiliser volumes, réseaux et Compose.
- Décrire et construire un **pipeline CI/CD** simple (qualité, tests, build, déploiement, retour arrière).

## Navigation

- [← Module 04 — Linux expert](../04-linux-expert/README.md)
- [→ Module 06 — Réseaux pour DevOps](../06-reseaux-devops/README.md)
- [← README principal](../README.md)
