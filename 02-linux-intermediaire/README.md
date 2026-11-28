# Module 02 — Linux intermédiaire

> 📘 **Prérequis** : avoir suivi le [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md) et disposer de la VM Rocky 9 fonctionnelle.
> Les commandes de ce module s'exécutent dans la VM (`vagrant ssh`).

Ce module couvre les processus et systemd, les paquets DNF, le réseau de base et SSH.

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
| 1 | [01 — Processus et services](cours/01-processus-services.md) | [Atelier 01 — Processus et systemd](ateliers/atelier-01-processus-systemd.md) |
| 2 | [02 — Gestion des paquets](cours/02-gestion-paquets.md) | [Atelier 02 — Gestion des paquets avec DNF](ateliers/atelier-02-apt-gestion-paquets.md) |
| 3 | [03 — Réseau, bases](cours/03-reseaux-base.md) | [Atelier 03 — Diagnostic réseau](ateliers/atelier-03-diagnostic-reseau.md) |
| 4 | [04 — SSH et clés](cours/04-ssh-cles.md) | [Atelier 04 — SSH sécurisé](ateliers/atelier-04-ssh-securise.md) |

## 🏆 Défis du jour

1. **Jour 1** — Service `heartbeat` résistant : `Restart=always` et *drop-in* → [voir le défi](ateliers/atelier-01-processus-systemd.md#-défi-du-jour)
2. **Jour 2** — Origine d'un binaire (`rpm -qf`), `dnf versionlock`, `remove` → [voir le défi](ateliers/atelier-02-apt-gestion-paquets.md#-défi-du-jour)
3. **Jour 3** — Diagnostic d'une entrée `/etc/hosts` erronée (nom → adresse → port) → [voir le défi](ateliers/atelier-03-diagnostic-reseau.md#-défi-du-jour)
4. **Jour 4** — Alias SSH, clé dédiée et `rsync` sécurisé → [voir le défi](ateliers/atelier-04-ssh-securise.md#-défi-du-jour)

## Ateliers Killercoda

- [Processus et services systemd](ateliers-killercoda/atelier-01-processus-services-killercoda/) (5 à 10 min)
- [Gérer les paquets avec APT](ateliers-killercoda/atelier-02-apt-paquets-killercoda/) (5 à 10 min, **version rapide Ubuntu** : `apt` au lieu de `dnf`)

Voir le [README des ateliers Killercoda](ateliers-killercoda/README.md) pour les lancer.

## Navigation

- [← README principal](../README.md) · [Documentation de la restructuration LUC](../RESTRUCTURATION-LUC.md)
