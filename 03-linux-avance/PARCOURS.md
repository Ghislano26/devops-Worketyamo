# Parcours Linux — Module 03 : Avancé

Ce module suit la philosophie du **Linux Upskill Challenge** (LUC) : chaque cours est immédiatement suivi d'une **mise en pratique sur TON serveur Rocky Linux**. Tu n'apprends pas pour la théorie, tu apprends pour **administrer un vrai serveur**.

Au programme : le scripting Bash, le traitement de texte (`grep`, `sed`, `awk`), le stockage LVM et le durcissement.

## Parcours en 4 jours

| Jour | Cours (théorie) | Atelier (pratique sur serveur) | Killercoda (pratique rapide) | Défi du jour |
|---|---|---|---|---|
| **Jour 1** *(J8 du cursus Linux)* | [01 — Scripting Bash](cours/01-scripting-bash.md) | [Atelier 01 — Scripts d'automatisation](ateliers/atelier-01-scripts-automatisation.md) | [Scripts Bash robustes](ateliers-killercoda/atelier-01-scripting-bash-killercoda/) | [Script d'alerte disque : `getopts`, mode strict, codes de retour](ateliers/atelier-01-scripts-automatisation.md#-défi-du-jour) |
| **Jour 2** *(J9 du cursus Linux)* | [02 — Traitement de texte avancé](cours/02-traitement-texte-avance.md) | [Atelier 02 — awk, sed, grep](ateliers/atelier-02-awk-sed-grep.md) | [grep, awk et sed](ateliers-killercoda/atelier-02-awk-sed-grep-killercoda/) | [Résumé chiffré et **anonymisation** d'un journal](ateliers/atelier-02-awk-sed-grep.md#-défi-du-jour) |
| **Jour 3** *(J10 du cursus Linux)* | [03 — Stockage et LVM](cours/03-stockage-lvm.md) | [Atelier 03 — LVM](ateliers/atelier-03-lvm.md) | — | [Deux volumes logiques, montage par UUID dans `fstab`](ateliers/atelier-03-lvm.md#-défi-du-jour) |
| **Jour 4** *(J11 du cursus Linux)* | [04 — Sécurité et durcissement](cours/04-securite-durcissement.md) | [Atelier 04 — Durcissement](ateliers/atelier-04-durcissement-serveur.md) | — | [Script d'audit : 5 contrôles, code de retour = nombre de KO](ateliers/atelier-04-durcissement-serveur.md#-défi-du-jour) |

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

- **Ton serveur d'entraînement** : la VM **Rocky Linux 9** (`devops-lab`) fournie par Vagrant — voir le [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md) (2 vCPU, 4 Go de RAM, 40 Go de disque, réseau NAT + privé) ; la recréation manuelle est décrite au [module 00](../00-installation-ubuntu-vm/README.md) et préparée avec la [checklist post-installation](../00-installation-ubuntu-vm/checklist-post-installation.md).
- **Accès** : en **SSH** depuis ta machine hôte (`vagrant ssh`, ou `ssh` avec les paramètres de `vagrant ssh-config`), pas depuis la console de l'hyperviseur. Procédure complète dans [SERVEUR.md](SERVEUR.md).
- **Filet de sécurité** : un **snapshot** `00-installation-propre`, puis un snapshot avant chaque jour. Pour repartir de zéro, tu restaures.
- **Sans VM sous la main ?** Les ateliers [Killercoda](ateliers-killercoda/README.md) s'exécutent dans ton navigateur.
- **Particularités de ce module** : Le jour 3 (LVM) utilise des périphériques *loop* (aucun risque pour votre vrai disque) ; le jour 4 modifie SSH, le pare-feu et le noyau : **snapshot obligatoire** et seconde session ouverte. Ces deux jours ne sont pas proposés sur Killercoda (périphériques et pare-feu : à pratiquer sur **votre** serveur).

## Navigation

[← Module 02](../02-linux-intermediaire/PARCOURS.md) · [Checklist](CHECKLIST.md) · [Serveur](SERVEUR.md) · [README du module](README.md) · [Module 04 →](../04-linux-expert/PARCOURS.md)
