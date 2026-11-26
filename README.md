# 🐧 DevOps Worketyamo — Du terminal Linux au SRE

Bienvenue dans le **cursus DevOps de Worketyamo** : un parcours complet, en français, qui mène du **premier `ls` sur un serveur Linux** jusqu'aux **pratiques SRE** (SLO, incidents, chaos engineering), en passant par les réseaux, Git, Docker, Kubernetes et l'observabilité.

**Public visé** : étudiants, autodidactes et professionnels (admin système, développeurs, futurs DevOps/SRE) qui veulent apprendre à **administrer, déployer, observer et fiabiliser** des systèmes réels. Aucune connaissance préalable de Linux n'est exigée.

## 🧠 Philosophie pédagogique

- **Théorie avant pratique** : chaque atelier est précédé d'un cours qui explique le *pourquoi*, y compris le fonctionnement interne (inodes, namespaces, netfilter, TSDB…).
- **Pratique immédiate** : ateliers guidés sur *votre* serveur Ubuntu et ateliers **[Killercoda](KILLERCODA.md)** interactifs avec vérification automatique, sans rien installer.
- **Progression du débutant à l'expert** : chaque module s'appuie sur les précédents et ne répète pas les bases.
- **Console-first** : l'interface graphique est un confort, la console est le métier.
- **Scénarios réalistes** : on joue l'administrateur ou le SRE face à de vraies situations (panne, incident, migration, audit).
- **Défi quotidien** : le cursus Linux (modules 01 à 04) suit la philosophie du *Linux Upskill Challenge* : un jour = un cours + un atelier + un défi ([détails](RESTRUCTURATION-LUC.md)).

## 📊 Le cursus en un coup d'œil

| Module | Thème | Niveau | Nb cours | Nb ateliers | Killercoda |
|---|---|---|---|---|---|
| [00 — Installation d'Ubuntu 24.04 LTS en machine virtuelle](00-installation-ubuntu-vm/README.md) | Installer son serveur d'entraînement | Débutant | — (3 guides) | 0 | — |
| [01 — Linux fondamentaux](01-linux-fondamentaux/README.md) | La console, les fichiers, les permissions | Débutant | 4 | 3 | 3 scénario(s) ⚠️ non déclarés |
| [02 — Linux intermédiaire](02-linux-intermediaire/README.md) | Processus, paquets, réseau de base, SSH | Intermédiaire | 4 | 4 | 2 scénario(s) ⚠️ non déclarés |
| [03 — Linux avancé](03-linux-avance/README.md) | Scripting, traitement de texte, LVM, durcissement | Avancé | 4 | 4 | 2 scénario(s) ⚠️ non déclarés |
| [04 — Linux expert](04-linux-expert/README.md) | Performance du noyau, namespaces et cgroups, journalisation | Expert | 3 | 3 | 1 scénario(s) ⚠️ non déclarés |
| [05 — Outils DevOps : Git, Docker et CI/CD](05-devops-outils/README.md) | Introduction à Git, Docker et CI/CD | Intermédiaire | 3 | 3 | — |
| [06 — Réseaux pour DevOps](06-reseaux-devops/README.md) | DNS, ports, routage et NAT, TLS, diagnostic | Intermédiaire à avancé | 5 | 4 | — |
| [07 — Git branching interactif](07-git-branching-interactif/README.md) | Git avancé avec exercices interactifs animés | Intermédiaire | 5 | 4 + 4 exercices interactifs | — |
| [08 — Docker approfondi](08-docker-approfondi/README.md) | Conteneurs : architecture, images, Dockerfile, réseau, Compose, sécurité | Intermédiaire à avancé | 6 | 0 | 3 scénario(s) ✅ |
| [09 — Kubernetes approfondi](09-kubernetes-approfondi/README.md) | Orchestration : architecture, workloads, réseau, stockage, configuration, scheduling, sécurité | Avancé | 7 | 0 | 3 scénario(s) ✅ |
| [10 — Monitoring & Observabilité](10-monitoring-observabilite/README.md) | Prometheus, PromQL, Grafana, Alertmanager, Loki, OpenTelemetry | Avancé | 7 | 0 | 4 scénario(s) ✅ |
| [11 — SRE : pratiques d'ingénierie de fiabilité](11-sre-pratiques/README.md) | SLO, incidents, postmortems, runbooks, chaos engineering, patterns de fiabilité | Avancé | 7 | 0 | 3 scénario(s) ✅ |

*« Nb ateliers » compte les ateliers guidés (dossier `ateliers/`) ; les modules 08 à 11 proposent leurs ateliers **uniquement sur Killercoda**. « ⚠️ non déclarés » : voir la section [Ateliers Killercoda](#-ateliers-killercoda).*

## 🗺️ Parcours recommandé (ordre pédagogique)

L'ordre suit une logique simple : **on apprend à manipuler une machine, puis à la relier au monde, puis à y déployer des applications, puis à les observer, puis à les fiabiliser.**

### 1. Fondations : Linux (modules 00 → 04)

- **Pourquoi à cet endroit ?** Une machine Linux et la console sont le socle de tout : conteneurs, Kubernetes et outils d'observabilité reposent sur les processus, les fichiers, les permissions, le réseau et les cgroups du noyau. On commence donc par un **serveur d'entraînement** (00), puis par la console et les permissions (01), l'exploitation (02), l'automatisation et la sécurité (03) et la compréhension du noyau (04).
- **Prérequis** : Aucun.
- **À la fin, vous saurez** : Administrer un serveur Ubuntu en SSH : fichiers, services, paquets, scripts, stockage, durcissement, diagnostic de performance, et expliquer ce qu'est un conteneur au niveau du noyau.

### 2. Transverse : Réseaux (module 06)

- **Pourquoi à cet endroit ?** Presque toutes les pannes en production ont une composante réseau (DNS, port fermé, certificat expiré, NAT). On le traite **avant** Docker et Kubernetes, dont les réseaux reposent sur ces mécanismes.
- **Prérequis** : Modules 01 à 03 (04 recommandé).
- **À la fin, vous saurez** : Diagnostiquer une panne réseau avec méthode, et expliquer comment un conteneur sort sur Internet.

### 3. Outils DevOps : Git (05, 07) → Docker (05, 08) → Kubernetes (09)

- **Pourquoi à cet endroit ?** Le module 05 est une **introduction** à Git, Docker et CI/CD ; chaque sujet est ensuite **approfondi** : Git (07) pour travailler en équipe sans peur de l'historique, Docker (08) pour empaqueter proprement, Kubernetes (09) pour orchestrer à grande échelle. Chaque étape suppose la précédente (Kubernetes exécute des images Docker, qui vivent dans un dépôt Git).
- **Prérequis** : Modules 04 et 06 ; pour Kubernetes, le module 08.
- **À la fin, vous saurez** : Versionner, construire une image de production, déployer et exposer une application sur un cluster, avec stockage, configuration et sécurité.

### 4. Observabilité : Monitoring (module 10)

- **Pourquoi à cet endroit ?** Une application déployée n'est pas une application maîtrisée : il faut la **mesurer**. Ce module s'appuie sur les conteneurs et Kubernetes pour observer métriques, logs et traces.
- **Prérequis** : Modules 04, 06, 08 et 09.
- **À la fin, vous saurez** : Mesurer un service (SLI), construire des dashboards, concevoir des alertes utiles et monitorer un cluster.

### 5. Pratiques d'ingénierie : SRE (module 11)

- **Pourquoi à cet endroit ?** Dernière étape : ce ne sont plus des outils mais des **pratiques**. Elles ne prennent leur sens qu'avec l'observabilité (on ne gère pas ce qu'on ne mesure pas) et l'expérience des modules précédents.
- **Prérequis** : Modules 01 à 10 (surtout le 10).
- **À la fin, vous saurez** : Fixer des SLO, répondre à un incident, apprendre des pannes sans blâme, réduire le toil et tester la résilience.

Pour chaque module : **lisez le cours, pratiquez l'atelier correspondant, puis passez au suivant**. Gardez les [cheatsheets](ressources/cheatsheets/commandes-linux.md) sous la main.

> 🏁 Après Kubernetes, le module [`10-monitoring-observabilite/`](10-monitoring-observabilite/README.md) montre comment observer et alerter sur un système en production, et le module [`11-sre-pratiques/`](11-sre-pratiques/README.md) clôt le cursus par les pratiques d'ingénierie de fiabilité.

> 💡 **Conseil** : prenez un *snapshot* de la VM avant chaque atelier. En cas d'erreur, vous revenez en arrière en quelques secondes.

## 🎯 Catalogue détaillé des modules

### [Module 00 — Installation d'Ubuntu 24.04 LTS en machine virtuelle](00-installation-ubuntu-vm/README.md)

Installez Ubuntu 24.04 LTS dans une machine virtuelle (VMware ou VirtualBox) : c'est le **serveur d'entraînement** de tout le cursus.

**Prérequis** : Aucun : un ordinateur avec 8 Go de RAM et 60 Go de disque libres.

**Guides** :

- [Guide d'installation d'Ubuntu 24.04 LTS avec VMware](00-installation-ubuntu-vm/guide-installation-vmware.md)
- [Guide d'installation d'Ubuntu 24.04 LTS avec VirtualBox](00-installation-ubuntu-vm/guide-installation-virtualbox.md)
- [Checklist post-installation d'Ubuntu 24.04 LTS](00-installation-ubuntu-vm/checklist-post-installation.md)

**Ateliers Killercoda** : aucun (la pratique se fait sur votre VM).

**Compétences acquises** :

- Créer et configurer une VM Ubuntu (4 vCPU, 4 Go, 40 Go, réseau NAT)
- Vérifier l'ISO, installer le système et OpenSSH
- Appliquer la checklist post-installation (mises à jour, outils, utilisateur sudo)
- Prendre et restaurer un snapshot

### [Module 01 — Linux fondamentaux](01-linux-fondamentaux/README.md)

Premiers pas sur un serveur Linux : se repérer, manipuler les fichiers, comprendre utilisateurs et permissions. Orienté **défi quotidien** (parcours en 3 jours).

**Prérequis** : Module 00 (VM Ubuntu prête).

**Cours** :

1. [Introduction à Linux et à la console](01-linux-fondamentaux/cours/01-introduction-linux.md)
2. [Le système de fichiers Linux](01-linux-fondamentaux/cours/02-systeme-fichiers.md)
3. [Navigation et commandes de base](01-linux-fondamentaux/cours/03-navigation-commandes-base.md)
4. [Utilisateurs, groupes et permissions](01-linux-fondamentaux/cours/04-utilisateurs-permissions.md)

**Ateliers guidés** :

- [Atelier 01 — Navigation dans le système de fichiers](01-linux-fondamentaux/ateliers/atelier-01-navigation.md)
- [Atelier 02 — Gestion de fichiers, redirections et recherche](01-linux-fondamentaux/ateliers/atelier-02-gestion-fichiers.md)
- [Atelier 03 — Utilisateurs, groupes et permissions](01-linux-fondamentaux/ateliers/atelier-03-permissions.md)

**Ateliers Killercoda** (**non déclarés dans `structure.json`** (voir la section Killercoda)) :

- [Linux : naviguer et s'aider soi-même](01-linux-fondamentaux/ateliers-killercoda/atelier-01-navigation-killercoda/)
- [Linux : créer, copier, déplacer, supprimer](01-linux-fondamentaux/ateliers-killercoda/atelier-02-fichiers-killercoda/)
- [Linux : permissions, propriétaire, setgid et sticky](01-linux-fondamentaux/ateliers-killercoda/atelier-03-permissions-killercoda/)

**Parcours en jours** : [PARCOURS](01-linux-fondamentaux/PARCOURS.md) · [Checklist de compétences](01-linux-fondamentaux/CHECKLIST.md) · [Mon serveur d'entraînement](01-linux-fondamentaux/SERVEUR.md)

**Compétences acquises** :

- Naviguer et chercher dans l'arborescence sans interface graphique
- Créer, copier, déplacer et supprimer des fichiers ; utiliser redirections et pipes
- Lire et écrire des permissions (`chmod`, `chown`, setgid, sticky bit)
- Gérer utilisateurs, groupes et règles `sudo`
- Trouver de l'aide avec `man` et `--help`

### [Module 02 — Linux intermédiaire](02-linux-intermediaire/README.md)

Exploiter un serveur : surveiller les processus, piloter les services avec systemd, gérer les paquets, diagnostiquer le réseau et sécuriser SSH (parcours en 4 jours).

**Prérequis** : Module 01.

**Cours** :

1. [Processus, signaux et services systemd](02-linux-intermediaire/cours/01-processus-services.md)
2. [Gestion des paquets avec APT](02-linux-intermediaire/cours/02-gestion-paquets.md)
3. [Réseau : les bases sous Linux](02-linux-intermediaire/cours/03-reseaux-base.md)
4. [SSH et authentification par clés](02-linux-intermediaire/cours/04-ssh-cles.md)

**Ateliers guidés** :

- [Atelier 01 — Processus et services systemd](02-linux-intermediaire/ateliers/atelier-01-processus-systemd.md)
- [Atelier 02 — APT et gestion des paquets](02-linux-intermediaire/ateliers/atelier-02-apt-gestion-paquets.md)
- [Atelier 03 — Diagnostic réseau](02-linux-intermediaire/ateliers/atelier-03-diagnostic-reseau.md)
- [Atelier 04 — SSH sécurisé](02-linux-intermediaire/ateliers/atelier-04-ssh-securise.md)

**Ateliers Killercoda** (**non déclarés dans `structure.json`** (voir la section Killercoda)) :

- [Linux : processus et services systemd](02-linux-intermediaire/ateliers-killercoda/atelier-01-processus-services-killercoda/)
- [Linux : gérer les paquets avec APT](02-linux-intermediaire/ateliers-killercoda/atelier-02-apt-paquets-killercoda/)

**Parcours en jours** : [PARCOURS](02-linux-intermediaire/PARCOURS.md) · [Checklist de compétences](02-linux-intermediaire/CHECKLIST.md) · [Mon serveur d'entraînement](02-linux-intermediaire/SERVEUR.md)

**Compétences acquises** :

- Lister, prioriser et arrêter des processus ; écrire une unité systemd
- Installer, mettre à jour et auditer des paquets avec APT
- Diagnostiquer une panne réseau couche par couche
- Se connecter par clés SSH et durcir `sshd`

### [Module 03 — Linux avancé](03-linux-avance/README.md)

Automatiser et sécuriser : scripts Bash robustes, analyse de journaux avec `grep`/`sed`/`awk`, stockage LVM et durcissement d'un serveur (parcours en 4 jours).

**Prérequis** : Modules 01 et 02.

**Cours** :

1. [Scripting Bash](03-linux-avance/cours/01-scripting-bash.md)
2. [Traitement de texte avancé : `grep`, `sed`, `awk` et expressions régulières](03-linux-avance/cours/02-traitement-texte-avance.md)
3. [Stockage Linux et LVM](03-linux-avance/cours/03-stockage-lvm.md)
4. [Sécurité et durcissement d'un serveur Linux](03-linux-avance/cours/04-securite-durcissement.md)

**Ateliers guidés** :

- [Atelier 01 — Scripts d'automatisation Bash](03-linux-avance/ateliers/atelier-01-scripts-automatisation.md)
- [Atelier 02 — `awk`, `sed` et `grep` : enquête sur des journaux](03-linux-avance/ateliers/atelier-02-awk-sed-grep.md)
- [Atelier 03 — LVM : volumes logiques, extension à chaud et snapshots](03-linux-avance/ateliers/atelier-03-lvm.md)
- [Atelier 04 — Durcissement d'un serveur Ubuntu](03-linux-avance/ateliers/atelier-04-durcissement-serveur.md)

**Ateliers Killercoda** (**non déclarés dans `structure.json`** (voir la section Killercoda)) :

- [Linux : écrire des scripts Bash robustes](03-linux-avance/ateliers-killercoda/atelier-01-scripting-bash-killercoda/)
- [Linux : analyser du texte avec grep, awk et sed](03-linux-avance/ateliers-killercoda/atelier-02-awk-sed-grep-killercoda/)

**Parcours en jours** : [PARCOURS](03-linux-avance/PARCOURS.md) · [Checklist de compétences](03-linux-avance/CHECKLIST.md) · [Mon serveur d'entraînement](03-linux-avance/SERVEUR.md)

**Compétences acquises** :

- Écrire des scripts Bash robustes (mode strict, `getopts`, codes de retour, `trap`)
- Filtrer, compter et transformer du texte avec `grep`, `awk` et `sed`
- Créer, agrandir et sauvegarder des volumes logiques LVM
- Durcir un serveur (pare-feu, `fail2ban`, `sysctl`) et mesurer le résultat avec Lynis

### [Module 04 — Linux expert](04-linux-expert/README.md)

Comprendre Linux en profondeur : diagnostiquer la performance, construire un « conteneur » à la main (namespaces, cgroups) et centraliser les journaux (parcours en 3 jours).

**Prérequis** : Module 03.

**Cours** :

1. [Noyau Linux et performance](04-linux-expert/cours/01-noyau-performance.md)
2. [Conteneurs : namespaces et cgroups](04-linux-expert/cours/02-conteneurs-namespaces.md)
3. [Observabilité et journalisation](04-linux-expert/cours/03-observabilite-logs.md)

**Ateliers guidés** :

- [Atelier 01 — Diagnostic de performance et tuning du noyau](04-linux-expert/ateliers/atelier-01-tuning-noyau.md)
- [Atelier 02 — Construire un conteneur à la main : namespaces et cgroups](04-linux-expert/ateliers/atelier-02-namespaces-cgroups.md)
- [Atelier 03 — Journalisation centralisée avec rsyslog](04-linux-expert/ateliers/atelier-03-journalisation-centralisee.md)

**Ateliers Killercoda** (**non déclarés dans `structure.json`** (voir la section Killercoda)) :

- [Linux expert : namespaces et cgroups](04-linux-expert/ateliers-killercoda/atelier-01-namespaces-cgroups-killercoda/)

**Parcours en jours** : [PARCOURS](04-linux-expert/PARCOURS.md) · [Checklist de compétences](04-linux-expert/CHECKLIST.md) · [Mon serveur d'entraînement](04-linux-expert/SERVEUR.md)

**Compétences acquises** :

- Appliquer la méthode USE pour trouver un goulot (CPU, mémoire, disque)
- Régler le noyau avec `sysctl` et mesurer l'effet
- Isoler un processus avec les namespaces et le limiter avec les cgroups v2
- Router, centraliser et faire tourner des journaux (`rsyslog`, `logrotate`)

### [Module 05 — Outils DevOps : Git, Docker et CI/CD](05-devops-outils/README.md)

Ouverture vers les outils DevOps : versionner avec Git, empaqueter avec Docker et automatiser la livraison avec un pipeline CI/CD. Introduction avant les modules d'approfondissement 07 et 08.

**Prérequis** : Modules 00 à 02.

**Cours** :

1. [Git et workflows collaboratifs](05-devops-outils/cours/01-git-workflow.md)
2. [Docker : les fondamentaux](05-devops-outils/cours/02-docker-fondamentaux.md)
3. [Principes du CI/CD](05-devops-outils/cours/03-ci-cd-principes.md)

**Ateliers guidés** :

- [Atelier 01 — Git : commits, branches, fusions et conflits](05-devops-outils/ateliers/atelier-01-git-branches.md)
- [Atelier 02 — Votre premier Dockerfile](05-devops-outils/ateliers/atelier-02-premier-dockerfile.md)
- [Atelier 03 — Un pipeline CI/CD simple](05-devops-outils/ateliers/atelier-03-pipeline-simple.md)

**Ateliers Killercoda** : aucun (la pratique se fait sur votre VM ; voir aussi les modules 07 et 08).

**Compétences acquises** :

- Travailler avec Git : commits, branches, fusions, conflits, annulation
- Écrire et exécuter un `Dockerfile`
- Décrire un pipeline CI/CD (qualité, tests, build, déploiement, rollback)

### [Module 06 — Réseaux pour DevOps](06-reseaux-devops/README.md)

Les réseaux **orientés DevOps** : uniquement ce qu'il faut maîtriser pour déployer et dépanner des services, avec des exemples Docker et Kubernetes.

**Prérequis** : Modules 01 à 03 (le module 04 est recommandé pour les namespaces).

**Cours** :

1. [DNS : les fondamentaux pour un DevOps](06-reseaux-devops/cours/01-dns-fondamentaux.md)
2. [Ports, sockets et états TCP](06-reseaux-devops/cours/02-ports-et-sockets.md)
3. [Routage, NAT et réseaux de conteneurs](06-reseaux-devops/cours/03-routage-et-nat.md)
4. [TLS et HTTPS pour un DevOps](06-reseaux-devops/cours/04-tls-et-https.md)
5. [Diagnostic réseau pour DevOps](06-reseaux-devops/cours/05-diagnostic-reseau-devops.md)

**Ateliers guidés** :

- [Atelier 01 — Résolution DNS : dig, resolvectl, dnsmasq et TTL](06-reseaux-devops/ateliers/atelier-01-dns-resolution.md)
- [Atelier 02 — Ports, sockets et états TCP](06-reseaux-devops/ateliers/atelier-02-ports-et-services.md)
- [Atelier 03 — Routage et NAT : deux namespaces, un pont et iptables](06-reseaux-devops/ateliers/atelier-03-routage-nat.md)
- [Atelier 04 — Diagnostic complet : DNS, port et certificat](06-reseaux-devops/ateliers/atelier-04-diagnostic-complet.md)

**Ateliers Killercoda** : aucun (la pratique se fait sur votre VM).

**Compétences acquises** :

- Suivre une résolution DNS complète et expliquer les TTL
- Lire les états TCP et l'exposition d'un service (`bind`, ports)
- Reconstruire à la main le réseau d'un conteneur (namespaces, veth, pont, NAT)
- Inspecter un certificat TLS et comprendre une chaîne incomplète
- Mener un diagnostic méthodique DNS → TCP → TLS → HTTP → application

### [Module 07 — Git branching interactif](07-git-branching-interactif/README.md)

Comprendre Git comme un **graphe de commits** et des pointeurs. Cours, ateliers sur de vrais dépôts et une mini-application web animée (inspirée de Learn Git Branching).

**Prérequis** : Module 05 (bases de Git).

**Cours** :

1. [Modéliser Git : un graphe de commits](07-git-branching-interactif/cours/01-modeliser-git.md)
2. [Branches, `switch` et HEAD](07-git-branching-interactif/cours/02-branches-et-checkout.md)
3. [Merge, rebase et cherry-pick](07-git-branching-interactif/cours/03-merge-rebase-cherry-pick.md)
4. [Reflog et récupération](07-git-branching-interactif/cours/04-reflog-et-recuperation.md)
5. [Workflows d'équipe avec Git](07-git-branching-interactif/cours/05-workflows-equipe.md)

**Ateliers guidés** :

- [Atelier 01 — Premiers commits, branches et HEAD](07-git-branching-interactif/ateliers/atelier-01-premiers-commits-branches.md)
- [Atelier 02 — Merge ou rebase ? Fusionner, rebaser, résoudre un conflit](07-git-branching-interactif/ateliers/atelier-02-merge-vs-rebase.md)
- [Atelier 03 — Cherry-pick, rétroportage et tags de version](07-git-branching-interactif/ateliers/atelier-03-cherry-pick-et-tags.md)
- [Atelier 04 — Récupération : reflog, reset et revert](07-git-branching-interactif/ateliers/atelier-04-recuperation-reflog.md)

**Exercices interactifs animés** (à ouvrir dans un navigateur : [sommaire](07-git-branching-interactif/interactif/index.html)) :

- [1. Branches de base : créer, se déplacer, committer](07-git-branching-interactif/interactif/exercices/01-branches-de-base.html)
- [2. Merge : fusionner deux historiques](07-git-branching-interactif/interactif/exercices/02-merge.html)
- [3. Rebase : rejouer ses commits sur une nouvelle base](07-git-branching-interactif/interactif/exercices/03-rebase.html)
- [4. Cherry-pick : prélever des commits précis](07-git-branching-interactif/interactif/exercices/04-cherry-pick.html)

**Ateliers Killercoda** : aucun (la pratique se fait sur votre VM).

**Compétences acquises** :

- Représenter un dépôt comme un graphe et prédire l'effet d'une commande
- Choisir entre `merge`, `rebase` et `cherry-pick`
- Récupérer du travail perdu avec le reflog ; annuler avec `revert`
- Choisir un workflow d'équipe (GitHub Flow, Git Flow, trunk-based) et utiliser Conventional Commits

### [Module 08 — Docker approfondi](08-docker-approfondi/README.md)

De l'usage à la maîtrise de Docker : comment ça fonctionne, comment construire des images de production, comment orchestrer plusieurs conteneurs et les sécuriser.

**Prérequis** : Modules 04 (namespaces, cgroups), 06 (réseaux) et 05 (bases de Docker).

**Cours** :

1. [Architecture de Docker](08-docker-approfondi/cours/01-architecture-docker.md)
2. [Images et couches](08-docker-approfondi/cours/02-images-et-couches.md)
3. [Dockerfile avancé](08-docker-approfondi/cours/03-dockerfile-avance.md)
4. [Réseau et stockage dans Docker](08-docker-approfondi/cours/04-reseau-et-stockage-docker.md)
5. [Docker Compose](08-docker-approfondi/cours/05-docker-compose.md)
6. [Sécurité des conteneurs et bonnes pratiques](08-docker-approfondi/cours/06-securite-et-bonnes-pratiques.md)

**Ateliers Killercoda** (déclarés dans `structure.json`) :

- [Docker : premiers pas, conteneurs éphémères et volumes](08-docker-approfondi/ateliers-killercoda/atelier-01-premiers-pas/)
- [Dockerfile : de l'image naïve au multi-stage](08-docker-approfondi/ateliers-killercoda/atelier-02-dockerfile-multistage/)
- [Docker Compose : réseau personnalisé et DNS interne](08-docker-approfondi/ateliers-killercoda/atelier-03-compose-reseau/)

**Compétences acquises** :

- Expliquer la chaîne `docker` → `dockerd` → `containerd` → `runc`
- Écrire un Dockerfile de production (multi-stage, cache, BuildKit, non-root, PID 1)
- Concevoir réseau et stockage Docker (DNS interne, DNAT, volumes, sauvegarde)
- Orchestrer une pile avec Compose (healthchecks, profils, surcharges)
- Durcir un conteneur (capabilities, seccomp, lecture seule, secrets, scan)

### [Module 09 — Kubernetes approfondi](09-kubernetes-approfondi/README.md)

Kubernetes de niveau CKA/CKAD : comprendre l'architecture, déployer et exposer des applications, gérer stockage et configuration, ordonnancer et sécuriser.

**Prérequis** : Modules 04, 06 et 08.

**Cours** :

1. [Kubernetes : architecture et composants](09-kubernetes-approfondi/cours/01-architecture-et-composants.md)
2. [Pods et workloads](09-kubernetes-approfondi/cours/02-pods-et-workloads.md)
3. [Services et réseau dans Kubernetes](09-kubernetes-approfondi/cours/03-services-et-reseau-kubernetes.md)
4. [Stockage et persistance dans Kubernetes](09-kubernetes-approfondi/cours/04-stockage-persistance.md)
5. [Configuration et secrets](09-kubernetes-approfondi/cours/05-configuration-et-secrets.md)
6. [Scheduling et gestion des ressources](09-kubernetes-approfondi/cours/06-scheduling-et-ressources.md)
7. [Sécurité : RBAC, Pod Security et NetworkPolicies](09-kubernetes-approfondi/cours/07-securite-rbac-et-networkpolicies.md)

**Ateliers Killercoda** (déclarés dans `structure.json`) :

- [Kubernetes : premier Pod, Deployment, rollout et rollback](09-kubernetes-approfondi/ateliers-killercoda/atelier-01-premier-pod-et-deployment/)
- [Kubernetes : Service ClusterIP et NodePort](09-kubernetes-approfondi/ateliers-killercoda/atelier-02-service-et-nodeport/)
- [Kubernetes : ConfigMap, Secret et RBAC](09-kubernetes-approfondi/ateliers-killercoda/atelier-03-configmap-secret-et-rbac/)

**Compétences acquises** :

- Expliquer le flux d'un `kubectl apply` et le rôle de chaque composant
- Choisir le bon workload (Deployment, StatefulSet, DaemonSet, Job) et gérer un rollout
- Exposer et relier des applications (Services, CoreDNS, Ingress, NetworkPolicies)
- Gérer stockage persistant, ConfigMaps et Secrets
- Contrôler le placement (requests/limits, taints, affinités) et sécuriser (RBAC, Pod Security)

### [Module 10 — Monitoring & Observabilité](10-monitoring-observabilite/README.md)

Observer, mesurer et alerter sur un système en production, avec les trois piliers : **métriques**, **logs** et **traces**.

**Prérequis** : Modules 04, 06, 08 et 09.

**Cours** :

1. [Introduction à l'observabilité](10-monitoring-observabilite/cours/01-introduction-observabilite.md)
2. [Prometheus : fondamentaux](10-monitoring-observabilite/cours/02-prometheus-fondamentaux.md)
3. [PromQL et types de métriques](10-monitoring-observabilite/cours/03-promql-et-metriques.md)
4. [Grafana : visualisation](10-monitoring-observabilite/cours/04-grafana-visualisation.md)
5. [Alertmanager et stratégie d'alerte](10-monitoring-observabilite/cours/05-alertmanager-alertes.md)
6. [Logs avec Loki](10-monitoring-observabilite/cours/06-logs-avec-loki.md)
7. [Traces distribuées et OpenTelemetry](10-monitoring-observabilite/cours/07-traces-et-opentelemetry.md)

**Ateliers Killercoda** (déclarés dans `structure.json`) :

- [Prometheus et Grafana : votre première pile de monitoring](10-monitoring-observabilite/ateliers-killercoda/atelier-01-prometheus-grafana-ubuntu/)
- [PromQL : interroger Prometheus](10-monitoring-observabilite/ateliers-killercoda/atelier-02-promql-requetes/)
- [Alertes : règles Prometheus et Alertmanager](10-monitoring-observabilite/ateliers-killercoda/atelier-03-alertes-avec-alertmanager/)
- [Monitoring Kubernetes avec kube-prometheus-stack](10-monitoring-observabilite/ateliers-killercoda/atelier-04-monitoring-kubernetes/)

**Compétences acquises** :

- Choisir quoi mesurer (signaux d'or, RED, USE) et exprimer des SLO
- Déployer Prometheus et Grafana et écrire des requêtes PromQL justes
- Concevoir des alertes utiles et configurer Alertmanager
- Centraliser des logs avec Loki et comprendre traces et OpenTelemetry
- Monitorer un cluster Kubernetes avec `kube-prometheus-stack`

### [Module 11 — SRE : pratiques d'ingénierie de fiabilité](11-sre-pratiques/README.md)

Des **pratiques** d'ingénierie de fiabilité (et non des outils) : prépare aux rôles de SRE, Platform Engineer ou DevOps senior. *Ce module se vit plus qu'il ne s'apprend.*

**Prérequis** : Modules 01 à 10, surtout le module 10 (observabilité).

**Cours** :

1. [Introduction au SRE (Site Reliability Engineering)](11-sre-pratiques/cours/01-introduction-sre.md)
2. [SLI, SLO et budget d'erreur](11-sre-pratiques/cours/02-slo-sli-error-budget.md)
3. [Gestion d'incident et astreinte (on-call)](11-sre-pratiques/cours/03-gestion-incident-et-oncall.md)
4. [Postmortem blameless](11-sre-pratiques/cours/04-postmortem-blameless.md)
5. [Runbooks, toil et automatisation](11-sre-pratiques/cours/05-runbooks-et-automatisation.md)
6. [Chaos engineering](11-sre-pratiques/cours/06-chaos-engineering.md)
7. [Patterns de fiabilité](11-sre-pratiques/cours/07-patterns-fiabilite.md)

**Ateliers Killercoda** (déclarés dans `structure.json`) :

- [SRE : définir un SLO et calculer le budget d'erreur](11-sre-pratiques/ateliers-killercoda/atelier-01-definir-slo-et-error-budget/)
- [SRE : rédiger un postmortem blameless](11-sre-pratiques/ateliers-killercoda/atelier-02-postmortem-blameless/)
- [SRE : chaos engineering basique sur Kubernetes](11-sre-pratiques/ateliers-killercoda/atelier-03-chaos-engineering-basique/)

**Compétences acquises** :

- Définir des SLI/SLO, calculer le budget d'erreur et écrire une politique de release
- Organiser la réponse à un incident et une astreinte soutenable
- Rédiger un postmortem blameless qui produit des actions suivies
- Écrire des runbooks, mesurer et réduire le toil
- Mener une expérience de chaos et concevoir pour la panne (timeouts, retries, circuit breakers)

## 🧪 Ateliers Killercoda

**[Killercoda](https://killercoda.com/)** ouvre dans le navigateur un vrai serveur Linux ou un vrai cluster Kubernetes, prêt en quelques secondes. Chaque étape de nos scénarios est **vérifiée automatiquement** (bouton *Vérifier*).

- **Publier et lancer les scénarios** : procédure d'import (lien du dépôt au profil, mises à jour, tests) dans [**KILLERCODA.md**](KILLERCODA.md) ; liste des scénarios déclarés dans [`structure.json`](structure.json).
- **Backends utilisés** : `ubuntu` (machine Ubuntu avec Docker préinstallé) et `kubernetes-kubeadm-1node` (cluster Kubernetes à un nœud, `kubectl` prêt).
- **Modules couverts et déclarés** : 08 (Docker), 09 (Kubernetes), 10 (Monitoring) et 11 (SRE) — **13 scénarios** déclarés dans `structure.json`.
- **Modules Linux (01 à 04)** : **8 scénarios Killercoda** existent (dossiers `*/ateliers-killercoda/`) mais ne sont **pas encore déclarés** dans `structure.json` : tant qu'ils n'y figurent pas, Killercoda les ignore. Les ajouter est une décision à prendre (voir [KILLERCODA.md, section 5](KILLERCODA.md#5-et-les-scénarios-linux-01-à-04-)). En attendant, leurs ateliers guidés se pratiquent sur votre VM.

> ⚠️ **Attention** : la détection par Killercoda de scénarios rangés sous `<module>/ateliers-killercoda/` n'a pas encore été confirmée sur la plateforme ; une variante de secours (groupes) et une option « dépôts séparés » sont documentées dans [KILLERCODA.md](KILLERCODA.md).

## 🛠️ Environnement de travail

Tout le cursus Linux se pratique sur une **VM Ubuntu 24.04 LTS** que vous installez au [module 00](00-installation-ubuntu-vm/README.md).

| Élément | Minimum | Recommandé |
|---|---|---|
| RAM de la machine hôte | 8 Go | 16 Go |
| Espace disque libre | 60 Go | 100 Go (SSD) |
| Processeur | 4 cœurs, virtualisation (VT-x / AMD-V) activée | 8 cœurs |
| Virtualisation | VirtualBox 7.x **ou** VMware Workstation/Fusion | — |
| Connexion Internet | Oui | — |

- **Installer** : guides [VMware](00-installation-ubuntu-vm/guide-installation-vmware.md) ou [VirtualBox](00-installation-ubuntu-vm/guide-installation-virtualbox.md), puis la [checklist post-installation](00-installation-ubuntu-vm/checklist-post-installation.md).
- **Se connecter** : en **SSH** depuis votre machine hôte (`ssh utilisateur@adresse`, ou `ssh -p 2222 utilisateur@127.0.0.1` avec la redirection de port VirtualBox) plutôt que depuis la fenêtre de la VM. Procédure détaillée dans [`SERVEUR.md`](01-linux-fondamentaux/SERVEUR.md).
- **Snapshots** : un snapshot `00-installation-propre`, puis un snapshot avant chaque jour ou atelier (`jour-XX-avant`). Pour revenir en arrière, restaurez-le.
- **Killercoda en complément** : pour s'échauffer ou réviser sans VM, ou quand une machine plus puissante est nécessaire (Kubernetes, pile de monitoring). Les modules 08 à 11 s'appuient sur Killercoda ; sur votre VM, les mêmes commandes fonctionnent (Docker installé : [module 05](05-devops-outils/cours/02-docker-fondamentaux.md)).
- **Ressources matérielles** : la pile de monitoring (module 10) et Kubernetes demandent plus de mémoire : arrêtez les conteneurs d'un atelier avant de lancer le suivant.

## 📚 Ressources transverses

| Ressource | Contenu |
|---|---|
| [`ressources/cheatsheets/commandes-linux.md`](ressources/cheatsheets/commandes-linux.md) | Aide-mémoire des commandes Linux |
| [`ressources/cheatsheets/vim.md`](ressources/cheatsheets/vim.md) | Aide-mémoire Vim |
| [`ressources/cheatsheets/bash-scripting.md`](ressources/cheatsheets/bash-scripting.md) | Aide-mémoire scripting Bash |
| [`ressources/liens-utiles.md`](ressources/liens-utiles.md) | Documentation officielle, man pages, ressources DevOps |
| [`KILLERCODA.md`](KILLERCODA.md) | Publier et tester les scénarios Killercoda (options A et B) |
| [`structure.json`](structure.json) | Déclaration des scénarios Killercoda (monorepo) |
| [`RESTRUCTURATION-LUC.md`](RESTRUCTURATION-LUC.md) | Cursus Linux orienté *Linux Upskill Challenge* (14 jours, défis, checklists) |
| [`scripts/check-killercoda.py`](scripts/check-killercoda.py) · [`scripts/export-killercoda-repos.sh`](scripts/export-killercoda-repos.sh) | Contrôle local des scénarios · export en dépôts séparés |

## 🤝 Contribution

Les contributions (corrections, clarifications, nouveaux exercices) sont les bienvenues :

1. Ouvrez une *issue* pour décrire le problème ou la proposition.
2. Créez une branche : `git switch -c correction/mon-sujet`.
3. Respectez le style : français, ton pédagogique, blocs de code avec langage, encadrés `💡 / ⚠️ / 📌`, titres de cours et d'ateliers cohérents avec le catalogue.
4. Testez les commandes sur **Ubuntu 24.04 LTS** (et sur Killercoda pour les scénarios : `python3 scripts/check-killercoda.py` avant de pousser).
5. Ouvrez une *pull request* avec une description claire (Conventional Commits recommandés : `feat:`, `fix:`, `docs:`).

## 📜 Licence

Le contenu pédagogique est publié sous licence **[CC BY-SA 4.0](LICENSE)** : vous pouvez le partager et l'adapter, à condition de citer Worketyamo et de conserver la même licence. Les extraits de code sont fournis à titre pédagogique, « tels quels », sans garantie.

## 📈 Chiffres clés

| | |
|---|---|
| Modules | **12** (00 à 11) |
| Cours | **55** |
| Ateliers guidés (fichiers `ateliers/`) | **25** |
| Exercices interactifs animés (module 07) | **4** |
| Scénarios Killercoda | **21** (13 déclarés dans `structure.json`, 8 à déclarer) |
| Lignes de contenu (approximatif) | **≈ 31 500** |

