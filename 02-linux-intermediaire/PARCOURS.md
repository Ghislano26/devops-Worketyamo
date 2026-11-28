# Parcours Linux — Module 02 : Intermédiaire

Ce module suit la philosophie du **Linux Upskill Challenge** (LUC) : chaque cours est immédiatement suivi d'une **mise en pratique sur TON serveur Rocky Linux**. Tu n'apprends pas pour la théorie, tu apprends pour **administrer un vrai serveur**.

Au programme : les processus et systemd, les paquets DNF, le réseau de base et SSH.

## Parcours en 4 jours

| Jour | Cours (théorie) | Atelier (pratique sur serveur) | Killercoda (pratique rapide) | Défi du jour |
|---|---|---|---|---|
| **Jour 1** *(J4 du cursus Linux)* | [01 — Processus et services](cours/01-processus-services.md) | [Atelier 01 — Processus et systemd](ateliers/atelier-01-processus-systemd.md) | [Processus et services systemd](ateliers-killercoda/atelier-01-processus-services-killercoda/) | [Service `heartbeat` résistant : `Restart=always` et *drop-in*](ateliers/atelier-01-processus-systemd.md#-défi-du-jour) |
| **Jour 2** *(J5 du cursus Linux)* | [02 — Gestion des paquets](cours/02-gestion-paquets.md) | [Atelier 02 — Gestion des paquets avec DNF](ateliers/atelier-02-apt-gestion-paquets.md) | [Gérer les paquets avec APT](ateliers-killercoda/atelier-02-apt-paquets-killercoda/) | [Origine d'un binaire (`rpm -qf`), `dnf versionlock`, `remove`](ateliers/atelier-02-apt-gestion-paquets.md#-défi-du-jour) |
| **Jour 3** *(J6 du cursus Linux)* | [03 — Réseau, bases](cours/03-reseaux-base.md) | [Atelier 03 — Diagnostic réseau](ateliers/atelier-03-diagnostic-reseau.md) | — | [Diagnostic d'une entrée `/etc/hosts` erronée (nom → adresse → port)](ateliers/atelier-03-diagnostic-reseau.md#-défi-du-jour) |
| **Jour 4** *(J7 du cursus Linux)* | [04 — SSH et clés](cours/04-ssh-cles.md) | [Atelier 04 — SSH sécurisé](ateliers/atelier-04-ssh-securise.md) | — | [Alias SSH, clé dédiée et `rsync` sécurisé](ateliers/atelier-04-ssh-securise.md#-défi-du-jour) |

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
- **Particularités de ce module** : Les jours 3 et 4 modifient le pare-feu et SSH : **gardez une seconde session ouverte** et un snapshot, sinon une erreur peut vous enfermer dehors. Pas de Killercoda pour ces deux jours (réseau et SSH se pratiquent sur **votre** serveur ; le réseau est approfondi au [module 06](../06-reseaux-devops/README.md)).

## Navigation

[← Module 01](../01-linux-fondamentaux/PARCOURS.md) · [Checklist](CHECKLIST.md) · [Serveur](SERVEUR.md) · [README du module](README.md) · [Module 03 →](../03-linux-avance/PARCOURS.md)
