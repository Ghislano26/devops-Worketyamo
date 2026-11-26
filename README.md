# 🐧 DevOps Worketyamo — Du débutant à l'expert sur la console Linux

Bienvenue dans le support du cours **DevOps** dispensé en ligne par **Worketyamo**.

Ce dépôt est un **cursus complet et progressif** : vous partez de zéro (installer
Ubuntu dans une machine virtuelle) et vous terminez en maîtrisant la console Linux,
les mécanismes internes du noyau (namespaces, cgroups), puis en ouvrant la porte
aux outils DevOps (Git, Docker, CI/CD).

## 🎯 Objectif pédagogique

À la fin du parcours, vous serez capable de :

- installer et configurer un serveur **Ubuntu 24.04 LTS** dans une VM ;
- naviguer, administrer et diagnostiquer un système Linux **uniquement à la console** ;
- automatiser des tâches avec **Bash**, `awk`, `sed` et `grep` ;
- sécuriser un serveur (SSH, pare-feu, durcissement) ;
- comprendre ce qui se cache derrière un conteneur (namespaces, cgroups) ;
- utiliser Git, construire une image Docker et écrire un pipeline CI/CD simple.

> 🧗 **Cursus Linux orienté Linux Upskill Challenge** : les modules Linux (01 à 04) se suivent comme un défi quotidien de **14 jours** sur *ton* serveur Ubuntu : un jour = un cours + un atelier + un **défi du jour**, avec des ateliers Killercoda pour s'échauffer sans VM. Voir [**RESTRUCTURATION-LUC.md**](RESTRUCTURATION-LUC.md).

## 🗂️ Structure du dépôt

| Dossier | Contenu | Niveau |
|---|---|---|
| [`00-installation-ubuntu-vm/`](00-installation-ubuntu-vm/README.md) | Installation d'Ubuntu 24.04 LTS sous VMware et VirtualBox, checklist post-installation | Débutant |
| [`01-linux-fondamentaux/`](01-linux-fondamentaux/) | Introduction, système de fichiers, commandes de base, utilisateurs et permissions | Débutant |
| [`02-linux-intermediaire/`](02-linux-intermediaire/) | Processus et systemd, APT, réseau, SSH et clés | Intermédiaire |
| [`03-linux-avance/`](03-linux-avance/) | Scripting Bash, `awk`/`sed`/`grep`, LVM, durcissement | Avancé |
| [`04-linux-expert/`](04-linux-expert/) | Noyau et performance, namespaces/cgroups, journalisation centralisée | Expert |
| [`05-devops-outils/`](05-devops-outils/) | Git, Docker, CI/CD | Ouverture DevOps |
| [`06-reseaux-devops/`](06-reseaux-devops/README.md) | Cours et ateliers réseaux orientés DevOps : DNS, ports, routage, TLS, diagnostic. Diagrammes animés. | Intermédiaire à avancé |
| [`07-git-branching-interactif/`](07-git-branching-interactif/README.md) | Cours Git avancé + exercices interactifs animés (mini learngitbranching). | Intermédiaire |
| [`08-docker-approfondi/`](08-docker-approfondi/README.md) | Cours Docker approfondis (architecture, images, Dockerfile, réseau, Compose, sécurité) + ateliers Killercoda interactifs. | Intermédiaire à avancé |
| [`09-kubernetes-approfondi/`](09-kubernetes-approfondi/README.md) | Cours Kubernetes approfondis (architecture, workloads, réseau, stockage, config, scheduling, sécurité) + ateliers Killercoda interactifs. | Avancé |
| [`ressources/`](ressources/liens-utiles.md) | Cheatsheets (commandes, Vim, Bash) et liens utiles | Transverse |

Chaque module `01` à `05` contient un dossier `cours/` (théorie) et un dossier
`ateliers/` (pratique guidée).

## 💻 Prérequis

| Élément | Minimum | Recommandé |
|---|---|---|
| RAM de la machine hôte | 8 Go | 16 Go |
| Espace disque libre | 60 Go | 100 Go (SSD) |
| Processeur | 4 cœurs avec virtualisation (VT-x / AMD-V) activée dans le BIOS/UEFI | 8 cœurs |
| Logiciel de virtualisation | VirtualBox 7.x **ou** VMware Workstation/Fusion | — |
| Connexion Internet | Oui (ISO d'environ 6 Go, paquets APT) | — |

Aucune connaissance préalable de Linux n'est exigée. Une aisance générale avec
un ordinateur suffit.

## 🧭 Parcours recommandé

1. **Module 00** — Installez votre VM en suivant le guide [VMware](00-installation-ubuntu-vm/guide-installation-vmware.md)
   ou [VirtualBox](00-installation-ubuntu-vm/guide-installation-virtualbox.md), puis déroulez la
   [checklist post-installation](00-installation-ubuntu-vm/checklist-post-installation.md).
2. **Module 01** — Lisez les 4 cours dans l'ordre, puis faites les 3 ateliers.
3. **Module 02** — Même démarche : cours puis ateliers.
4. **Module 03** — Idem. C'est le module le plus dense : prenez votre temps.
5. **Module 04** — Module expert, à aborder une fois le module 03 acquis.
6. **Module 05** — Ouverture vers les outils DevOps.
7. Gardez les [cheatsheets](ressources/cheatsheets/commandes-linux.md) sous la main tout au long du parcours.

> 💡 **Conseil** : prenez un *snapshot* de la VM avant chaque atelier. En cas d'erreur, vous
> revenez en arrière en quelques secondes.

## 🧠 Philosophie pédagogique

- **Théorie avant pratique** : chaque atelier est précédé d'un cours qui explique le *pourquoi*.
- **Progression graduelle** : un atelier ne mobilise que ce qui a été vu auparavant.
- **Console-first** : l'interface graphique est un confort, la console est le métier. Tout se fait en ligne de commande.
- **Scénarios réalistes** : on joue le rôle d'un administrateur système confronté à des situations de terrain.
- **Comprendre plutôt que copier** : des questions de compréhension jalonnent les ateliers.
- **Droit à l'erreur** : la VM est faite pour être cassée, puis restaurée.

## 🤝 Contribution

Les contributions sont les bienvenues (corrections, clarifications, nouveaux exercices) :

1. Ouvrez une *issue* pour décrire le problème ou la proposition.
2. Créez une branche : `git switch -c correction/mon-sujet`.
3. Respectez le style : français, ton pédagogique, blocs de code avec langage, encadrés `💡 / ⚠️ / 📌`.
4. Testez toutes les commandes sur **Ubuntu 24.04 LTS**.
5. Ouvrez une *pull request* avec une description claire.

## 📄 Licence

Le contenu pédagogique est publié sous licence **[CC BY-SA 4.0](LICENSE)** : vous pouvez le
partager et l'adapter, à condition de citer Worketyamo et de conserver la même licence.
