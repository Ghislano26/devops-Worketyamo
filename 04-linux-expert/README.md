# Module 04 — Linux expert

> 📘 **Prérequis** : avoir suivi le [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md) et disposer de la VM Rocky 9 fonctionnelle.
> Les commandes de ce module s'exécutent dans la VM (`vagrant ssh`).

Ce module couvre la performance du noyau, les namespaces et cgroups (ce qu'est un conteneur) et la journalisation centralisée.

## Philosophie du module

Ce module suit la philosophie du **[Linux Upskill Challenge](https://linuxupskillchallenge.org/)** (LUC) : **on n'apprend pas Linux pour la théorie, on l'apprend pour administrer un vrai serveur**.

- **Un jour = un cours + un atelier + un défi.** La théorie ([cours](cours/)) est immédiatement mise en pratique sur **ton** serveur Rocky Linux ([ateliers](ateliers/)).
- **Le défi du jour** (en fin d'atelier) valide la compétence : on ne passe au jour suivant qu'une fois **tous les critères cochés**.
- **Pratique quotidienne et tâches concrètes** : scénarios réalistes d'administrateur (collègue qui supprime un fichier, serveur qui rame, service qui plante).
- **Accès SSH dès le premier jour** : on travaille comme sur un serveur distant ([SERVEUR.md](SERVEUR.md)).
- **Un échauffement rapide sans VM** : des [ateliers Killercoda](ateliers-killercoda/README.md) courts, focalisés sur une compétence, avec vérification automatique.

Le contenu théorique est celui des cours existants : rien n'a été supprimé.

## Pour démarrer

| Fichier | Rôle |
|---|---|
| [**PARCOURS.md**](PARCOURS.md) | Le parcours jour par jour (cours, atelier, Killercoda, défi) et ses règles |
| [**CHECKLIST.md**](CHECKLIST.md) | Les compétences « admin sys » à cocher, liées aux cours et ateliers |
| [**SERVEUR.md**](SERVEUR.md) | Mon serveur d'entraînement : SSH, snapshots, réinitialisation |
| [**ateliers-killercoda/**](ateliers-killercoda/README.md) | Pratique rapide dans le navigateur |

## Cours et ateliers

| Jour | Cours | Atelier |
|---|---|---|
| 1 | [01 — Noyau et performance](cours/01-noyau-performance.md) | [Atelier 01 — Tuning du noyau](ateliers/atelier-01-tuning-noyau.md) |
| 2 | [02 — Conteneurs : namespaces et cgroups](cours/02-conteneurs-namespaces.md) | [Atelier 02 — Namespaces et cgroups](ateliers/atelier-02-namespaces-cgroups.md) |
| 3 | [03 — Observabilité et logs](cours/03-observabilite-logs.md) | [Atelier 03 — Journalisation centralisée](ateliers/atelier-03-journalisation-centralisee.md) |
| Complément | [04 — Appels système et transitions user/kernel](cours/04-syscalls-user-kernel.md) | *(pas d'atelier dédié : la pratique avec `strace`, `perf trace` et `bpftrace` est intégrée au cours)* |

## 🏆 Défis du jour

1. **Jour 1** — Diagnostic en 60 secondes pendant une surcharge CPU → [voir le défi](ateliers/atelier-01-tuning-noyau.md#-défi-du-jour)
2. **Jour 2** — Mini-prison : service web dans un namespace réseau + cgroup plafonné → [voir le défi](ateliers/atelier-02-namespaces-cgroups.md#-défi-du-jour)
3. **Jour 3** — Règle `rsyslog` dédiée et rotation avec `logrotate` → [voir le défi](ateliers/atelier-03-journalisation-centralisee.md#-défi-du-jour)

## Ateliers Killercoda

- [Namespaces et cgroups](ateliers-killercoda/atelier-01-namespaces-cgroups-killercoda/) (5 à 10 min)

Voir le [README des ateliers Killercoda](ateliers-killercoda/README.md) pour les lancer.

## Navigation

- [← README principal](../README.md) · [Documentation de la restructuration LUC](../RESTRUCTURATION-LUC.md)
