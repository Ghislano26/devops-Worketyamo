# Restructuration « Linux Upskill Challenge » (LUC)

Ce document explique comment les modules Linux (01 à 04) ont été réorientés selon la philosophie du **[Linux Upskill Challenge](https://linuxupskillchallenge.org/)** : *un défi pratique, quotidien, sur un vrai serveur Ubuntu accessible en SSH*.

## 1. La philosophie adoptée

Le LUC repose sur quelques idées simples que ce dépôt reprend :

| Principe du LUC | Application dans ce dépôt |
|---|---|
| **Un vrai serveur**, pas un simulateur | Chaque jour se pratique sur la VM Ubuntu 24.04 du [module 00](00-installation-ubuntu-vm/README.md) |
| **SSH dès le premier jour** | Chaque module a un guide [SERVEUR.md](01-linux-fondamentaux/SERVEUR.md) : connexion SSH, snapshots, réinitialisation |
| **Un petit pas par jour** | **1 jour = 1 cours + 1 atelier + 1 défi** ; on ne passe pas au jour suivant sans valider le défi |
| **Tâches concrètes d'administrateur** | Chaque défi est un scénario réaliste (suppression accidentelle, serveur qui rame, intranet injoignable…) |
| **Apprendre en faisant** | La théorie reste dans les cours, mais elle est *immédiatement* suivie de pratique |
| **Auto-évaluation** | Une [checklist de compétences](01-linux-fondamentaux/CHECKLIST.md) par module, chaque case liée à un cours ou un atelier |

> 📌 **À retenir** : la restructuration **n'a supprimé aucun cours** et **n'a pas réécrit leur contenu théorique**. Elle **ajoute** une couche de pratique et de suivi par-dessus.

## 2. Ce qui a changé

### Ajouts dans chaque module Linux (01 à 04)

| Fichier / dossier | Rôle |
|---|---|
| `README.md` | **Nouveau** : présentation du module, philosophie LUC, liens, liste des défis (ces modules n'avaient pas de README) |
| `PARCOURS.md` | Le parcours « en N jours » : cours, atelier, Killercoda, défi du jour ; règles du parcours ; environnement |
| `CHECKLIST.md` | Compétences « admin sys » à cocher, liées aux cours et ateliers |
| `SERVEUR.md` | « Mon serveur d'entraînement » : SSH, snapshots avant chaque jour, réinitialisation, commandes depuis l'hôte |
| `ateliers-killercoda/` | Ateliers courts (5-10 min) pour pratiquer **sans VM**, avec `verify.sh` strict |

### Modifications des fichiers existants

- Les **14 ateliers** existants (modules 01 à 04) reçoivent une section **« 🏆 Défi du jour »** en fin de document, avant le lien de navigation : objectif, contexte, consignes, indices, critères de réussite, solution dans un bloc `<details>`. Chaque défi n'utilise que ce qui a été vu dans le cours associé et les cours précédents.
- Le **README racine** mentionne le cursus orienté LUC et renvoie vers ce document.

### Ce qui n'a pas changé

- Les **15 cours** Linux (modules 01 à 04) : aucun n'a été modifié ni supprimé.
- Le corps des **ateliers** : seule la section « Défi du jour » est ajoutée.
- Les modules **00, 05, 06, 07, 08, 09** ne sont pas touchés.

## 3. Le parcours Linux en 4 modules et 14 jours

| Jours | Module | Parcours | Compétence centrale |
|---|---|---|---|
| J1 → J3 | [01 — Fondamentaux](01-linux-fondamentaux/PARCOURS.md) | Navigation, fichiers, permissions | Se déplacer, manipuler, sécuriser les fichiers |
| J4 → J7 | [02 — Intermédiaire](02-linux-intermediaire/PARCOURS.md) | Processus/systemd, APT, réseau, SSH | Exploiter un serveur : services, logiciels, accès |
| J8 → J11 | [03 — Avancé](03-linux-avance/PARCOURS.md) | Scripting, texte, LVM, durcissement | Automatiser et sécuriser |
| J12 → J14 | [04 — Expert](04-linux-expert/PARCOURS.md) | Performance, namespaces/cgroups, logs | Comprendre et diagnostiquer en profondeur |

Les 14 jours détaillés :

| Jour | Cours | Défi du jour |
|---|---|---|
| J1 | 01 Introduction + 02 Système de fichiers | [Rapport sur `/var/log`](01-linux-fondamentaux/ateliers/atelier-01-navigation.md#-défi-du-jour) |
| J2 | 03 Navigation et commandes de base | [Sauvegarde et restauration](01-linux-fondamentaux/ateliers/atelier-02-gestion-fichiers.md#-défi-du-jour) |
| J3 | 04 Utilisateurs et permissions | [Clé en 600, umask, setuid](01-linux-fondamentaux/ateliers/atelier-03-permissions.md#-défi-du-jour) |
| J4 | 01 Processus et services | [Service `heartbeat` résistant](02-linux-intermediaire/ateliers/atelier-01-processus-systemd.md#-défi-du-jour) |
| J5 | 02 Gestion des paquets | [Origine d'un binaire, `hold`](02-linux-intermediaire/ateliers/atelier-02-apt-gestion-paquets.md#-défi-du-jour) |
| J6 | 03 Réseau, bases | [Diagnostic `/etc/hosts`](02-linux-intermediaire/ateliers/atelier-03-diagnostic-reseau.md#-défi-du-jour) |
| J7 | 04 SSH et clés | [Alias SSH et `rsync`](02-linux-intermediaire/ateliers/atelier-04-ssh-securise.md#-défi-du-jour) |
| J8 | 01 Scripting Bash | [Script d'alerte disque](03-linux-avance/ateliers/atelier-01-scripts-automatisation.md#-défi-du-jour) |
| J9 | 02 Traitement de texte | [Résumé et anonymisation d'un journal](03-linux-avance/ateliers/atelier-02-awk-sed-grep.md#-défi-du-jour) |
| J10 | 03 Stockage et LVM | [Deux volumes logiques, `fstab` par UUID](03-linux-avance/ateliers/atelier-03-lvm.md#-défi-du-jour) |
| J11 | 04 Sécurité et durcissement | [Script d'audit](03-linux-avance/ateliers/atelier-04-durcissement-serveur.md#-défi-du-jour) |
| J12 | 01 Noyau et performance | [Diagnostic en 60 secondes](04-linux-expert/ateliers/atelier-01-tuning-noyau.md#-défi-du-jour) |
| J13 | 02 Conteneurs : namespaces et cgroups | [Mini-prison réseau + cgroup](04-linux-expert/ateliers/atelier-02-namespaces-cgroups.md#-défi-du-jour) |
| J14 | 03 Observabilité et logs | [Règle `rsyslog` et rotation](04-linux-expert/ateliers/atelier-03-journalisation-centralisee.md#-défi-du-jour) |

> Le LUC original dure 20 jours ; ce cursus en compte **14** parce qu'il s'appuie sur des cours déjà denses (un jour = un cours complet). Les jours 1 (introduction + système de fichiers) et les modules 02 et 04 regroupent parfois plusieurs sujets sous un seul atelier existant.

### Le cursus global (Linux → Réseaux → Git → Docker → Kubernetes)

| Étape | Module | Jours indicatifs |
|---|---|---|
| Pré-requis | [00 — Installation d'Ubuntu en VM](00-installation-ubuntu-vm/README.md) | « Jour 0 » |
| 1. **Linux** | 01 à 04 | **14 jours** (ci-dessus) |
| 2. Réseaux | [06 — Réseaux pour DevOps](06-reseaux-devops/README.md) | 5 jours (5 cours, 4 ateliers) |
| 3. Git | [07 — Git branching interactif](07-git-branching-interactif/README.md) | 5 jours (5 cours, 4 ateliers, exercices interactifs) |
| 4. Docker | [08 — Docker approfondi](08-docker-approfondi/README.md) | 6 jours (6 cours, 3 ateliers Killercoda) |
| 5. Kubernetes | [09 — Kubernetes approfondi](09-kubernetes-approfondi/README.md) | 7 jours (7 cours, 3 ateliers Killercoda) |
| Complément | [05 — Outils DevOps](05-devops-outils/cours/01-git-workflow.md) | Introduction (Git, Docker, CI/CD), utile avant 07 et 08 |

Soit environ **37 jours** pour le cœur du cursus (14 + 5 + 5 + 6 + 7), à raison d'un jour par cours.

## 4. Les nouveaux fichiers

| Module | Parcours | Checklist | Serveur | README | Killercoda |
|---|---|---|---|---|---|
| 01 | [PARCOURS](01-linux-fondamentaux/PARCOURS.md) | [CHECKLIST](01-linux-fondamentaux/CHECKLIST.md) | [SERVEUR](01-linux-fondamentaux/SERVEUR.md) | [README](01-linux-fondamentaux/README.md) | [3 scénarios](01-linux-fondamentaux/ateliers-killercoda/README.md) |
| 02 | [PARCOURS](02-linux-intermediaire/PARCOURS.md) | [CHECKLIST](02-linux-intermediaire/CHECKLIST.md) | [SERVEUR](02-linux-intermediaire/SERVEUR.md) | [README](02-linux-intermediaire/README.md) | [2 scénarios](02-linux-intermediaire/ateliers-killercoda/README.md) |
| 03 | [PARCOURS](03-linux-avance/PARCOURS.md) | [CHECKLIST](03-linux-avance/CHECKLIST.md) | [SERVEUR](03-linux-avance/SERVEUR.md) | [README](03-linux-avance/README.md) | [2 scénarios](03-linux-avance/ateliers-killercoda/README.md) |
| 04 | [PARCOURS](04-linux-expert/PARCOURS.md) | [CHECKLIST](04-linux-expert/CHECKLIST.md) | [SERVEUR](04-linux-expert/SERVEUR.md) | [README](04-linux-expert/README.md) | [1 scénario](04-linux-expert/ateliers-killercoda/README.md) |

**Ateliers Killercoda Linux (8)** — backend `ubuntu`, 2 étapes chacun, `verify.sh` strict :

- Module 01 : navigation et aide · fichiers · permissions (setgid / sticky).
- Module 02 : processus et services systemd · paquets APT.
- Module 03 : scripting Bash · `grep`, `awk`, `sed`.
- Module 04 : namespaces et cgroups.

Les sujets qui touchent au pare-feu, à SSH, au réseau, aux disques ou à la performance ne sont **volontairement pas** proposés sur Killercoda : ils se pratiquent sur **ton** serveur, avec un snapshot.

## 5. Comment utiliser ce parcours

1. Prépare ton serveur : [module 00](00-installation-ubuntu-vm/README.md), puis [SERVEUR.md](01-linux-fondamentaux/SERVEUR.md) (connexion SSH, premier snapshot).
2. Ouvre le [PARCOURS du module 01](01-linux-fondamentaux/PARCOURS.md) et suis-le jour après jour.
3. Chaque jour : **snapshot → cours → atelier → défi** ; coche la [CHECKLIST](01-linux-fondamentaux/CHECKLIST.md).
4. Entre deux sessions, **échauffe-toi** ou **révise** avec les ateliers Killercoda.
5. Une fois le module 04 validé, enchaîne avec le module 06 (Réseaux), puis Git, Docker et Kubernetes.

[← Retour au README principal](README.md)
