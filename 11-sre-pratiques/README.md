# Module 11 — SRE : pratiques d'ingénierie de fiabilité

## Pourquoi ce module ?

Ce module est **différent des précédents** : il ne porte pas sur un outil (Prometheus, Kubernetes, Docker…) mais sur des **pratiques**. Le **SRE** (*Site Reliability Engineering*) répond à la question que posent
tous les systèmes en production : *quelle fiabilité vise-t-on, comment la mesure-t-on, et que fait-on quand elle se dégrade ?* Vous y apprenez à **chiffrer la fiabilité** (SLO, budget d'erreur), à **répondre aux incidents**,
à **apprendre des pannes** (postmortem blameless), à **supprimer le toil**, à **tester la résilience** (chaos engineering) et à **concevoir pour la panne** (timeouts, retries, circuit breakers…).

Il s'appuie sur **tous les modules précédents** et prépare aux rôles de **SRE**, **Platform Engineer** ou **DevOps senior**.

> ⚠️ **Attention** : *ce module se lit en parallèle de la pratique ; il se vit plus qu'il ne s'apprend.* Les cours donnent le vocabulaire et les méthodes ; la compétence vient des incidents, des astreintes et des postmortems réels. Appliquez chaque notion à un système que vous connaissez.

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [01 → 04 Linux](../01-linux-fondamentaux/PARCOURS.md) | Processus, journaux, performance, scripts Bash (automatisation) |
| [06 Réseaux](../06-reseaux-devops/README.md) | Ports, DNS, timeouts, diagnostic de panne |
| [07 Git](../07-git-branching-interactif/README.md) | `revert`, workflows (retours arrière, gestion du changement) |
| [08 Docker](../08-docker-approfondi/README.md) / [09 Kubernetes](../09-kubernetes-approfondi/README.md) | Pods, Deployments, probes (support du chaos et de l'auto-guérison) |
| [**10 Monitoring et observabilité**](../10-monitoring-observabilite/README.md) | **Indispensable** : SLI, PromQL, alertes (les SLO se mesurent avec Prometheus) |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Introduction au SRE (Site Reliability Engineering)](cours/01-introduction-sre.md) | ⭐⭐ | Origine, SRE vs DevOps, principes, cycle SRE, rôle dans l'organisation |
| 2 | [SLI, SLO et budget d'erreur](cours/02-slo-sli-error-budget.md) | ⭐⭐⭐ | SLI/SLO/SLA, budget d'erreur, politique de gel, mesure avec Prometheus |
| 3 | [Gestion d'incident et astreinte (on-call)](cours/03-gestion-incident-et-oncall.md) | ⭐⭐⭐⭐ | Cycle de vie, rôles (IC, Comms), SEV1-SEV4, communication, astreinte soutenable |
| 4 | [Postmortem blameless](cours/04-postmortem-blameless.md) | ⭐⭐⭐ | Culture sans blâme, structure, 5 pourquoi, actions suivies |
| 5 | [Runbooks, toil et automatisation](cours/05-runbooks-et-automatisation.md) | ⭐⭐⭐ | Runbooks, toil (règle des 50 %), quand automatiser, Ansible, Rundeck |
| 6 | [Chaos engineering](cours/06-chaos-engineering.md) | ⭐⭐⭐⭐ | Hypothèse, blast radius, pannes, Chaos Mesh/Litmus, game days |
| 7 | [Patterns de fiabilité](cours/07-patterns-fiabilite.md) | ⭐⭐⭐⭐ | Timeouts, retries (backoff + jitter), circuit breaker, bulkhead, load shedding, idempotence |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — Définir un SLO et un error budget](ateliers-killercoda/atelier-01-definir-slo-et-error-budget/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 2 |
| [Atelier 02 — Postmortem blameless](ateliers-killercoda/atelier-02-postmortem-blameless/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 3, 4 |
| [Atelier 03 — Chaos engineering basique](ateliers-killercoda/atelier-03-chaos-engineering-basique/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 6, 7 |

Procédure de publication : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 (SLO) → Cours 03 → Cours 04 → Atelier 02 (postmortem)
        → Cours 05 → Cours 06 → Atelier 03 (chaos) → Cours 07
```

Les cours 03 à 05 sont **organisationnels** : mettez-les en pratique avec votre équipe (une simulation d'incident, un vrai postmortem, la mesure du toil d'un mois).

## Ce que vous saurez faire à la fin

- Définir des **SLI** et **SLO** réalistes, calculer le **budget d'erreur** et écrire la **politique** qui en découle.
- **Organiser** la réponse à un incident (rôles, sévérités, communication) et une astreinte **soutenable**.
- Rédiger un **postmortem blameless** qui produit des **actions suivies**.
- Écrire des **runbooks**, **mesurer et réduire le toil**, décider **quand automatiser**.
- Mener une **expérience de chaos** contrôlée et organiser un **game day**.
- Concevoir des services qui **tolèrent la panne** (timeouts, retries, circuit breakers, bulkheads, idempotence).

> 💡 **Conseil** : commencez petit. Un SLO, un runbook, un postmortem : c'est déjà un changement de pratique. Choisissez **un service critique** et appliquez-lui le cycle SRE (SLO → mesurer → alerter → répondre → postmortem → améliorer).

## Navigation

- [← Module 10 — Monitoring et observabilité](../10-monitoring-observabilite/README.md)
- [← README principal](../README.md)
