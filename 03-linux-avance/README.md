# Module 03 — Linux avancé

Ce module couvre le scripting Bash, le traitement de texte (`grep`, `sed`, `awk`), le stockage LVM et le durcissement.

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
| 1 | [01 — Scripting Bash](cours/01-scripting-bash.md) | [Atelier 01 — Scripts d'automatisation](ateliers/atelier-01-scripts-automatisation.md) |
| 2 | [02 — Traitement de texte avancé](cours/02-traitement-texte-avance.md) | [Atelier 02 — awk, sed, grep](ateliers/atelier-02-awk-sed-grep.md) |
| 3 | [03 — Stockage et LVM](cours/03-stockage-lvm.md) | [Atelier 03 — LVM](ateliers/atelier-03-lvm.md) |
| 4 | [04 — Sécurité et durcissement](cours/04-securite-durcissement.md) | [Atelier 04 — Durcissement](ateliers/atelier-04-durcissement-serveur.md) |

## 🏆 Défis du jour

1. **Jour 1** — Script d'alerte disque : `getopts`, mode strict, codes de retour → [voir le défi](ateliers/atelier-01-scripts-automatisation.md#-défi-du-jour)
2. **Jour 2** — Résumé chiffré et **anonymisation** d'un journal → [voir le défi](ateliers/atelier-02-awk-sed-grep.md#-défi-du-jour)
3. **Jour 3** — Deux volumes logiques, montage par UUID dans `fstab` → [voir le défi](ateliers/atelier-03-lvm.md#-défi-du-jour)
4. **Jour 4** — Script d'audit : 5 contrôles, code de retour = nombre de KO → [voir le défi](ateliers/atelier-04-durcissement-serveur.md#-défi-du-jour)

## Ateliers Killercoda

- [Scripts Bash robustes](ateliers-killercoda/atelier-01-scripting-bash-killercoda/) (5 à 10 min)
- [grep, awk et sed](ateliers-killercoda/atelier-02-awk-sed-grep-killercoda/) (5 à 10 min)

Voir le [README des ateliers Killercoda](ateliers-killercoda/README.md) pour les lancer.

## Navigation

- [← README principal](../README.md) · [Documentation de la restructuration LUC](../RESTRUCTURATION-LUC.md)
