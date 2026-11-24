# Module 00 — Installation d'Ubuntu 24.04 LTS en machine virtuelle

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
│  │  │ VM invitée : Ubuntu 24.04 LTS    │  │  │
│  │  │ 4 vCPU · 4 Go RAM · 40 Go disque │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

> 📌 **À retenir** : l'**hôte** est votre machine physique, l'**invité** (*guest*) est la VM.
> L'**hyperviseur** est le logiciel qui crée et fait tourner les VM.

## Pourquoi Ubuntu 24.04 LTS ?

- **LTS** (*Long Term Support*) : 5 ans de mises à jour de sécurité (jusqu'en 2029, extensible avec Ubuntu Pro).
- Très répandue sur les serveurs et dans le cloud : ce que vous apprenez est directement réutilisable.
- Documentation abondante, communauté active.

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
| vCPU | 4 |
| Mémoire | 4 Go (4096 Mo) |
| Disque | 40 Go (allocation dynamique) |
| Réseau | NAT |
| Firmware | UEFI |
| Image | Ubuntu Server ou Desktop 24.04 LTS (amd64) |

> ⚠️ **Attention** : sur Mac à processeur Apple Silicon (M1 à M4), l'architecture est **arm64**.
> Téléchargez l'ISO « arm64 » et utilisez VMware Fusion ou UTM. VirtualBox ne gère pas bien
> Ubuntu arm64 sur ces machines. Les commandes du cours sont identiques.

## Quelle variante d'Ubuntu choisir ?

- **Ubuntu Server** : sans interface graphique, léger, proche d'un vrai serveur. Idéal pour un cursus « console-first ».
- **Ubuntu Desktop** : avec interface graphique. Plus confortable pour débuter (copier-coller, navigateur). Ouvrez simplement un terminal (`Ctrl+Alt+T`).

Les ateliers fonctionnent sur les deux. Ce cursus recommande **Server** si votre machine le
permet, sinon **Desktop**.

## Checklist de fin de module

- [ ] La VM démarre et vous pouvez vous connecter.
- [ ] `lsb_release -a` affiche *Ubuntu 24.04*.
- [ ] La VM accède à Internet (`ping -c 2 ubuntu.com`).
- [ ] Le système est à jour (`sudo apt update && sudo apt upgrade`).
- [ ] Un utilisateur non-root avec `sudo` est en place.
- [ ] Un snapshot nommé **« 00-installation-propre »** existe.

Le détail des commandes se trouve dans la [checklist post-installation](checklist-post-installation.md).

## Et ensuite ?

Passez au [module 01 — Fondamentaux](../01-linux-fondamentaux/cours/01-introduction-linux.md).
