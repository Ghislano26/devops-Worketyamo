# Parcours Linux — Module 04 : Expert

Ce module suit la philosophie du **Linux Upskill Challenge** (LUC) : chaque cours est immédiatement suivi d'une **mise en pratique sur TON serveur Rocky Linux**. Tu n'apprends pas pour la théorie, tu apprends pour **administrer un vrai serveur**.

Au programme : la performance du noyau, les namespaces et cgroups (ce qu'est un conteneur) et la journalisation centralisée.

## Parcours en 3 jours

| Jour | Cours (théorie) | Atelier (pratique sur serveur) | Killercoda (pratique rapide) | Défi du jour |
|---|---|---|---|---|
| **Jour 1** *(J12 du cursus Linux)* | [01 — Noyau et performance](cours/01-noyau-performance.md) | [Atelier 01 — Tuning du noyau](ateliers/atelier-01-tuning-noyau.md) | — | [Diagnostic en 60 secondes pendant une surcharge CPU](ateliers/atelier-01-tuning-noyau.md#-défi-du-jour) |
| **Jour 2** *(J13 du cursus Linux)* | [02 — Conteneurs : namespaces et cgroups](cours/02-conteneurs-namespaces.md) | [Atelier 02 — Namespaces et cgroups](ateliers/atelier-02-namespaces-cgroups.md) | [Namespaces et cgroups](ateliers-killercoda/atelier-01-namespaces-cgroups-killercoda/) | [Mini-prison : service web dans un namespace réseau + cgroup plafonné](ateliers/atelier-02-namespaces-cgroups.md#-défi-du-jour) |
| **Jour 3** *(J14 du cursus Linux)* | [03 — Observabilité et logs](cours/03-observabilite-logs.md) | [Atelier 03 — Journalisation centralisée](ateliers/atelier-03-journalisation-centralisee.md) | — | [Règle `rsyslog` dédiée et rotation avec `logrotate`](ateliers/atelier-03-journalisation-centralisee.md#-défi-du-jour) |

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

- **Ton serveur d'entraînement** : la VM **Rocky Linux 9** (`devops-lab`) construite par chaque étudiant avec Vagrant (`make up`) — voir le [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md) (2 vCPU, 4 Go de RAM, disque de la box ≥ 20 Go : vérifier avec `df -h /`, réseau NAT + privé) ; la recréation manuelle est décrite au [module 00](../00-installation-ubuntu-vm/README.md) et préparée avec la [checklist post-installation](../00-installation-ubuntu-vm/checklist-post-installation.md).
- **Accès** : en **SSH** depuis ta machine hôte (`vagrant ssh`, ou `ssh` avec les paramètres de `vagrant ssh-config`), pas depuis la console de l'hyperviseur. Procédure complète dans [SERVEUR.md](SERVEUR.md).
- **Filet de sécurité** : un **snapshot** `00-installation-propre`, puis un snapshot avant chaque jour. Pour repartir de zéro, tu restaures.
- **Sans VM sous la main ?** Les ateliers [Killercoda](ateliers-killercoda/README.md) s'exécutent dans ton navigateur.
- **Particularités de ce module** : Ce module sature volontairement la VM (CPU, mémoire, disque) et manipule réseau et cgroups : **snapshot avant chaque jour**, et ne le faites jamais sur une machine de production. Les jours 1 et 3 ne sont pas proposés sur Killercoda (mesures de performance et services système : à pratiquer sur **votre** serveur).

## Navigation

[← Module 03](../03-linux-avance/PARCOURS.md) · [Checklist](CHECKLIST.md) · [Serveur](SERVEUR.md) · [README du module](README.md) · [Module 06 — Réseaux pour DevOps →](../06-reseaux-devops/README.md)
