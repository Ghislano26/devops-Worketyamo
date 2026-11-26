# Parcours Linux — Module 01 : Fondamentaux

Ce module suit la philosophie du **Linux Upskill Challenge** (LUC) : chaque cours est immédiatement suivi d'une **mise en pratique sur TON serveur Ubuntu**. Tu n'apprends pas pour la théorie, tu apprends pour **administrer un vrai serveur**.

Au programme : la console, le système de fichiers, les commandes de base, les utilisateurs et les permissions.

## Parcours en 3 jours

| Jour | Cours (théorie) | Atelier (pratique sur serveur) | Killercoda (pratique rapide) | Défi du jour |
|---|---|---|---|---|
| **Jour 1** *(J1 du cursus Linux)* | [01 — Introduction à Linux](cours/01-introduction-linux.md)<br>[02 — Système de fichiers](cours/02-systeme-fichiers.md) | [Atelier 01 — Navigation](ateliers/atelier-01-navigation.md) | [Naviguer et s'aider](ateliers-killercoda/atelier-01-navigation-killercoda/) | [Rapport sur `/var/log` avec `find`, `ls`, `grep`, `wc`](ateliers/atelier-01-navigation.md#-défi-du-jour) |
| **Jour 2** *(J2 du cursus Linux)* | [03 — Navigation et commandes de base](cours/03-navigation-commandes-base.md) | [Atelier 02 — Gestion de fichiers](ateliers/atelier-02-gestion-fichiers.md) | [Créer, copier, déplacer, supprimer](ateliers-killercoda/atelier-02-fichiers-killercoda/) | [Sauvegarde datée, suppression accidentelle et **restauration**](ateliers/atelier-02-gestion-fichiers.md#-défi-du-jour) |
| **Jour 3** *(J3 du cursus Linux)* | [04 — Utilisateurs et permissions](cours/04-utilisateurs-permissions.md) | [Atelier 03 — Permissions](ateliers/atelier-03-permissions.md) | [Permissions, setgid, sticky](ateliers-killercoda/atelier-03-permissions-killercoda/) | [Clé privée en `600` créée avec un `umask`, audit des binaires setuid](ateliers/atelier-03-permissions.md#-défi-du-jour) |

> 💡 **Conseil** : compte environ **1 h à 1 h 30 par jour** (lecture du cours, atelier, défi). Le Killercoda (5 à 10 minutes) est un **échauffement sans VM**, pratique entre deux sessions ou pour réviser ; il ne remplace pas l'atelier sur ton serveur.

## Règles du parcours

1. **1 jour = 1 cours + 1 atelier.** Lis le cours (la théorie), puis pratique **tout de suite** sur ton serveur.
2. **Ne passe pas au jour suivant sans avoir validé le défi du jour.** Le défi est en fin d'atelier : tous les critères de réussite doivent être cochés.
3. **Tape les commandes, ne les copie pas aveuglément.** Quand une question de compréhension est posée dans l'atelier, réponds-y **par écrit** avant de continuer.
4. **Snapshot avant chaque jour** (`jour-XX-avant`) : tu as le droit — et même le devoir — de tout casser ; la VM se restaure en quelques secondes ([SERVEUR.md](SERVEUR.md)).
5. **Cherche d'abord toi-même** : `man`, `--help`, relire le cours. Les indices ne servent qu'en cas de blocage ; la solution est en dernier recours.
6. **Coche ta progression** dans la [CHECKLIST](CHECKLIST.md) : chaque case est liée à un cours ou un atelier précis.
7. **Pratique SSH dès le premier jour** : ne travaille pas dans la fenêtre de la VM mais depuis ton terminal, comme sur un vrai serveur distant.

## Environnement de travail

- **Ton serveur d'entraînement** : la VM **Ubuntu 24.04 LTS** installée au [module 00](../00-installation-ubuntu-vm/README.md) (4 vCPU, 4 Go de RAM, 40 Go de disque, réseau NAT) et préparée avec la [checklist post-installation](../00-installation-ubuntu-vm/checklist-post-installation.md).
- **Accès** : en **SSH** depuis ta machine hôte (`ssh utilisateur@adresse`), pas depuis la console de l'hyperviseur. Procédure complète dans [SERVEUR.md](SERVEUR.md).
- **Filet de sécurité** : un **snapshot** `00-installation-propre`, puis un snapshot avant chaque jour. Pour repartir de zéro, tu restaures.
- **Sans VM sous la main ?** Les ateliers [Killercoda](ateliers-killercoda/README.md) s'exécutent dans ton navigateur.
- **Particularités de ce module** : Les ateliers de ce module créent des utilisateurs et des groupes (`alice`, `bob`, `devs`…) : ils fournissent une étape de nettoyage, mais un snapshot reste la meilleure garantie.

## Navigation

[← Module 00 — Installation](../00-installation-ubuntu-vm/README.md) · [Checklist](CHECKLIST.md) · [Serveur](SERVEUR.md) · [README du module](README.md) · [Module 02 →](../02-linux-intermediaire/PARCOURS.md)
