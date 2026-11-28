# Module 00 — Installation de Rocky Linux 9 en machine virtuelle

> 📘 **La VM de référence est fournie par le formateur via Vagrant** (voir le [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md)) : c'est la voie normale, elle ne demande aucune installation de système.
> **Si tu dois recréer la VM manuellement** (pas de Vagrant possible, VMware imposé, besoin de comprendre l'installation), voici la procédure pour **Rocky Linux 9** : ce module la décrit pas à pas avec VirtualBox et VMware.

> 🐧 *Le nom du dossier (`00-installation-ubuntu-vm`) est conservé pour ne pas casser les liens du dépôt ; son contenu décrit Rocky Linux 9.*

## Pourquoi une machine virtuelle ?

Apprendre l'administration Linux implique de **faire des erreurs** : supprimer un fichier
système, casser une configuration réseau, saturer un disque. Sur votre ordinateur
personnel, c'est dangereux. Dans une **machine virtuelle (VM)**, c'est sans risque :
un *snapshot* (instantané) permet de revenir à un état sain en quelques secondes.

```text
┌──────────────────────────────────────────────┐
│  Votre PC (hôte) : Windows / macOS / Linux   │
│  ┌────────────────────────────────────────┐  │
│  │ Hyperviseur (VMware / VirtualBox)      │  │
│  │  ┌──────────────────────────────────┐  │  │
│  │  │ VM invitée : Rocky Linux 9       │  │  │
│  │  │ 2 vCPU · 4 Go RAM · 40 Go disque │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

> 📌 **À retenir** : l'**hôte** est votre machine physique, l'**invité** (*guest*) est la VM.
> L'**hyperviseur** est le logiciel qui crée et fait tourner les VM.

## Pourquoi Rocky Linux 9 ?

- **Binaire-compatible avec RHEL 9** (Red Hat Enterprise Linux) : les commandes, les chemins, les paquets et les outils (`dnf`, `systemd`, `firewalld`, SELinux) sont ceux des serveurs d'entreprise.
- **Gratuite** et communautaire : successeur de CentOS, sans licence.
- **Support long** : mises à jour de sécurité jusqu'en **2032**.
- Très présente en entreprise, dans le cloud et dans les certifications Red Hat (RHCSA, RHCE).

> 🐧 **Et Ubuntu ?** Ubuntu (famille Debian : `apt`, `ufw`, AppArmor) reste très répandue ; les cours indiquent l'équivalent quand la commande diffère. Les ateliers Killercoda tournent sur Ubuntu.

## Contenu du module

| Fichier | Rôle |
|---|---|
| [`guide-installation-vmware.md`](guide-installation-vmware.md) | Guide pas à pas avec VMware Workstation / Fusion |
| [`guide-installation-virtualbox.md`](guide-installation-virtualbox.md) | Guide pas à pas avec VirtualBox |
| [`checklist-post-installation.md`](checklist-post-installation.md) | Commandes à exécuter après l'installation |

Choisissez **un seul** hyperviseur. Si vous hésitez : VirtualBox est gratuit et
disponible partout ; VMware Workstation Pro et Fusion Pro sont gratuits pour un usage
personnel depuis 2024.

## Configuration de la VM recommandée

| Paramètre | Valeur |
|---|---|
| vCPU | 2 (4 si votre machine le permet) |
| Mémoire | 4 Go (4096 Mo) |
| Disque | 40 Go (allocation dynamique) |
| Réseau | NAT (+ réseau privé *Host-only* si vous voulez joindre la VM depuis l'hôte) |
| Firmware | BIOS ou UEFI (la VM Vagrant du cours est en BIOS) |
| Image | **Rocky Linux 9** (`Rocky-9.x-x86_64-minimal.iso`, 64 bits) : <https://rockylinux.org/download> |
| Nom d'hôte | `devops-lab` |
| Utilisateur | `vagrant` (pour reproduire la VM de référence) ou votre identifiant |

> ⚠️ **Attention** : sur Mac à processeur Apple Silicon (M1 à M4), l'architecture est **aarch64** (arm64).
> Téléchargez l'ISO « aarch64 » et utilisez **UTM** (gratuit) ou VMware Fusion. VirtualBox ne
> convient pas à ces machines. Les commandes du cours sont identiques (voir le chapitre 12 du [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md)).

## Quelle variante de Rocky choisir ?

- **Minimal** (ISO `minimal`) : sans interface graphique, léger, très proche d'un vrai serveur. Idéal pour un cursus « console-first » : **recommandé**.
- **DVD** avec *Server with GUI* : interface graphique. Plus confortable pour débuter (copier-coller, navigateur). Ouvrez simplement un terminal depuis les applications.

Les ateliers fonctionnent sur les deux. Ce cursus recommande **Minimal** (la VM Vagrant du cours est une installation minimale).

## Checklist de fin de module

- [ ] La VM démarre et vous pouvez vous connecter.
- [ ] `cat /etc/rocky-release` affiche *Rocky Linux release 9*.
- [ ] La VM accède à Internet (`ping -c 2 rockylinux.org`).
- [ ] Le système est à jour (`sudo dnf upgrade -y`).
- [ ] Un utilisateur non-root avec `sudo` (groupe `wheel`) est en place.
- [ ] Un snapshot nommé **« 00-installation-propre »** existe.

Le détail des commandes se trouve dans la [checklist post-installation](checklist-post-installation.md).

## Et ensuite ?

Passez au [module 01 — Fondamentaux](../01-linux-fondamentaux/cours/01-introduction-linux.md).
