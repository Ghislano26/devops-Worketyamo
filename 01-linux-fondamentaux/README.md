# Module 01 — Linux fondamentaux

Ce module couvre la console, le système de fichiers, les commandes de base, les utilisateurs et les permissions.

## Philosophie du module

Ce module suit la philosophie du **[Linux Upskill Challenge](https://linuxupskillchallenge.org/)** (LUC) : **on n'apprend pas Linux pour la théorie, on l'apprend pour administrer un vrai serveur**.

- **Un jour = un cours + un atelier + un défi.** La théorie ([cours](cours/)) est immédiatement mise en pratique sur **ton** serveur Ubuntu ([ateliers](ateliers/)).
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
| 1 | [01 — Introduction à Linux](cours/01-introduction-linux.md), [02 — Système de fichiers](cours/02-systeme-fichiers.md) | [Atelier 01 — Navigation](ateliers/atelier-01-navigation.md) |
| 2 | [03 — Navigation et commandes de base](cours/03-navigation-commandes-base.md) | [Atelier 02 — Gestion de fichiers](ateliers/atelier-02-gestion-fichiers.md) |
| 3 | [04 — Utilisateurs et permissions](cours/04-utilisateurs-permissions.md) | [Atelier 03 — Permissions](ateliers/atelier-03-permissions.md) |

## 🏆 Défis du jour

1. **Jour 1** — Rapport sur `/var/log` avec `find`, `ls`, `grep`, `wc` → [voir le défi](ateliers/atelier-01-navigation.md#-défi-du-jour)
2. **Jour 2** — Sauvegarde datée, suppression accidentelle et **restauration** → [voir le défi](ateliers/atelier-02-gestion-fichiers.md#-défi-du-jour)
3. **Jour 3** — Clé privée en `600` créée avec un `umask`, audit des binaires setuid → [voir le défi](ateliers/atelier-03-permissions.md#-défi-du-jour)

## Ateliers Killercoda

- [Naviguer et s'aider](ateliers-killercoda/atelier-01-navigation-killercoda/) (5 à 10 min)
- [Créer, copier, déplacer, supprimer](ateliers-killercoda/atelier-02-fichiers-killercoda/) (5 à 10 min)
- [Permissions, setgid, sticky](ateliers-killercoda/atelier-03-permissions-killercoda/) (5 à 10 min)

Voir le [README des ateliers Killercoda](ateliers-killercoda/README.md) pour les lancer.

## Navigation

- [← README principal](../README.md) · [Documentation de la restructuration LUC](../RESTRUCTURATION-LUC.md)
