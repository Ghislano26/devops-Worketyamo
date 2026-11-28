# 📘 Guide de l'environnement de formation

> Ce guide t'accompagne **de l'installation jusqu'à la fin du cursus**.
> Garde-le ouvert dans un onglet : tu y reviendras souvent.

## 📑 Table des matières

1. [Introduction et philosophie](#1-introduction-et-philosophie)
2. [Installation de l'environnement](#2-installation-de-lenvironnement)
3. [Premier contact avec la VM](#3-premier-contact-avec-la-vm)
4. [Workflow quotidien d'un étudiant](#4-workflow-quotidien-dun-étudiant)
5. [Partager des fichiers entre l'hôte et la VM](#5-partager-des-fichiers-entre-lhôte-et-la-vm)
6. [Snapshots et sauvegardes](#6-snapshots-et-sauvegardes)
7. [Gestion des ressources (RAM, CPU, disque)](#7-gestion-des-ressources)
8. [Maintenance et mises à jour](#8-maintenance-et-mises-à-jour)
9. [Remise à zéro et recréation](#9-remise-à-zéro-et-recréation)
10. [Dépannage](#10-dépannage)
11. [Migration vers une autre machine](#11-migration-vers-une-autre-machine)
12. [Cas particuliers (Apple Silicon, machines faibles)](#12-cas-particuliers)
13. [FAQ](#13-faq)
14. [Annexes (cheatsheet, glossaire, liens)](#14-annexes)

**Documents compagnons** : [📋 Cheatsheet à imprimer](environnement/CHEATSHEET.md) · [🎬 Scénarios concrets](environnement/SCENARIOS.md)

> 🧭 **Comment lire ce guide ?**
> - Tu **débutes** : lis les chapitres 1 à 4 dans l'ordre, puis le 6 (snapshots).
> - Tu as un **problème** : va directement au chapitre 10 (dépannage) ou ouvre les [scénarios](environnement/SCENARIOS.md).
> - Tu **changes de machine** : chapitre 11.
> - Tu es sur **Mac Apple Silicon** ou une **machine modeste** : chapitre 12 avant l'installation.

---

## 1. Introduction et philosophie

### 1.1 Pourquoi un environnement unique ?

Imagine une classe de 30 étudiants : certains sous Windows 11, d'autres sous macOS ou Ubuntu, avec des versions d'outils différentes. Une commande qui « marche chez moi » échoue chez le voisin, et le formateur passe sa séance à dépanner les machines au lieu d'enseigner.

La solution : **tout le monde travaille dans la même machine virtuelle (VM)**, construite à partir de la même image (*box*). Les bénéfices :

| Bénéfice | Ce que ça change pour toi |
|---|---|
| **Zéro divergence** | Mêmes versions, mêmes outils, mêmes chemins : les cours et les corrigés s'appliquent tels quels |
| **Reproductibilité** | Une VM cassée se **recrée en quelques minutes** à l'identique |
| **Sécurité** | Tes expériences (permissions, pare-feu, LVM…) ne peuvent **pas abîmer** ton ordinateur |
| **Réalisme** | Tu pratiques sur un vrai serveur Linux **Rocky Linux 9** (famille Red Hat), comme en entreprise |
| **Réversibilité** | Les **snapshots** te permettent de revenir en arrière après une erreur |

### 1.2 Deux environnements, deux rôles

| | **VM Rocky Linux 9 (locale)** | **Killercoda (en ligne)** |
|---|---|---|
| Rôle | **Référence d'administration système** : tu y apprends Linux en profondeur | **Outils et ateliers guidés** : Docker, Kubernetes, monitoring, SRE, CI/CD |
| Où ça tourne | Sur **ton ordinateur** (VirtualBox) | Dans le **navigateur**, serveur éphémère (environ 1 h) |
| Persistance | **Oui** : tes fichiers restent | **Non** : tout disparaît à la fermeture |
| Installation | **Oui** (ce guide) | Aucune (un compte gratuit) |
| Hors ligne | Oui, après installation | Non |
| Vérification automatique | Non (tu t'auto-évalues avec les checklists) | **Oui** (bouton *Vérifier*) |

> 📌 **À retenir** : la **VM** est ton **poste de travail Linux** durable ; **Killercoda** est un **laboratoire jetable** pour les technologies lourdes (clusters Kubernetes, piles de monitoring). Les deux se complètent. Le détail pour Killercoda est dans [`KILLERCODA.md`](KILLERCODA.md).

### 1.3 Ce que tu vas apprendre à faire avec ce guide

- **Installer** VirtualBox, Vagrant et la box, puis démarrer ta VM (chapitre 2).
- **Travailler** au quotidien : démarrer, te connecter, sauvegarder, éteindre (chapitres 3 et 4).
- **Échanger des fichiers** entre ton ordinateur et la VM (chapitre 5).
- **Ne jamais perdre ton travail** : snapshots, sauvegardes (chapitre 6).
- **Régler** les ressources, **entretenir** et **remettre à zéro** ta VM (chapitres 7 à 9).
- **Dépanner** seul les problèmes courants et **changer de machine** (chapitres 10 à 12).

### 1.4 Prérequis matériels

| Ressource | Minimum | Recommandé |
|---|---|---|
| **Processeur** | 64 bits avec virtualisation (Intel VT-x / AMD-V) | 4 cœurs ou plus |
| **Mémoire (RAM)** de l'ordinateur | 8 Go (VM réduite à 2 Go : voir chapitre 12) | 16 Go |
| **Disque libre** | 30 Go | 60 Go (SSD) |
| **Système hôte** | Windows 10/11, macOS (Intel), Linux | Windows 11, Ubuntu, macOS Intel |
| **Connexion Internet** | Pour l'installation (box ≈ 1,5 Go) | Ensuite facultative |
| **Droits** | Administrateur pour installer les logiciels | — |

> ⚠️ **Attention** : les **Mac à puce Apple Silicon (M1/M2/M3/M4)** ne peuvent pas faire tourner VirtualBox correctement. Lis le [chapitre 12](#12-cas-particuliers) **avant** d'installer quoi que ce soit.

### 1.5 Combien de temps ça prend ?

| Phase | Durée |
|---|---|
| **Installation initiale** (téléchargements compris) | **≈ 30 minutes** (selon ta connexion) |
| Démarrage de la VM les jours suivants | 1 à 2 minutes |
| **Configuration au quotidien** | **0 minute** : tout est déjà prêt dans la box |

L'effort est concentré au début : ensuite, tu ouvres un terminal, tu tapes deux commandes et tu travailles.

### 1.6 Vocabulaire minimal

| Terme | Signification |
|---|---|
| **Hôte** (*host*) | Ton ordinateur réel (Windows, macOS, Linux) |
| **Invité** (*guest*) ou **VM** | L'ordinateur virtuel qui tourne dans l'hôte (Rocky Linux 9) |
| **Hyperviseur** | Le logiciel qui fait tourner des VM (ici **VirtualBox**) |
| **Vagrant** | L'outil en ligne de commande qui crée et pilote la VM de façon reproductible |
| **Box** | L'image de VM prête à l'emploi (`rocky9-devops`) |
| **Vagrantfile** | Le fichier texte qui décrit la VM (box, RAM, CPU, réseau, dossiers partagés) |

Le glossaire complet est en [annexe D](#d-glossaire).

---

## 2. Installation de l'environnement

> ⏱️ **Durée : ≈ 30 minutes.** Coche chaque case au fur et à mesure : `- [x]`.
> Les commandes `PowerShell` s'exécutent sur **Windows** (clic droit → *Exécuter en tant qu'administrateur* si indiqué), les commandes `bash` sur **macOS/Linux**.

### Étape 0 — Vérifier la virtualisation matérielle

La VM a besoin que ton processeur expose sa **virtualisation** (Intel **VT-x** / AMD **AMD-V**), souvent désactivée par défaut dans le BIOS/UEFI.

**Windows** : ouvre le *Gestionnaire des tâches* (`Ctrl + Maj + Échap`) → onglet **Performance** → **UC** : la ligne **Virtualisation** doit afficher **Activé**. En PowerShell :

```powershell
systeminfo | Select-String "Hyper-V"
# Cherche : « Un hyperviseur a été détecté » (Hyper-V actif) ou « Virtualisation activée dans le microprogramme : Oui »
```

**Linux** :

```bash
grep -Ec '(vmx|svm)' /proc/cpuinfo      # > 0 : la virtualisation est disponible
lscpu | grep -i virtualization
```

**macOS Intel** : `sysctl -a | grep -c VMX` doit renvoyer un nombre > 0.

- [ ] La virtualisation est **activée**.

> ⚠️ **Si elle est désactivée** : redémarre l'ordinateur, entre dans le BIOS/UEFI (touche `F2`, `F10`, `Suppr` ou `Échap` au démarrage, selon la marque), cherche **Intel Virtualization Technology**, **VT-x**, **SVM Mode** ou **AMD-V** (souvent sous *Advanced → CPU Configuration*), mets-la sur **Enabled**, enregistre (`F10`) et redémarre.

> ⚠️ **Windows : Hyper-V, WSL2 et « Isolation du noyau »** peuvent monopoliser la virtualisation. VirtualBox 7.x sait cohabiter avec Hyper-V (en mode plus lent). En cas de message « VT-x is not available » alors que le BIOS est correct, voir le [dépannage](#10-dépannage).

### Étape 1 — Installer VirtualBox 7.x

Télécharge VirtualBox sur <https://www.virtualbox.org/wiki/Downloads> (version **7.x**) :

| Système | Paquet à télécharger | Installation |
|---|---|---|
| **Windows** | *Windows hosts* (`.exe`) | Double-clic, laisser les options par défaut. Accepte l'installation des pilotes réseau (une coupure Internet de quelques secondes est normale). |
| **macOS Intel** | *macOS / Intel hosts* (`.dmg`) | Ouvre le `.dmg`, lance le `.pkg`. À la fin : *Réglages Système → Confidentialité et sécurité → Autoriser* l'extension d'Oracle, puis redémarre. |
| **Linux (Ubuntu/Debian)** | Paquet `.deb` ou dépôt Oracle | `sudo apt install virtualbox` (ou paquet Oracle plus récent) |
| **Linux (Fedora/Rocky)** | RPM Oracle | `sudo dnf install VirtualBox-7.x` |
| **macOS Apple Silicon** | ⚠️ **Non adapté** | Voir le [chapitre 12](#12-cas-particuliers) |

Vérification :

```bash
VBoxManage --version        # doit afficher 7.x.y
```

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
```

- [ ] VirtualBox 7.x est installé et `VBoxManage --version` répond.

### Étape 2 — Installer Vagrant 2.4+

Télécharge Vagrant sur <https://developer.hashicorp.com/vagrant/downloads> (version **2.4 ou plus**).

| Système | Installation |
|---|---|
| **Windows** | Installeur `.msi` (AMD64), **redémarre** l'ordinateur à la fin (nécessaire pour le `PATH`) |
| **macOS** | `.dmg`, ou `brew install --cask vagrant` |
| **Linux** | Dépôt HashiCorp (`apt`/`dnf`) ou paquet de la distribution |

```bash
vagrant --version           # Vagrant 2.4.x ou supérieur
```

- [ ] `vagrant --version` affiche 2.4 ou plus.

### Étape 3 — Récupérer le dépôt et télécharger la box

1. **Clone le dépôt du cours** (ou télécharge-le en ZIP sur GitHub) :

```bash
git clone https://github.com/Ghislano26/devops-Worketyamo.git
cd devops-Worketyamo
```

2. **Télécharge la box** (≈ 1,5 Go) depuis la page des *Releases* (la box est **publiée par le formateur** ; le **lien exact du fichier sera communiqué à la promotion**) : <https://github.com/Ghislano26/devops-Worketyamo/releases>. Choisis la **dernière version** et télécharge le fichier **`rocky9-devops-1.0.0.box`** (le numéro de version peut être plus récent). Place-le **dans un dossier simple**, sans espaces ni accents, par exemple `C:\formation\` ou `~/formation/`.

3. **Vérifie l'intégrité** du téléchargement si la page de la release publie une empreinte (SHA-256) :

```powershell
Get-FileHash .\rocky9-devops-1.0.0.box -Algorithm SHA256
```

```bash
sha256sum rocky9-devops-1.0.0.box     # (macOS : shasum -a 256 …)
```

- [ ] Le dépôt est cloné.
- [ ] Le fichier `.box` est téléchargé (≈ 1,5 Go) et son empreinte correspond.

### Étape 4 — Ajouter la box à Vagrant

Depuis le dossier qui contient le fichier `.box` :

```bash
vagrant box add rocky9-devops rocky9-devops-1.0.0.box
vagrant box list
```

La seconde commande doit afficher `rocky9-devops (virtualbox, 1.0.0)`. L'ajout **copie** la box dans le dossier interne de Vagrant (`~/.vagrant.d/boxes`) : tu peux ensuite **garder ou supprimer** le fichier `.box` d'origine (garde-le si ta connexion est lente : il resservira pour une recréation).

- [ ] `vagrant box list` affiche `rocky9-devops`.

### Étape 5 — Démarrer la VM (`vagrant up`)

Place-toi dans le dossier qui contient le `Vagrantfile` de l'environnement :

```bash
cd environnement/vagrant        # depuis la racine du dépôt cloné
vagrant up
```

Au premier démarrage, Vagrant crée la VM dans VirtualBox, configure le réseau (NAT + réseau privé `192.168.56.10`), monte le dossier partagé et lance un *provisioning* qui **vérifie la présence des outils DevOps**. **2 à 5 minutes.** Tu dois voir à la fin :

```text
==> default: Machine booted and ready!
```

> 💡 Si tu **n'as pas d'interface graphique** qui s'ouvre : c'est normal, la VM démarre en mode **headless** (sans fenêtre). On s'y connecte en SSH (étape suivante).

- [ ] `vagrant up` s'est terminé sans erreur.
- [ ] `vagrant status` affiche `default  running (virtualbox)`.

### Étape 6 — Se connecter (`vagrant ssh`)

```bash
vagrant ssh
```

Ton invite devient `[vagrant@devops-lab ~]$` : **tu es dans la VM**. Pour en sortir : `exit` (ou `Ctrl + D`).

> ⚠️ **Windows** : utilise **PowerShell** ou **Windows Terminal** (inclus avec Windows 11). `vagrant ssh` utilise le client `ssh.exe` intégré à Windows 10/11 ; si la commande échoue, installe « Client OpenSSH » (*Paramètres → Applications → Fonctionnalités facultatives*) ou *Git for Windows* (qui fournit `ssh`).

- [ ] `vagrant ssh` ouvre un shell `[vagrant@devops-lab ~]$`.

### Étape 7 — Valider l'environnement

Dans la VM, vérifie le système puis les **9 outils DevOps** installés dans la box :

```bash
cat /etc/rocky-release          # Rocky Linux release 9.x
hostname                        # devops-lab
whoami                          # vagrant
```

```bash
for outil in kubectl helm trivy syft act shellcheck podman git yq; do
  if command -v "$outil" >/dev/null 2>&1; then
    printf '✅ %-10s %s\n' "$outil" "$(command -v "$outil")"
  else
    printf '❌ %-10s ABSENT\n' "$outil"
  fi
done
```

Les **9 lignes** doivent afficher ✅ (c'est la même liste que celle contrôlée par le `Vagrantfile` au `vagrant up`). Les **outils de base** (`vim`, `nano`, `tmux`, `jq`, `tree`, `curl`, `wget`, `rsync`, `unzip`, `tar`, `make`, `gcc`, `python3`…) sont installés aussi ; vérifie-les à part si besoin :

```bash
for outil in vim nano tmux jq tree curl wget rsync unzip tar make gcc python3; do
  command -v "$outil" >/dev/null 2>&1 && echo "✅ $outil" || echo "❌ $outil ABSENT"
done
```

Vérifie aussi les ressources et le réseau :

```bash
free -h | head -n 2     # RAM disponible (≈ 4 Go)
nproc                   # nombre de vCPU (2 par défaut)
df -h /                 # espace disque (≈ 40 Go)
ping -c 2 rockylinux.org   # accès Internet depuis la VM
ls /vagrant                # la racine du dépôt est visible (dossiers 01-…, 02-…, GUIDE-ENVIRONNEMENT.md)
```

> 📌 **À retenir** : si un outil est ❌, si `ls /vagrant` est vide ou si `ping` échoue, **ne continue pas** : passe au [dépannage](#10-dépannage), puis reviens ici. Les cours supposent un environnement conforme.

- [ ] Les 9 outils DevOps répondent ✅.
- [ ] La VM accède à Internet.

### Étape 8 — Faire le tout premier snapshot

Un snapshot est une **photo de l'état de ta VM**. Fais-le **maintenant**, quand tout est propre : il te permettra de revenir à cet état en 30 secondes.

```bash
# sur l'hôte, dans environnement/vagrant
vagrant snapshot save clean
vagrant snapshot list
```

- [ ] Le snapshot `clean` apparaît dans `vagrant snapshot list`.

🎉 **Installation terminée.** Tu sais maintenant démarrer (`vagrant up`), te connecter (`vagrant ssh`) et revenir à un état sain (`vagrant snapshot restore clean`).

### Récapitulatif de l'installation

| # | Étape | Commande de contrôle |
|---|---|---|
| 0 | Virtualisation activée | Gestionnaire des tâches → Virtualisation : **Activé** |
| 1 | VirtualBox 7.x | `VBoxManage --version` |
| 2 | Vagrant 2.4+ | `vagrant --version` |
| 3 | Box téléchargée | fichier `.box` ≈ 1,5 Go |
| 4 | Box ajoutée | `vagrant box list` |
| 5 | VM démarrée | `vagrant status` → `running` |
| 6 | Connexion | `vagrant ssh` |
| 7 | Validation | boucle des 9 outils DevOps ✅ |
| 8 | Snapshot | `vagrant snapshot list` → `clean` |

---

## 3. Premier contact avec la VM

### 3.1 Que se passe-t-il quand tu fais `vagrant up` ?

```text
 Ton ordinateur (hôte : Windows, macOS, Linux)
 ┌──────────────────────────────────────────────────────────────┐
 │  vagrant up                                                  │
 │     │ lit le Vagrantfile (box, RAM, CPU, réseau, dossiers)    │
 │     ▼                                                        │
 │  VirtualBox (hyperviseur)                                     │
 │     │ crée la VM à partir de la box « rocky9-devops »        │
 │     ▼                                                        │
 │  ┌────────────────────────────────────────────────────┐      │
 │  │ VM « devops-lab » — Rocky Linux 9 (invité)          │      │
 │  │  • utilisateur vagrant, sudo sans mot de passe       │      │
 │  │  • SSH ouvert (redirigé vers 127.0.0.1:2222 de l'hôte)│     │
 │  │  • /vagrant = dossier du dépôt côté hôte             │      │
 │  └────────────────────────────────────────────────────┘      │
 │  vagrant ssh  ──────────────►  te connecte à la VM            │
 └──────────────────────────────────────────────────────────────┘
```

1. Vagrant lit le **Vagrantfile** du dossier courant.
2. Il demande à VirtualBox de **créer** (la première fois) puis **démarrer** la VM.
3. Il configure le **réseau NAT** (accès Internet), un **réseau privé** (`192.168.56.10`, accessible depuis l'hôte) et la **redirection de port SSH** (`2222` sur l'hôte → `22` dans la VM).
4. Il **monte le dossier partagé** (`/vagrant`).
5. Il attend que SSH réponde, puis annonce `Machine booted and ready!`.

### 3.2 Anatomie de l'environnement

| Élément | Valeur | Remarque |
|---|---|---|
| Distribution | **Rocky Linux 9** | Famille Red Hat : gestionnaire de paquets **`dnf`** |
| Nom d'hôte | `devops-lab` | Te sert à reconnaître la VM |
| Utilisateur | `vagrant` | Pas `root` |
| Répertoire personnel | `/home/vagrant` | Ton espace de travail (`~`) |
| `sudo` | **NOPASSWD** | `sudo` ne demande **pas** de mot de passe |
| Dossier partagé | `/vagrant` | **Racine du dépôt** côté hôte (`synced_folder "../.."`), pas ton dossier personnel |
| Accès SSH | `127.0.0.1:2222` | Redirection de port gérée par Vagrant |
| Réseau | NAT + réseau privé `192.168.56.10` | La VM accède à Internet (NAT) et est joignable **depuis ton ordinateur** à `192.168.56.10` ; pas depuis le reste du réseau local |

> 💡 Rocky Linux est un **clone** de RHEL (Red Hat Enterprise Linux). Les commandes sont les mêmes qu'ailleurs, mais **les paquets s'installent avec `dnf`** (au lieu d'`apt`), les services sont gérés par `systemd`, et **SELinux** est présent (en mode *permissive* dans la box du cours : il journalise sans bloquer). Les cours expliquent les équivalences quand elles comptent.

### 3.3 Les commandes de base pour naviguer

```bash
pwd                       # où suis-je ?
ls -la                    # que contient ce dossier ?
cd /vagrant               # aller dans le dossier partagé
cd ~                      # revenir à mon home (/home/vagrant)
cat fichier               # afficher un fichier
less fichier              # le lire page par page (q pour quitter)
man ls                    # le manuel d'une commande (q pour quitter)
sudo dnf install -y htop  # installer un paquet (sudo sans mot de passe)
history | tail            # mes dernières commandes
clear                     # nettoyer l'écran (ou Ctrl + L)
```

Raccourcis du terminal : `Tab` (complétion), `↑`/`↓` (historique), `Ctrl + C` (interrompre), `Ctrl + R` (chercher dans l'historique), `Ctrl + D` (quitter).

### 3.4 Dans quel environnement suis-je ?

Quand on enchaîne les terminaux, on finit par ne plus savoir où l'on est. Trois indices :

| Où ? | Invite (prompt) | `hostname` | `cat /etc/rocky-release` |
|---|---|---|---|
| **Dans la VM** | `[vagrant@devops-lab ~]$` | `devops-lab` | `Rocky Linux release 9.x` |
| Sur ton hôte | dépend (PowerShell `PS C:\>`, `moi@mac %`…) | nom de ton PC | commande inconnue ou autre distribution |

```bash
hostname && cat /etc/rocky-release && whoami
# devops-lab
# Rocky Linux release 9.x (Blue Onyx)
# vagrant
```

> 💡 Dans le doute : tape `hostname`. Si tu lis `devops-lab`, **tu es dans la VM**.

### 3.5 ⚠️ Règle d'or : toujours travailler dans la VM

> **Toutes les commandes des cours s'exécutent dans la VM** (`vagrant ssh`), **jamais sur ton ordinateur hôte.**

Pourquoi ? Les commandes de cours (`chmod`, `useradd`, `mount`, `iptables`, `dnf remove`…) modifient le système. Dans la VM, **le pire qui puisse arriver** est de restaurer un snapshot. Sur ton hôte, tu pourrais **endommager ton vrai système**.

| ✅ Sur l'hôte (autorisé) | ❌ Sur l'hôte (interdit) |
|---|---|
| `vagrant up`, `vagrant ssh`, `vagrant halt`… | Les commandes des ateliers |
| `git clone`, `git pull` du dépôt du cours | `sudo` quoi que ce soit des cours |
| Éditer des fichiers avec ton éditeur préféré | Créer des utilisateurs, formater des disques, modifier le pare-feu |

### 3.6 Vérifier quelque chose sur ton hôte sans casser la VM

Il t'arrivera de vouloir consulter une page web, un PDF, ou tester une commande sur ton ordinateur. **Ouvre un second terminal** (une fenêtre ou un onglet séparé) :

- **Terminal n°1** : la VM (`vagrant ssh`) — ses invites commencent par `[vagrant@devops-lab …]`.
- **Terminal n°2** : ton hôte — ton invite habituelle.

> 💡 Colle une étiquette mentale (ou change la couleur de fond du terminal) : « **fenêtre sombre = VM**, **fenêtre claire = hôte** ». Beaucoup d'erreurs viennent d'une commande tapée dans la mauvaise fenêtre.

---
## 4. Workflow quotidien d'un étudiant

### 4.1 Une session de travail type

| # | Action | Où ? | Commande |
|---|---|---|---|
| 1 | Ouvrir un terminal | Hôte | PowerShell / Windows Terminal / Terminal |
| 2 | Aller dans le dossier de l'environnement | Hôte | `cd devops-Worketyamo/environnement/vagrant` |
| 3 | Démarrer (ou vérifier) la VM | Hôte | `vagrant up` (ou `vagrant status`) |
| 4 | Se connecter | Hôte | `vagrant ssh` |
| 5 | Travailler sur l'atelier du jour | **VM** | dans `~/ateliers/` ou `/tmp/` |
| 6 | Sauvegarder son travail | **VM** | voir [chapitre 5](#5-partager-des-fichiers-entre-lhôte-et-la-vm) |
| 7 | Quitter la VM | **VM** | `exit` |
| 8 | Éteindre ou mettre en pause | Hôte | `vagrant halt` ou `vagrant suspend` |

### 4.2 Exemple concret : « Je commence l'atelier 03 du module 01 »

**Sur ton hôte** (PowerShell) :

```powershell
cd C:\formation\devops-Worketyamo\environnement\vagrant
git -C ..\.. pull                    # récupère les dernières corrections du cours
vagrant up                           # démarre la VM (1 à 2 minutes)
vagrant snapshot save avant-m01-a03  # filet de sécurité avant l'atelier
vagrant ssh                          # entre dans la VM
```

**Dans la VM** :

```bash
mkdir -p ~/ateliers/m01-a03 && cd ~/ateliers/m01-a03     # un dossier par atelier
less /vagrant/01-linux-fondamentaux/ateliers/atelier-03-permissions.md   # lire l'énoncé
# ... réaliser les exercices ...
cp -r ~/ateliers/m01-a03 /vagrant/mes-travaux/           # copie de sécurité côté hôte
exit
```

**De retour sur l'hôte** :

```powershell
vagrant halt                          # extinction propre
```

> 💡 **Conseil** : donne à tes dossiers un nom qui indique le module et l'atelier (`m01-a03`, `m03-a05`). Dans un mois, tu retrouveras ton travail en dix secondes.

### 4.3 Reprendre le lendemain

```powershell
cd C:\formation\devops-Worketyamo\environnement\vagrant
vagrant up                            # si la VM était éteinte (halt)
vagrant resume                        # si elle était suspendue (suspend)
vagrant ssh
```

`vagrant up` est **idempotent** : lancé sur une VM déjà démarrée, il ne fait rien de dangereux. En cas de doute, commence par `vagrant status`.

### 4.4 `halt`, `suspend` ou laisser tourner ?

| Situation | Commande | Reprise | RAM de l'hôte | Remarque |
|---|---|---|---|---|
| Pause courte (déjeuner, réunion) | *rien* : laisse tourner | immédiate | **utilisée** | Simple, mais consomme de la RAM |
| Pause de quelques heures, reprise **rapide** | `vagrant suspend` | `vagrant resume` (5-10 s) | **libérée** (écrite sur disque) | Garde l'état exact des processus |
| Fin de journée | `vagrant halt` | `vagrant up` (1-2 min) | libérée | **Recommandé** : extinction propre du système |
| Avant de mettre l'ordinateur en veille prolongée | `vagrant halt` | `vagrant up` | libérée | Évite les horloges et réseaux déphasés |
| Libérer de l'espace disque | `vagrant destroy` | `vagrant up` (recréation) | libérée | ⚠️ **Perte des données** de la VM |

> ⚠️ **Attention** : **ne ferme jamais brutalement** la fenêtre de VirtualBox ni n'éteins l'ordinateur VM en marche : tu risques de corrompre le système de fichiers. Utilise toujours `vagrant halt` (ou `sudo poweroff` dans la VM).

---

## 5. Partager des fichiers entre l'hôte et la VM

Tu auras besoin d'échanger des fichiers : récupérer un énoncé, sauvegarder un script, envoyer un compte rendu. Quatre méthodes, de la plus simple à la plus spécialisée.

| Méthode | Idéale pour | Sens | Difficulté |
|---|---|---|---|
| 1. Dossier synchronisé (`/vagrant`) | Échanges fréquents, sauvegarde de ton travail | Hôte ⇄ VM | ⭐ |
| 2. `vagrant upload` / `scp` | Un fichier ponctuel | Hôte → VM (ou inverse) | ⭐⭐ |
| 3. Copier-coller dans le terminal | Un petit script ou quelques lignes | Hôte → VM | ⭐ |
| 4. Git | Ce qui est versionné, travail d'équipe | Dépôt ⇄ VM | ⭐⭐ |

### 5.1 Méthode 1 : le dossier synchronisé `/vagrant`

Par défaut, Vagrant **partage le dossier du projet** (la **racine du dépôt** du cours : `synced_folder "../.."` depuis `environnement/vagrant/`) avec la VM, monté sur **`/vagrant`**.

```bash
# Dans la VM
ls /vagrant                       # tu vois les fichiers de ton dépôt, côté hôte
cp ~/ateliers/m01-a03/rapport.txt /vagrant/mes-travaux/    # VM → hôte
cp /vagrant/modele/script.sh ~/ateliers/                   # hôte → VM
```

Un fichier copié dans `/vagrant/mes-travaux/` **apparaît immédiatement** dans le dossier correspondant sur ton ordinateur (et inversement).

**Limites à connaître**

| Limite | Explication |
|---|---|
| **Permissions** | Le système de fichiers partagé n'applique pas toujours `chmod`/`chown` (surtout depuis Windows) : un script peut apparaître avec les droits `rwxrwxrwx` ou ne pas pouvoir être rendu exécutable. Copie-le dans `~` pour les ateliers sur les permissions. |
| **Performances** | Plus lent que le disque de la VM : n'y mets pas de gros volumes de petits fichiers (bases de données, `node_modules`, caches). |
| **Liens symboliques, noms** | Les liens symboliques et la casse des noms de fichiers se comportent différemment sous Windows/macOS. |
| **Sauvegarde** | Le dossier partagé survit à `vagrant destroy` (il est sur ton hôte) : c'est **la bonne destination** pour tes sauvegardes. |

> ⚠️ **Attention** : pour tout atelier qui manipule des **permissions, propriétaires, ACL ou SELinux**, travaille **dans `~`** (disque de la VM), **pas dans `/vagrant`**. Sinon les résultats seront faux.

### 5.2 Méthode 2 : `vagrant upload` et `scp`

**Le plus simple : `vagrant upload`** (depuis l'hôte, dans le dossier du `Vagrantfile`) :

```bash
vagrant upload mon-script.sh /home/vagrant/ateliers/mon-script.sh
vagrant upload ./dossier-local /home/vagrant/ateliers/dossier-distant
```

**Avec `scp`** (utile pour **récupérer** un fichier de la VM) :

```bash
vagrant ssh-config                      # affiche HostName, Port, User, IdentityFile
```

```text
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  IdentityFile /…/.vagrant/machines/default/virtualbox/private_key
```

```bash
# hôte → VM
scp -P 2222 -i .vagrant/machines/default/virtualbox/private_key \
    -o StrictHostKeyChecking=no  mon-fichier.txt  vagrant@127.0.0.1:/home/vagrant/
# VM → hôte
scp -P 2222 -i .vagrant/machines/default/virtualbox/private_key \
    -o StrictHostKeyChecking=no  vagrant@127.0.0.1:/home/vagrant/ateliers/rapport.txt  .
```

> 💡 Le **port** (`2222` ici) peut être différent si 2222 était déjà occupé : lis-le dans `vagrant ssh-config`. Sous **Windows**, `scp.exe` est fourni avec OpenSSH ; les chemins s'écrivent `C:\…` (entre guillemets s'ils contiennent des espaces).

### 5.3 Méthode 3 : coller directement dans le terminal

Pour un petit script, le plus rapide est de le **coller** via un « here-document » dans la VM :

```bash
cat > ~/ateliers/bonjour.sh <<'EOF'
#!/usr/bin/env bash
echo "Bonjour depuis la VM"
EOF
chmod +x ~/ateliers/bonjour.sh && ~/ateliers/bonjour.sh
```

- Copie le bloc depuis le cours, **colle-le** dans le terminal (clic droit ou `Ctrl + Maj + V`), appuie sur `Entrée`.
- Les guillemets `<<'EOF'` empêchent la VM d'interpréter `$` et les backticks pendant le collage.

> ⚠️ **Attention** : évite de coller des blocs de plus de 50 lignes (risque d'erreur de collage) ; pour du long, préfère `/vagrant` ou `vagrant upload`. Si le collage insère des caractères bizarres (`^M`), le fichier a des fins de ligne Windows : `sed -i 's/\r$//' fichier`.

### 5.4 Méthode 4 : Git

Pour tout ce qui est **versionné** (tes scripts, tes notes), Git est la meilleure sauvegarde :

```bash
# Dans la VM
cd ~/ateliers && git init
git add . && git commit -m "Atelier 03 module 01"
git remote add origin git@github.com:TON-COMPTE/mes-ateliers.git
git push -u origin main
```

Sur une nouvelle machine, un simple `git clone` restaure tout (voir [migration](#11-migration-vers-une-autre-machine)). Pour l'authentification : jeton d'accès personnel GitHub (HTTPS) ou clé SSH **générée dans la VM**. Ne mets **jamais** ta clé privée dans un dépôt.

### 5.5 Cas d'usage : « Je dois créer un script bash pour l'atelier 05, comment le faire depuis Windows ? »

Trois chemins possibles, du plus rapide au plus confortable :

1. **Dans la VM, avec `nano` ou `vim`** : `nano ~/ateliers/m03-a05/script.sh`. Aucun transfert, aucune différence de fins de ligne. **Recommandé pour commencer.**
2. **Avec ton éditeur Windows (VS Code…)** : édite `C:\formation\devops-Worketyamo\mes-travaux\script.sh` (visible dans la VM sous `/vagrant/mes-travaux/script.sh`), puis dans la VM : `cp /vagrant/mes-travaux/script.sh ~/ateliers/ && chmod +x ~/ateliers/script.sh`. Configure ton éditeur en **fins de ligne LF** (pas CRLF) pour les scripts : sinon `bash: ./script.sh: /bin/bash^M: bad interpreter`.
3. **Éditeur Windows connecté à la VM** : l'extension **Remote - SSH** de VS Code (hôte `127.0.0.1`, port et clé de `vagrant ssh-config`) ouvre directement les fichiers de la VM.

### 5.6 ⚠️ Ne JAMAIS éditer le même fichier des deux côtés

Si tu modifies **le même fichier** à la fois dans la VM et sur l'hôte (via `/vagrant`), tu auras des conflits ou des écrasements silencieux. Règle simple :

> **Un fichier = un seul endroit où on l'édite.** Décide au départ « ce fichier vit dans la VM » ou « ce fichier vit sur l'hôte », et ne le modifie qu'à cet endroit.

---

## 6. Snapshots et sauvegardes

Un **snapshot** est une **photo** de l'état complet de la VM (disque, et éventuellement mémoire) que l'on peut **restaurer** en quelques secondes. C'est ton **bouton « annuler »** pour toute la VM. Prends-en **souvent**.

> 📌 **À retenir** : un snapshot protège contre **tes erreurs** (une mauvaise commande), pas contre la **perte du disque** de ton ordinateur. Pour ça, il faut aussi une **sauvegarde de ton travail** (Git, copie hors de la machine).

### 6.1 Snapshots Vagrant (rapides, en ligne de commande)

Depuis l'hôte, dans le dossier du `Vagrantfile` :

```bash
vagrant snapshot save avant-lvm       # créer un snapshot nommé « avant-lvm »
vagrant snapshot list                 # lister les snapshots
vagrant snapshot restore avant-lvm    # RESTAURER (l'état actuel est perdu)
vagrant snapshot delete avant-lvm     # supprimer un snapshot
vagrant snapshot push                 # pile (empiler un point de restauration anonyme)
vagrant snapshot pop                  # restaurer le dernier empilé ET le retirer
```

| Commande | Effet | Attention |
|---|---|---|
| `save <nom>` | Crée le snapshot (quelques secondes) | Un snapshot occupe de l'espace disque |
| `restore <nom>` | Remet la VM **dans l'état du snapshot** (la VM redémarre) | **Tout ce qui a été fait depuis est perdu** |
| `delete <nom>` | Supprime le snapshot | Libère de l'espace ; ne touche pas à l'état courant |
| `list` | Affiche les noms | — |

> ⚠️ **Attention** : **`vagrant snapshot restore` annule ton travail dans la VM** depuis le snapshot. **Copie d'abord tes fichiers importants dans `/vagrant/mes-travaux/`** (qui, lui, n'est pas affecté), puis restaure.

### 6.2 Snapshots VirtualBox (interface graphique)

Équivalent plus visuel : ouvre **VirtualBox** → sélectionne la VM `devops-lab` (nom précédé du dossier du projet) → bouton **Instantanés** (*Snapshots*) → **Prendre** (icône appareil photo) → donne un nom et une description. Pour restaurer : clic droit sur le snapshot → **Restaurer**.

```bash
VBoxManage list vms                                  # trouver le nom exact de la VM
VBoxManage snapshot "<nom-vm>" take "avant-test"     # équivalent en ligne de commande
VBoxManage snapshot "<nom-vm>" list
VBoxManage snapshot "<nom-vm>" restore "avant-test"
```

> 💡 Les snapshots Vagrant et VirtualBox sont **les mêmes** (Vagrant s'appuie sur VirtualBox) : ceux créés par `vagrant snapshot save` apparaissent dans l'interface de VirtualBox.

### 6.3 Quand faire un snapshot ?

| Moment | Pourquoi | Nom suggéré |
|---|---|---|
| **Juste après l'installation** (étape 8) | État de référence : on y revient toujours | `clean` |
| **Avant un atelier risqué** : LVM, partitions, pare-feu, durcissement, SELinux, permissions avancées | Une erreur peut rendre la VM inutilisable | `avant-lvm`, `avant-durcissement` |
| **Après un atelier réussi et important** | Tu fixes une base solide | `apres-m02` |
| **Avant `dnf update`/`dnf remove`** ou `systemctl disable` d'un service critique | Mise à jour ou suppression qui peut casser | `avant-dnf` |
| **Avant de modifier** `/etc/ssh/sshd_config`, `/etc/fstab`, `/etc/sudoers` | Une faute de frappe peut te verrouiller dehors | `avant-fstab` |
| **Avant une démonstration ou un examen blanc** | Reprise instantanée | `pre-demo` |

**Convention de nommage** : `avant-<sujet>` / `apres-<sujet>`, sans espaces ni accents. Garde **3 à 5 snapshots au maximum** : chaque snapshot consomme de l'espace et ralentit la VM quand la chaîne s'allonge.

### 6.4 Sauvegarder la VM complète

Pour **archiver** ta VM entière (migration, point de non-retour) :

**Option 1 — exporter une nouvelle box** (la plus propre) :

```bash
vagrant halt
vagrant package --output ma-vm-2025-12.box      # crée une box à partir de la VM actuelle (≈ 1,5 à 3 Go)
```

**Option 2 — copier le dossier `.vagrant/`** : situé dans le dossier du `Vagrantfile`, il contient l'**identifiant** de la VM, pas son disque. Les disques sont dans le dossier VirtualBox (**VirtualBox VMs**, `~/VirtualBox VMs/` ou `C:\Users\<toi>\VirtualBox VMs\`). Copier ces dossiers **VM éteinte** est possible mais **lourd** et fragile : préfère l'option 1.

> ⚠️ Un `.box` ou un dossier `.vagrant/` **ne se commite jamais dans Git** (ils sont dans le `.gitignore` du dépôt) : fichiers volumineux et propres à ta machine.

### 6.5 Restauration après une casse

Du moins radical au plus radical :

| Niveau | Situation | Commande | Perte |
|---|---|---|---|
| 1 | Une commande a mal tourné, la VM démarre | Corriger à la main ou annuler la commande | Aucune |
| 2 | La VM fonctionne mais est « abîmée » | `vagrant snapshot restore clean` (ou un snapshot plus récent) | Ce qui a été fait depuis le snapshot |
| 3 | La VM ne démarre plus et pas de bon snapshot | `vagrant destroy -f && vagrant up` | **Tout le contenu de la VM** |
| 4 | Même la recréation échoue | Réinstaller la box ([chapitre 10](#10-dépannage)) | Tout, sauf `/vagrant` |

```bash
# Niveau 2 : retour à l'état propre
vagrant snapshot restore clean
vagrant ssh

# Niveau 3 : recréation complète (⚠️ perte des données de la VM)
vagrant destroy -f && vagrant up
vagrant snapshot save clean          # refaire le snapshot de référence !
```

---

## 7. Gestion des ressources

Les ressources de la VM (RAM, CPU, disque) sont définies dans le **`Vagrantfile`**. Après une modification, applique-la avec `vagrant reload` (redémarrage de la VM).

```ruby
# Extrait du Vagrantfile (environnement/vagrant/Vagrantfile)
Vagrant.configure("2") do |config|
  config.vm.box = "rocky9-devops"
  config.vm.box_version = "1.0.0"
  config.vm.hostname = "devops-lab"
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.synced_folder "../..", "/vagrant", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"      # RAM en Mo
    vb.cpus   = 2           # nombre de vCPU
    vb.name   = "devops-lab"
  end
end
```

### 7.1 RAM (par défaut 4 Go)

```ruby
vb.memory = "8192"          # 8 Go
```

```bash
vagrant reload              # applique la modification (la VM redémarre)
```

| RAM de ton ordinateur | RAM conseillée pour la VM |
|---|---|
| 8 Go | **2 à 3 Go** (ferme le navigateur et les applications lourdes) |
| 16 Go | 4 à 6 Go |
| 32 Go ou plus | 8 Go |

> 💡 **Règle** : laisse **au moins la moitié de la RAM** à ton ordinateur hôte. Une VM trop gourmande fait **ralentir tout** (swap côté hôte).

### 7.2 CPU (par défaut 2 vCPU)

```ruby
vb.cpus = 4
```

Ne dépasse pas **la moitié de tes cœurs physiques** (4 cœurs → 2 vCPU ; 8 cœurs → 4 vCPU). Plus de vCPU ne rend pas toujours plus rapide, et peut même ralentir l'hôte.

### 7.3 Disque (par défaut 40 Go)

Le disque de la VM est **dynamique** : il grossit avec l'usage, jusqu'à 40 Go. L'agrandir demande :

**Option A — plugin `vagrant-disksize`** (si le provisionnement le supporte) :

```bash
vagrant plugin install vagrant-disksize
```

```ruby
config.disksize.size = "60GB"
```

Puis `vagrant reload`. Le disque virtuel est agrandi, mais **la partition et le système de fichiers** doivent être étendus dans la VM (`growpart`, `xfs_growfs /`) : voir le cours LVM du [module 03](03-linux-avance/README.md).

**Option B — recréer la VM** avec un disque plus grand (`vagrant destroy -f`, modifier, `vagrant up`) : plus simple, mais **perte des données** (sauvegarde d'abord, [chapitre 11](#11-migration-vers-une-autre-machine)).

### 7.4 Vérifier les ressources dans la VM

```bash
free -h            # mémoire : total, utilisée, disponible, swap
nproc              # nombre de vCPU
lscpu | head -n 15 # détails du processeur
df -h              # espace disque par système de fichiers
du -sh ~/* | sort -h | tail   # les plus gros dossiers de ton home
```

### 7.5 La VM est lente : que faire ?

| Cause probable | Vérification | Solution |
|---|---|---|
| **Pas assez de RAM** (swap actif) | `free -h` : `Swap` utilisé élevé | Augmenter `vb.memory`, fermer des applications sur l'hôte |
| **Virtualisation non activée** | VirtualBox indique « mode logiciel » / très lent | Activer VT-x/AMD-V dans le BIOS ([étape 0](#étape-0--vérifier-la-virtualisation-matérielle)) |
| **Hyper-V actif** (Windows) | `systeminfo` : « hyperviseur détecté » | Désactiver ou accepter la lenteur ([dépannage](#10-dépannage)) |
| **Trop de snapshots** | `vagrant snapshot list` | Supprimer les anciens |
| **Disque presque plein** | `df -h` | Libérer de l'espace, `sudo dnf clean all` |
| **Antivirus** qui scanne le dossier VirtualBox | Gestionnaire des tâches | Exclure `VirtualBox VMs` de l'analyse |
| **Travail dans `/vagrant`** (partage lent) | — | Travaille dans `~` |
| **Hôte surchargé** | Gestionnaire des tâches | Fermer le navigateur, les autres VM |

### 7.6 Surveiller l'utilisation

```bash
top                         # processus par consommation (q pour quitter)
sudo dnf install -y htop    # version plus confortable
htop                        # F6 trier, F9 tuer un processus, q quitter
vmstat 2 5                  # mémoire/CPU/E-S : 5 mesures espacées de 2 s
iostat -x 2 3               # E/S disque (paquet sysstat : sudo dnf install -y sysstat)
```

> 💡 Sur l'hôte : le **Gestionnaire des tâches** (Windows), **Moniteur d'activité** (macOS) ou `htop` (Linux) indiquent ce que consomme **VirtualBox**.

---

## 8. Maintenance et mises à jour

### 8.1 Mettre à jour les paquets dans la VM

```bash
sudo dnf check-update          # liste les mises à jour disponibles (sans rien installer)
sudo dnf update -y             # installe toutes les mises à jour
sudo dnf upgrade --security -y # seulement les mises à jour de sécurité
```

> ⚠️ **Attention** : une mise à jour peut **changer des versions d'outils** utilisées par les ateliers, redémarrer des services ou remplacer le noyau. **Prends un snapshot avant** (`vagrant snapshot save avant-dnf`), et **ne fais pas de `dnf update` de ta propre initiative** : les cours sont testés sur les versions de la box. Si un atelier le demande explicitement, fais-le.

### 8.2 Mettre à jour la box elle-même

Le formateur publie une **nouvelle version de la box** (par exemple `1.1.0`) quand l'environnement évolue : [GitHub Releases](https://github.com/Ghislano26/devops-Worketyamo/releases).

1. **Lis le changelog** (annexe F et la page de la release) pour savoir ce qui change.
2. **Sauvegarde ton travail** : copie `~/ateliers` vers `/vagrant/mes-travaux/` ([chapitre 11, option A](#11-migration-vers-une-autre-machine)).
3. **Télécharge** `rocky9-devops-1.1.0.box` et ajoute-la :

```bash
vagrant box add rocky9-devops rocky9-devops-1.1.0.box
vagrant box list            # rocky9-devops (virtualbox, 1.0.0) et (virtualbox, 1.1.0)
```

4. **Modifie le `Vagrantfile`** pour fixer la version :

```ruby
config.vm.box = "rocky9-devops"
config.vm.box_version = "1.1.0"
```

5. **Recrée la VM** (une box mise à jour s'applique à une *nouvelle* VM, pas à l'existante) :

```bash
vagrant destroy -f && vagrant up
vagrant snapshot save clean
```

6. **Restaure ton travail** depuis `/vagrant/mes-travaux/` vers `~/ateliers`.

> 📌 `vagrant box update` ne sert que pour les box publiées sur un catalogue (Vagrant Cloud) avec un champ de version : avec un fichier `.box` distribué manuellement, on **ajoute** la nouvelle version comme ci-dessus.

### 8.3 Nettoyer les anciennes box

```bash
vagrant box list                       # versions installées
vagrant box prune                      # supprime les versions obsolètes non utilisées
vagrant box remove rocky9-devops --box-version 1.0.0     # supprimer une version précise
```

Chaque box fait environ 1,5 Go : nettoie après une migration réussie.

### 8.4 Vérifier la santé de la VM

```bash
systemctl --failed             # services en échec (idéalement : 0 loaded units listed)
journalctl -p err -b --no-pager | tail -n 20   # erreurs depuis le dernier démarrage
df -h                          # espaces disque (alerte au-delà de 85 %)
free -h                        # mémoire
uptime                         # charge moyenne (load average)
sudo dmesg --level=err,warn | tail   # messages du noyau
getenforce                     # état de SELinux (Permissive attendu dans cette box)
```

### 8.5 Recommandation

> **Ne fais pas de `dnf update` sauf si un atelier le demande.** Ta VM est livrée dans un état testé : c'est ce qui garantit que les cours fonctionnent. Pour obtenir un système à jour, **mets à jour la box** (§ 8.2) plutôt que les paquets un par un.

---

## 9. Remise à zéro et recréation

### 9.1 Scénario 1 — « J'ai cassé ma VM, je veux repartir de zéro »

```bash
# 1. Sauvegarde d'abord ce que tu veux garder
vagrant ssh -c 'cp -r ~/ateliers /vagrant/mes-travaux/ 2>/dev/null; echo "sauvegarde faite"'
# 2. Détruis et recrée
vagrant destroy -f
vagrant up
vagrant snapshot save clean
```

> ⚠️ **Attention** : `vagrant destroy -f` **supprime la VM sans confirmation** (`-f` = *force*). Tout ce qui n'est pas dans `/vagrant` (donc sur ton hôte) est **perdu définitivement**. Si la VM ne démarre plus, la sauvegarde via `vagrant ssh` est impossible : essaie d'abord le [dépannage](#10-dépannage).

### 9.2 Scénario 2 — « Je veux juste retrouver l'état du dernier snapshot »

```bash
vagrant snapshot list
vagrant snapshot restore clean       # ou un autre nom
```

Plus rapide (30 secondes) et plus doux que la recréation : à préférer dès que tu as un bon snapshot.

### 9.3 Scénario 3 — « Je veux faire une pause et reprendre plus tard »

```bash
vagrant suspend       # fige la VM (état écrit sur disque)
# ... plus tard ...
vagrant resume
```

Ou `vagrant halt` / `vagrant up` si la pause dure plusieurs jours.

### 9.4 Scénario 4 — « Je change d'ordinateur »

Voir le [chapitre 11 — Migration](#11-migration-vers-une-autre-machine).

### 9.5 Quelle commande pour quel scénario ?

| Je veux… | Commande | Données de la VM | Durée |
|---|---|---|---|
| Éteindre proprement | `vagrant halt` | conservées | 20 s |
| Mettre en pause, reprise rapide | `vagrant suspend` / `resume` | conservées (état exact) | 10 s |
| Appliquer un changement du Vagrantfile | `vagrant reload` | conservées | 1-2 min |
| Revenir à un état sain | `vagrant snapshot restore <nom>` | **perdues depuis le snapshot** | 30 s |
| Rejouer le provisioning | `vagrant provision` | conservées | variable |
| Tout recréer à neuf | `vagrant destroy -f && vagrant up` | **toutes perdues** | 3-5 min |
| Libérer de l'espace disque | `vagrant destroy` | **toutes perdues** | 10 s |
| Oublier les VM fantômes | `vagrant global-status --prune` | — | — |

---
## 10. Dépannage

> 🩺 **Méthode générale** : (1) **lis** le message d'erreur en entier (la cause est souvent dans les 3 dernières lignes) ; (2) cherche-le dans le tableau ; (3) applique **une seule** correction à la fois ; (4) si tu es bloqué, relance avec `vagrant up --debug 2>&1 | tee debug.log` et joins `debug.log` à ton signalement.

### 10.1 Tableau des problèmes fréquents

| # | Symptôme | Cause probable | Solution rapide |
|---|---|---|---|
| 1 | `vagrant up` → « VT-x is not available » / « VERR_VMX_NO_VMX » | Virtualisation désactivée dans le BIOS/UEFI | Activer VT-x/AMD-V ([étape 0](#étape-0--vérifier-la-virtualisation-matérielle)) |
| 2 | `vagrant up` → « Hyper-V must be disabled » / VM très lente sous Windows | Hyper-V ou la plateforme d'hyperviseur Windows est active | Voir § 10.2 |
| 3 | `vagrant up` → « The box 'rocky9-devops' could not be found » | Box non ajoutée | `vagrant box add rocky9-devops rocky9-devops-1.0.0.box` |
| 4 | `vagrant ssh` → « Permission denied (publickey) » | Clés SSH de Vagrant désynchronisées | `vagrant reload` puis, sinon, recréer (§ 10.3) |
| 5 | VM très lente | RAM insuffisante, virtualisation absente | Augmenter `vb.memory`, [§ 7.5](#75-la-vm-est-lente--que-faire-) |
| 6 | Pas de connexion Internet dans la VM | NAT ou DNS cassé | `vagrant reload` ; `cat /etc/resolv.conf` ; § 10.4 |
| 7 | `dnf install` échoue | Dépôts désactivés, DNS, miroir indisponible | `sudo dnf clean all && sudo dnf makecache` ; `sudo dnf repolist` |
| 8 | `sudo` demande un mot de passe | Fichier sudoers modifié ou connexion en autre utilisateur | Utiliser `vagrant ssh` (compte `vagrant`, NOPASSWD) ; `whoami` |
| 9 | Disque plein (« No space left on device ») | Snapshots, journaux ou fichiers volumineux | `df -h`, `vagrant snapshot list`, § 10.5 |
| 10 | « Port 2222 is already in use » / collision de port | Une autre VM ou un autre programme | Vagrant choisit un autre port ; sinon `config.vm.network "forwarded_port", guest: 22, host: 2200, id: "ssh"` |
| 11 | `vagrant up` bloqué sur « Waiting for machine to boot » puis expire | Démarrage lent, VT-x absent, pilote réseau VirtualBox | Patienter 5 min, `vb.gui = true` pour voir la console, § 10.6 |
| 12 | « A VirtualBox machine with the name 'devops-lab' already exists » | VM fantôme d'une tentative précédente | `VBoxManage list vms`, `VBoxManage unregistervm devops-lab --delete` |
| 13 | `/vagrant` est vide ou introuvable | Dossier partagé non monté (Additions invité) | `vagrant reload` ; `mount \| grep vagrant` ; § 10.7 |
| 14 | « The VirtualBox VM was created with a user that doesn't match the current user » | VM créée sous un autre compte | Se reconnecter avec le bon compte ou `vagrant global-status --prune` |
| 15 | « Vagrant failed to initialize at a very early stage / VBoxManage not found » | VirtualBox absent du `PATH` | Redémarrer ; vérifier l'installation ; ajouter `C:\Program Files\Oracle\VirtualBox` au `PATH` |
| 16 | `vagrant` : « command not found » | Vagrant non installé ou terminal ouvert avant l'installation | Fermer/rouvrir le terminal, redémarrer ; `vagrant --version` |
| 17 | La VM démarre mais écran noir / pas de fenêtre | Mode headless normal | Se connecter avec `vagrant ssh` |
| 18 | Erreur « kernel driver not installed (rc=-1908) » | Pilotes VirtualBox non chargés | Linux : `sudo /sbin/vboxconfig` (Secure Boot : signer le module) ; macOS : autoriser l'extension |
| 19 | « Network adapter … Host-Only … not found » | Pilote réseau VirtualBox défaillant | Réinstaller VirtualBox en cochant les pilotes réseau |
| 20 | Heure de la VM décalée après une veille | Horloge non resynchronisée | `sudo chronyc makestep` ; `timedatectl` |
| 21 | « Warning: Remote connection disconnect. Retrying… » en boucle | SSH ne répond pas dans la VM | Attendre ; `vb.gui = true` ; `vagrant reload` |
| 22 | Fichier `.sh` : `bad interpreter: /bin/bash^M` | Fins de ligne Windows (CRLF) | `sed -i 's/\r$//' script.sh` |

### 10.2 Détail — Hyper-V, WSL2 et Windows

Sous Windows, **Hyper-V**, **WSL2**, **Windows Sandbox**, **Isolation du noyau (Intégrité de la mémoire)** et **Plateforme de machine virtuelle** utilisent la virtualisation et peuvent entrer en conflit avec VirtualBox. VirtualBox 7.x peut fonctionner **avec** Hyper-V actif (moteur « NEM », performances réduites), mais c'est la cause numéro un des lenteurs et des échecs de démarrage.

**Diagnostic** (PowerShell) :

```powershell
systeminfo | Select-String "hyperviseur|Hyper-V"
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All | Select-Object State
bcdedit /enum | Select-String hypervisorlaunchtype
```

**Solution (désactiver Hyper-V)** — PowerShell **en administrateur**, puis **redémarrer** :

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
bcdedit /set hypervisorlaunchtype off
```

> ⚠️ Cela **désactive aussi Docker Desktop avec WSL2** et d'autres outils s'appuyant sur Hyper-V. Pour réactiver plus tard : `bcdedit /set hypervisorlaunchtype auto` (et réactive la fonctionnalité). Si tu **dois** garder WSL2, accepte la lenteur de VirtualBox ou utilise **Killercoda** pour les ateliers lourds ([chapitre 12](#12-cas-particuliers)).

Vérifie aussi *Sécurité Windows → Sécurité de l'appareil → Isolation du noyau → Intégrité de la mémoire* : **Désactivée** peut aider.

### 10.3 Détail — `Permission denied (publickey)`

```bash
vagrant ssh-config                 # le fichier IdentityFile existe-t-il ?
vagrant reload                     # Vagrant réinsère une clé valide au redémarrage
vagrant halt && vagrant up
```

Si `vagrant reload` ne suffit pas : supprime le dossier `.vagrant/` du projet (`rm -rf .vagrant` ; PowerShell : `Remove-Item -Recurse -Force .vagrant`), puis `vagrant up` : Vagrant ne retrouve plus la VM et en recrée une (⚠️ l'ancienne reste dans VirtualBox : `VBoxManage list vms` puis suppression). En dernier recours, `vagrant destroy -f && vagrant up`.

### 10.4 Détail — Pas d'Internet dans la VM

```bash
# Dans la VM
ping -c 2 8.8.8.8            # OK : le réseau fonctionne ; sinon NAT cassé
ping -c 2 rockylinux.org     # OK : le DNS fonctionne ; sinon DNS cassé
ip -br a                     # l'interface a-t-elle une adresse (10.0.2.15 en NAT) ?
cat /etc/resolv.conf
```

| Résultat | Diagnostic | Action |
|---|---|---|
| Les deux `ping` échouent | Réseau/NAT | Sur l'hôte : `vagrant reload` ; vérifier le VPN, le pare-feu/antivirus |
| `8.8.8.8` répond, le nom ne résout pas | DNS | `echo "nameserver 1.1.1.1" \| sudo tee /etc/resolv.conf` (temporaire), vérifier le VPN |
| Tout échoue après un VPN d'entreprise | Le VPN coupe le NAT | Déconnecter le VPN le temps de l'installation |

### 10.5 Détail — Disque plein

```bash
df -h                                   # quel système de fichiers est plein ?
sudo du -xh / --max-depth=2 2>/dev/null | sort -h | tail -n 15     # qui consomme ?
sudo journalctl --vacuum-size=100M      # réduire les journaux systemd
sudo dnf clean all                      # vider le cache dnf
sudo rm -rf /var/tmp/* /tmp/*           # fichiers temporaires (avec prudence)
```

Sur l'**hôte** : `vagrant snapshot list` puis `vagrant snapshot delete <nom>` pour les anciens snapshots, et `vagrant box prune`.

### 10.6 Détail — La VM ne démarre pas

Voir aussi le [scénario 3](environnement/SCENARIOS.md#scénario-3--ma-vm-ne-démarre-plus). Ordre de diagnostic :

1. `vagrant status` : l'état est-il `running`, `poweroff`, `aborted`, `not created` ?
2. `vagrant up --debug 2>&1 | tee debug.log` : lis les dernières lignes.
3. Active la fenêtre de la VM pour **voir la console** : dans le `Vagrantfile`, `vb.gui = true`, puis `vagrant reload`.
4. Ouvre **VirtualBox** : la VM apparaît-elle ? A-t-elle un état « Aborted » ? Vois le journal : *Machine → Afficher le journal*.
5. `VBoxManage list vms` et `VBoxManage list runningvms` pour voir si une VM fantôme occupe les ressources.
6. Redémarre l'hôte (règle vite beaucoup de problèmes de pilotes).
7. Restaure un snapshot : `vagrant snapshot restore clean`.
8. Dernier recours : `vagrant destroy -f && vagrant up`.

### 10.7 Détail — Le dossier `/vagrant` est vide

```bash
mount | grep -i vagrant              # le partage est-il monté ?
ls -la /vagrant
```

Sur l'hôte : `vagrant reload`. Si `mount` ne montre rien, le module « Guest Additions » ou le type de partage (`vboxsf`) est en cause : demande de l'aide en indiquant ta version de VirtualBox et la sortie de `vagrant up`. Contournement : utilise `vagrant upload` ([§ 5.2](#52-méthode-2--vagrant-upload-et-scp)).

### 10.8 Cheatsheet de diagnostic (dans la VM)

```bash
systemctl --failed                        # services en échec
journalctl -p err -b --no-pager | tail    # erreurs depuis le démarrage
df -h && free -h && uptime                # disque, mémoire, charge
ip -br a && ip route                      # réseau
ping -c 2 8.8.8.8 && ping -c 2 rockylinux.org
getenforce                                # SELinux
sudo dmesg --level=err | tail             # erreurs du noyau
```

> 📌 **Avant de demander de l'aide**, note : ton **système hôte** (Windows 11 23H2, macOS 14 Intel…), les **versions** (`vagrant --version`, `VBoxManage --version`), le **message d'erreur complet** et **ce que tu as déjà essayé**.

---

## 11. Migration vers une autre machine

Tu changes d'ordinateur (ou tu réinstalles Windows). Il faut **retrouver ton environnement et ton travail**. Trois options, de la plus recommandée à la plus lourde.

| Option | Principe | Taille à transférer | Quand ? |
|---|---|---|---|
| **A** | Sauvegarder **seulement tes fichiers** | quelques Mo | **Toujours** (en plus de C) |
| **B** | **Exporter la VM** complète en `.box` | 1,5 à 3 Go | Tu as personnalisé la VM en profondeur |
| **C** | **Repartir de zéro** sur la nouvelle machine | rien (re-téléchargement de la box) | **Recommandé** |

### 11.1 Option A — sauvegarder ses fichiers de travail

**À sauvegarder** : `~/ateliers/`, `~/notes/`, scripts, fichiers de configuration que *tu* as écrits. **À ne pas sauvegarder** : fichiers système, paquets installés, configuration générale : **Vagrant et la box les recréent**.

```bash
# Dans la VM
tar czf ~/backup-travail-$(date +%F).tar.gz -C ~ ateliers notes
ls -lh ~/backup-travail-*.tar.gz
cp ~/backup-travail-*.tar.gz /vagrant/mes-travaux/       # visible côté hôte
```

Ou, depuis l'hôte, sans copier dans `/vagrant` :

```bash
vagrant ssh -c 'tar czf - -C ~ ateliers notes' > backup-travail.tar.gz    # bash/zsh
```

**Copie ensuite `backup-travail-….tar.gz` hors de la machine** : clé USB, disque externe, cloud (Drive, OneDrive), ou Git. **Vérifie l'archive** :

```bash
tar tzf backup-travail-2025-12-01.tar.gz | head
```

### 11.2 Option B — export complet de la VM

```bash
vagrant halt
vagrant package --output ma-vm.box          # dans le dossier du Vagrantfile
ls -lh ma-vm.box                            # ≈ 1,5 à 3 Go
```

Transfère `ma-vm.box` (disque externe, réseau local), puis sur la nouvelle machine :

```bash
vagrant box add ma-vm ma-vm.box
# dans le Vagrantfile : config.vm.box = "ma-vm"
vagrant up
```

> ⚠️ `vagrant package` **ne conserve pas** les snapshots ni, selon la configuration, les dossiers partagés ; l'export est un **état figé** de ta VM. À réserver aux besoins précis.

### 11.3 Option C — repartir de zéro (recommandée)

1. **Installe** VirtualBox 7.x et Vagrant 2.4+ ([chapitre 2](#2-installation-de-lenvironnement), étapes 0 à 2).
2. **Clone** le dépôt : `git clone https://github.com/Ghislano26/devops-Worketyamo.git`.
3. **Télécharge** la box depuis [GitHub Releases](https://github.com/Ghislano26/devops-Worketyamo/releases) et ajoute-la (`vagrant box add …`).
4. **Démarre** : `vagrant up`, `vagrant snapshot save clean`.
5. **Restaure** ton travail :

```bash
# Copie l'archive dans /vagrant/mes-travaux/ (côté hôte) puis, dans la VM :
tar xzf /vagrant/mes-travaux/backup-travail-2025-12-01.tar.gz -C ~
ls ~/ateliers ~/notes
```

ou `git clone` de ton dépôt de travaux ([§ 5.4](#54-méthode-4--git)).

### 11.4 Checklist « avant de changer de machine »

- [ ] J'ai **copié mes fichiers** de la VM (`~/ateliers`, `~/notes`…) vers l'hôte.
- [ ] J'ai créé une **archive** `backup-travail-….tar.gz` et **vérifié** son contenu.
- [ ] J'ai copié l'archive **hors de l'ordinateur** (clé USB, cloud, Git).
- [ ] J'ai poussé mes dépôts Git (`git status` propre, `git push`).
- [ ] J'ai noté la **version de la box** utilisée (`vagrant box list`) et mes **modifications du Vagrantfile** (RAM, CPU).
- [ ] J'ai sauvegardé mes **clés SSH** personnelles si je les ai générées dans la VM (`~/.ssh/`), dans un endroit **chiffré**.
- [ ] J'ai le fichier `.box` (ou le lien de téléchargement) pour la nouvelle machine.
- [ ] Sur la nouvelle machine : virtualisation activée **avant** d'installer VirtualBox.

---

## 12. Cas particuliers

### 12.1 Apple Silicon (Mac M1 / M2 / M3 / M4)

**Le problème** : les Mac à puce Apple Silicon ont une architecture **ARM64** ; la box `rocky9-devops` est conçue pour **x86_64 (amd64)**, et **VirtualBox n'est pas utilisable de façon fiable** sur ces Mac (la version « développeur » ARM ne propose pas de VM Linux x86 courante). Tu as trois solutions.

| Solution | Principe | Coût | Remarques |
|---|---|---|---|
| **1. UTM + Rocky Linux ARM64** | UTM (<https://mac.getutm.app>) virtualise via Apple Virtualization/QEMU ; tu installes **Rocky Linux 9 aarch64** depuis l'ISO officielle | **Gratuit** | Environnement **équivalent** (même famille, mêmes commandes) ; installation manuelle (≈ 30-45 min) |
| **2. Vagrant + provider `vmware_desktop`** | VMware Fusion (gratuit pour usage personnel) + plugin Vagrant | Variable | Nécessite une box ARM64 compatible VMware (à demander au formateur) |
| **3. Tout sur Killercoda** | Les ateliers se font dans le navigateur | Gratuit | Tu **perds la VM locale** (pas de persistance) : réservé aux Mac sans autre option |

**Procédure UTM (solution 1)**

1. Installe UTM (`brew install --cask utm`).
2. Télécharge l'ISO **Rocky Linux 9 — aarch64 (minimal ou boot)** sur <https://rockylinux.org/download>.
3. Crée une VM : *Virtualiser* → *Linux* → 4 Go de RAM, 2 cœurs, 40 Go.
4. Installe Rocky ; crée l'utilisateur `vagrant`, donne-lui `sudo` sans mot de passe pour reproduire l'environnement :

```bash
sudo useradd -m -G wheel vagrant && sudo passwd vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
sudo hostnamectl set-hostname devops-lab
```

5. Installe les outils : `sudo dnf install -y git curl wget vim nano tmux jq tree rsync unzip tar python3`.
6. Installe les outils DevOps (`kubectl`, `helm`, `trivy`, `syft`, `act`, `shellcheck`, `yq`, `podman`) en version **arm64** — les versions de référence sont dans [`environnement/README.md`](environnement/README.md) — puis valide avec la boucle des 9 outils ([étape 7](#étape-7--valider-lenvironnement)) et prends un snapshot UTM.

**Limites** : certaines **images Docker** ne sont disponibles qu'en `amd64` (une erreur `exec format error` ou « no matching manifest for linux/arm64 » apparaît). Utilise des images multi-architecture ou `--platform linux/amd64` (émulation lente). Les dossiers partagés Vagrant n'existent pas : utilise `scp` ou Git ([chapitre 5](#5-partager-des-fichiers-entre-lhôte-et-la-vm)).

### 12.2 Machines faibles (4 Go de RAM)

| Mesure | Détail |
|---|---|
| **Réduire la RAM de la VM** | `vb.memory = "2048"` (2 Go), puis `vagrant reload`. Suffisant pour les modules Linux 01 à 03. |
| **Un seul vCPU si besoin** | `vb.cpus = 1` |
| **Fermer les applications lourdes** | Navigateur avec beaucoup d'onglets, Teams, Discord, IDE : ferme-les pendant l'atelier. |
| **Éviter le swap côté hôte** | Surveille le Gestionnaire des tâches ; si la mémoire dépasse 90 %, réduis encore. |
| **Désactiver l'interface graphique de la VM** | `vb.gui = false` (déjà le cas). |
| **Alternative** | **Killercoda uniquement** pour les modules lourds (Docker, Kubernetes, monitoring) ; la VM locale pour le Linux de base. |

> 💡 Même avec 4 Go de RAM sur l'hôte, une VM à 2 Go fonctionne pour **les modules 01 à 03** ; le **module 04** (performance, cgroups) et les **piles de monitoring** nécessitent plus : utilise Killercoda pour ceux-là.

### 12.3 Windows avec WSL2

**WSL2** utilise l'hyperviseur Windows (Hyper-V), qui entre en **conflit** avec la virtualisation matérielle directe de VirtualBox : sans précaution, tu obtiens des erreurs « VT-x is not available » ou une VM très lente.

| Option | Détail |
|---|---|
| **Cohabitation** | **VirtualBox 7.x** sait fonctionner avec Hyper-V actif (performances réduites). Garde WSL2, accepte la lenteur. |
| **Désactiver Hyper-V** | Meilleures performances pour VirtualBox, mais **WSL2 et Docker Desktop (WSL2)** cessent de fonctionner ([§ 10.2](#102-détail--hyper-v-wsl2-et-windows)). Basculer entre les deux demande un redémarrage. |
| **Utiliser WSL2 à la place** | Tu peux faire une partie des ateliers Linux dans une distribution WSL2 (Rocky via `wsl --import`), mais certains ateliers (systemd, noyau, cgroups, LVM) y sont **limités** : la VM reste la référence. |

> ⚠️ N'utilise **pas** WSL2 comme substitut complet : le cursus suppose une vraie VM avec `systemd` complet, ses propres disques et son réseau.

### 12.4 Linux sans interface graphique (serveur) ou avec KVM

- **VirtualBox headless** : Vagrant démarre la VM **sans fenêtre** par défaut ; tout se pilote par `vagrant ssh`. `VBoxManage` gère les VM en ligne de commande (`VBoxManage list vms`, `VBoxManage controlvm devops-lab poweroff`).
- **Alternative libvirt/KVM** (plus natif sous Linux, sans VirtualBox) :

```bash
sudo dnf install -y qemu-kvm libvirt        # (Debian/Ubuntu : apt install qemu-kvm libvirt-daemon-system)
vagrant plugin install vagrant-libvirt
vagrant up --provider=libvirt
```

Il faut alors une **box compatible libvirt** (format `libvirt`, pas `virtualbox`) : demande-la ou convertis la box (`vagrant mutate`). Vérifie aussi que ton utilisateur est dans les groupes `libvirt` et `kvm`.

- **Secure Boot** (Linux) : VirtualBox charge des modules noyau ; avec Secure Boot actif, il faut **signer** les modules ou désactiver Secure Boot, sinon l'erreur `rc=-1908` apparaît.

---

## 13. FAQ

### Installation et matériel

**Dois-je installer la VM sur mon ordinateur personnel ou professionnel ?**
Idéalement sur ton **ordinateur personnel**, où tu as les droits d'administrateur. Sur un ordinateur professionnel, demande l'accord de ton service informatique : l'installation d'un hyperviseur est souvent restreinte, et les VPN/antivirus d'entreprise interfèrent parfois. Sans accord possible, utilise **Killercoda**.

**Combien de RAM la VM utilise-t-elle ?**
4 Go par défaut, **réservés** tant que la VM tourne (et libérés à `vagrant halt`). Voir le [chapitre 7](#7-gestion-des-ressources) pour la modifier.

**Faut-il vraiment tout ça ? Je peux utiliser WSL2 ou Docker ?**
Pour les modules d'administration Linux, la VM est la référence (vrai `systemd`, vraie gestion des disques, réseau, noyau). WSL2 et Docker sont des substituts **partiels** ([§ 12.3](#123-windows-avec-wsl2)).

### Usage quotidien

**Puis-je travailler avec plusieurs VM en parallèle ?**
Oui si ta RAM le permet : crée un second dossier avec son propre `Vagrantfile` (`vb.name` différent, port SSH différent : Vagrant en choisit un libre). Chaque VM consomme sa RAM : vérifie avec `vagrant global-status`.

**Puis-je supprimer la VM entre deux sessions ?**
Oui (`vagrant destroy -f`), si ton travail est **sauvegardé dans `/vagrant/mes-travaux/`** ou Git. Ça libère le disque mais te coûte 3-5 minutes à chaque recréation et efface le snapshot. Préfère `halt`.

**Faut-il éteindre la VM entre deux sessions ?**
Recommandé : `vagrant halt` en fin de journée (libère RAM et CPU). `suspend` convient pour une pause courte. Évite de laisser tourner la VM des jours entiers sans raison.

**Que se passe-t-il si je ferme mon terminal ?**
La VM continue de tourner (elle est gérée par VirtualBox, pas par le terminal). Seul ton shell SSH est coupé : les programmes lancés sans `tmux` s'arrêtent. Rouvre un terminal et fais `vagrant ssh` ; utilise `tmux` pour les tâches longues.

**Comment savoir si ma VM est à jour ?**
Compare `vagrant box list` avec la dernière version de la [page Releases](https://github.com/Ghislano26/devops-Worketyamo/releases) et le changelog ([annexe F](#f-historique-des-versions-de-la-box)).

### Réseau et connectivité

**Que se passe-t-il si je perds ma connexion Internet pendant `vagrant up` ?**
Si la box est **déjà ajoutée**, `vagrant up` fonctionne **sans Internet** (hormis un éventuel provisioning). Si une étape de téléchargement échoue, relance `vagrant up --provision`. Pour le **téléchargement de la box**, reprends le fichier (un gestionnaire de téléchargement qui reprend est utile).

**Puis-je utiliser la VM sans Internet ?**
Oui pour tout ce qui ne demande pas de téléchargement : commandes, scripts, permissions, processus, LVM… En revanche `dnf install`, `git clone` ou `curl` vers Internet exigent le réseau.

**Comment accéder à la VM depuis un autre appareil de mon réseau ?**
Par défaut la VM n'est joignable que **depuis ton ordinateur** (réseau privé `192.168.56.10`), pas depuis le reste du réseau. Pour un service web, ajoute une redirection : `config.vm.network "forwarded_port", guest: 80, host: 8080` (accessible sur `http://<IP-de-ton-PC>:8080` si le pare-feu l'autorise), ou un réseau en pont : `config.vm.network "public_network"` (la VM obtient une IP de ton réseau). **À éviter sur un réseau public.**

### Environnement et outils

**Que faire si je veux faire un atelier sur une autre distribution (Ubuntu, Debian) ?**
Les cours sont écrits et testés pour **Rocky Linux 9**. Pour une autre distribution, crée une **seconde VM** (autre box, autre dossier) ou utilise Killercoda (`ubuntu`). Attention : `apt` ≠ `dnf`, certains chemins et noms de paquets diffèrent.

**Puis-je utiliser un autre hyperviseur (VMware, Proxmox, Hyper-V, UTM) ?**
Oui, mais **sans garantie de support** : la box fournie est au format **VirtualBox**. VMware demande une box `vmware_desktop`, Hyper-V une box `hyperv`, libvirt une box `libvirt`. Les performances et le comportement du dossier partagé varient. Pour Apple Silicon : [§ 12.1](#121-apple-silicon-mac-m1--m2--m3--m4).

**Puis-je installer d'autres logiciels dans la VM ?**
Oui : c'est ta VM (`sudo dnf install …`). **Prends un snapshot avant**, et n'installe pas ce qui change des paquets système critiques (noyau, `systemd`, `glibc`). Si quelque chose casse : `vagrant snapshot restore clean`.

**Où sont stockés les fichiers de la VM sur mon disque ?**
Les disques sont dans le dossier **VirtualBox VMs** (`C:\Users\<toi>\VirtualBox VMs\`, `~/VirtualBox VMs/`) ; les box dans `~/.vagrant.d/boxes` (Windows : `C:\Users\<toi>\.vagrant.d\boxes`). Ne les modifie pas à la main.

### Collaboration et support

**Puis-je partager ma VM avec un camarade ?**
Oui, via `vagrant package` ([§ 11.2](#112-option-b--export-complet-de-la-vm)) : tu donnes le `.box` (≈ 1,5 à 3 Go). Attention : ta VM exportée contient **tes fichiers, tes clés SSH et tes mots de passe** : nettoie-la avant (`~/.ssh`, `~/.bash_history`, `~/notes`). Il est généralement plus simple que chaque étudiant parte de la box officielle.

**Puis-je donner à un camarade l'accès à ma VM ?**
Déconseillé. Si besoin ponctuel, utilise `tmux` partagé ou, mieux, partagez un dépôt Git.

**Comment signaler un bug dans l'environnement ?**
Ouvre une *issue* sur <https://github.com/Ghislano26/devops-Worketyamo/issues> avec : ton système hôte, `vagrant --version`, `VBoxManage --version`, `vagrant box list`, le **message d'erreur complet** et les étapes pour reproduire. Pour un problème de VM : joins la sortie de `vagrant up --debug`.

**Où trouver de l'aide rapidement ?**
Dans l'ordre : ce guide (chapitre 10, [scénarios](environnement/SCENARIOS.md)), ton formateur ou tes camarades, les forums officiels (Vagrant, VirtualBox, Rocky), puis une *issue* GitHub.

**Mon antivirus bloque VirtualBox ou Vagrant. Que faire ?**
Ajoute des **exclusions** pour `VirtualBox VMs`, `.vagrant.d` et les exécutables `VBoxHeadless.exe`, `VBoxSVC.exe`, `vagrant.exe`. Ne désactive pas l'antivirus.

---

## 14. Annexes

### A. Cheatsheet Vagrant

| Commande | Effet |
|---|---|
| `vagrant up` | Crée et/ou démarre la VM |
| `vagrant status` | État de la VM du dossier courant |
| `vagrant global-status` | Toutes les VM Vagrant de la machine (`--prune` : nettoie les entrées orphelines) |
| `vagrant ssh` | Ouvre un shell dans la VM |
| `vagrant ssh -c 'commande'` | Exécute une commande dans la VM puis revient |
| `vagrant ssh-config` | Affiche la config SSH (host, port, clé) |
| `vagrant halt` | Éteint proprement la VM |
| `vagrant suspend` / `vagrant resume` | Met en pause / reprend |
| `vagrant reload` | Redémarre la VM en relisant le `Vagrantfile` |
| `vagrant reload --provision` | Redémarre et rejoue le provisioning |
| `vagrant provision` | Rejoue le provisioning sans redémarrer |
| `vagrant destroy -f` | **Supprime** la VM (sans confirmation) |
| `vagrant snapshot save <nom>` | Crée un snapshot |
| `vagrant snapshot list` | Liste les snapshots |
| `vagrant snapshot restore <nom>` | Restaure un snapshot |
| `vagrant snapshot delete <nom>` | Supprime un snapshot |
| `vagrant snapshot push` / `pop` | Empile / dépile un point de restauration |
| `vagrant upload <local> [<distant>]` | Envoie un fichier dans la VM |
| `vagrant package --output f.box` | Exporte la VM en box |
| `vagrant box list` | Liste les box installées |
| `vagrant box add <nom> <fichier>` | Ajoute une box |
| `vagrant box remove <nom>` | Supprime une box |
| `vagrant box prune` | Supprime les anciennes versions |
| `vagrant plugin list` / `install` | Gère les plugins |
| `vagrant version` / `--version` | Version de Vagrant |
| `vagrant validate` | Valide le `Vagrantfile` |
| `vagrant up --debug` | Démarre avec les journaux détaillés |
| `vagrant help <commande>` | Aide d'une commande |

### B. Cheatsheet VirtualBox

**Interface graphique**

| Raccourci / action | Effet |
|---|---|
| `Ctrl + droit` (touche hôte, par défaut *Ctrl droit*) | Libère le clavier et la souris capturés par la VM |
| `Hôte + F` | Plein écran |
| `Hôte + Suppr` | Envoie Ctrl + Alt + Suppr à la VM |
| `Hôte + T` | Prend un snapshot |
| `Hôte + R` | Redémarre la VM |
| *Machine → Afficher le journal* | Journal de la VM (diagnostic) |

**Ligne de commande `VBoxManage`**

```bash
VBoxManage --version                              # version
VBoxManage list vms                               # toutes les VM
VBoxManage list runningvms                        # VM en cours d'exécution
VBoxManage showvminfo "devops-lab" | head -n 30   # configuration
VBoxManage controlvm "devops-lab" acpipowerbutton # arrêt propre (ACPI)
VBoxManage controlvm "devops-lab" poweroff        # arrêt brutal (⚠️ risque de corruption)
VBoxManage snapshot "devops-lab" list             # snapshots
VBoxManage unregistervm "devops-lab" --delete     # supprime une VM fantôme (⚠️ définitif)
VBoxManage list hostonlyifs                       # réseaux « host-only »
```

### C. Cheatsheet diagnostic de la VM — les 10 commandes de santé

| # | Commande | Ce qu'elle vérifie |
|---|---|---|
| 1 | `hostname && cat /etc/rocky-release` | Je suis dans la bonne VM |
| 2 | `uptime` | Durée de fonctionnement et charge |
| 3 | `free -h` | Mémoire et swap |
| 4 | `df -h` | Espace disque |
| 5 | `systemctl --failed` | Services en échec |
| 6 | `journalctl -p err -b --no-pager \| tail` | Erreurs depuis le démarrage |
| 7 | `ip -br a` | Interfaces et adresses réseau |
| 8 | `ping -c 2 rockylinux.org` | Internet et DNS |
| 9 | `getenforce` | État de SELinux |
| 10 | `top -bn1 \| head -n 15` | Processus gourmands |

### D. Glossaire

| Terme | Définition |
|---|---|
| **Hôte** | L'ordinateur physique qui fait tourner l'hyperviseur |
| **Invité / VM** | Machine virtuelle qui tourne sur l'hôte |
| **Hyperviseur** | Logiciel qui crée et exécute des VM (VirtualBox, VMware, Hyper-V, KVM) |
| **VirtualBox** | Hyperviseur libre d'Oracle, utilisé dans ce cursus |
| **Vagrant** | Outil qui décrit, crée et pilote des VM de façon reproductible (outil de HashiCorp) |
| **Box** | Image de VM empaquetée (fichier `.box`) servant de modèle |
| **Vagrantfile** | Fichier Ruby qui décrit la VM (box, ressources, réseau, dossiers) |
| **Provisioning** | Configuration automatique de la VM au démarrage (scripts, installation d'outils) |
| **Provider** | Technologie de virtualisation utilisée par Vagrant (`virtualbox`, `vmware_desktop`, `libvirt`) |
| **Snapshot** | Photo de l'état de la VM, restaurable |
| **Dossier synchronisé** | Dossier partagé entre l'hôte et la VM (`/vagrant`) |
| **NAT** | Mode réseau où la VM accède à Internet via l'hôte, sans être joignable de l'extérieur |
| **Redirection de port** | Règle « port X de l'hôte → port Y de la VM » (ex. SSH : 2222 → 22) |
| **Headless** | Fonctionnement sans fenêtre graphique |
| **Guest Additions** | Pilotes de VirtualBox installés dans l'invité (dossiers partagés, intégration) |
| **VT-x / AMD-V** | Extensions de virtualisation matérielle des processeurs |
| **Hyper-V** | Hyperviseur de Windows |
| **WSL2** | Sous-système Linux de Windows, basé sur une VM légère |
| **`dnf`** | Gestionnaire de paquets de la famille Red Hat (Rocky, RHEL, Fedora) |
| **SELinux** | Module de sécurité Linux (contrôle d'accès obligatoire), présent sur Rocky (en mode permissif dans la box du cours) |
| **Rocky Linux** | Distribution communautaire compatible RHEL, successeur de CentOS |
| **SSH** | Protocole de connexion sécurisée à distance |
| **Idempotent** | Une commande qui, répétée, donne le même résultat sans effet de bord |
| **Killercoda** | Plateforme en ligne d'ateliers interactifs (serveurs éphémères dans le navigateur) |

### E. Liens utiles

| Ressource | Lien |
|---|---|
| Releases (box de l'environnement) | <https://github.com/Ghislano26/devops-Worketyamo/releases> |
| Issues (signaler un bug) | <https://github.com/Ghislano26/devops-Worketyamo/issues> |
| Documentation Vagrant | <https://developer.hashicorp.com/vagrant/docs> |
| Téléchargement Vagrant | <https://developer.hashicorp.com/vagrant/downloads> |
| Documentation VirtualBox | <https://www.virtualbox.org/manual/> |
| Téléchargement VirtualBox | <https://www.virtualbox.org/wiki/Downloads> |
| Documentation Rocky Linux | <https://docs.rockylinux.org/> |
| Téléchargement Rocky Linux | <https://rockylinux.org/download> |
| UTM (Mac Apple Silicon) | <https://mac.getutm.app/> |
| Killercoda | <https://killercoda.com/> |
| Cheatsheet à imprimer | [`environnement/CHEATSHEET.md`](environnement/CHEATSHEET.md) |
| Scénarios concrets | [`environnement/SCENARIOS.md`](environnement/SCENARIOS.md) |
| Scénarios Killercoda du cursus | [`KILLERCODA.md`](KILLERCODA.md) |

### F. Historique des versions de la box

| Version | Date | Contenu |
|---|---|---|
| **1.0.0** | *à remplir à la date du premier build réussi* | Version initiale : Rocky Linux 9, utilisateur `vagrant` (sudo NOPASSWD), nom d'hôte `devops-lab`, outils de base (`vim`, `nano`, `git`, `curl`, `wget`, `tmux`, `jq`, `tree`, `podman`, `buildah`, `skopeo`, `make`, `gcc`, `python3`, `rsync`, `unzip`, `tar`), outils DevOps épinglés (`kubectl` v1.30.5, `helm` v3.16.1, `trivy` 0.56.1, `syft` v1.14.0, `act` 0.2.68, `shellcheck` v0.10.0, `yq` v4.44.3), `firewalld` + SSH par clé, SELinux permissif, dossier partagé `/vagrant` = racine du dépôt, 4 Go de RAM, 2 vCPU, 40 Go de disque |
| *1.1.0* | *à venir* | *Modèle de ligne : ajout de X, correction de Y. Le formateur renseigne ce tableau à chaque publication d'une release.* |

> 📌 Chaque nouvelle version de la box est annoncée sur la page des [Releases](https://github.com/Ghislano26/devops-Worketyamo/releases) ; **ne mets à jour que si ton formateur l'indique** ([§ 8.2](#82-mettre-à-jour-la-box-elle-même)).

---

[⬆️ Retour à la table des matières](#-table-des-matières) · [← README principal](README.md)
