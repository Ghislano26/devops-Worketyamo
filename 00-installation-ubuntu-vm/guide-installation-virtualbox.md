# Guide d'installation de Rocky Linux 9 avec VirtualBox

> ⚠️ **Méthode recommandée** : `make up` (voir [GUIDE-ENVIRONNEMENT.md](../GUIDE-ENVIRONNEMENT.md)). Ce guide décrit l'installation manuelle, utile si tu veux comprendre ce qui se passe sous le capot ou si tu ne peux pas utiliser Vagrant.

VirtualBox (Oracle) est gratuit, open source et disponible sous Windows, Linux et macOS
(Intel). Ce guide utilise VirtualBox 7.x.

> ⚠️ **Attention** : sur Mac Apple Silicon, VirtualBox ne convient pas : privilégiez UTM ou VMware Fusion
> (voir le [README du module](README.md)).

> 🐧 **Ubuntu ?** Si vous préférez installer Ubuntu (famille Debian), la procédure de création de la VM est la même (type *Ubuntu 64-bit*, ISO d'<https://ubuntu.com/download>) ; seuls l'assistant d'installation et les commandes (`apt`…) diffèrent. Le cursus, lui, suppose **Rocky Linux 9**.

## 1. Prérequis

- Virtualisation matérielle (VT-x / AMD-V) activée dans le BIOS/UEFI.
- 8 Go de RAM sur l'hôte, 60 Go de disque libre.
- VirtualBox et son *Extension Pack* (facultatif) installés depuis <https://www.virtualbox.org/wiki/Downloads>.

## 2. Télécharger et vérifier l'ISO

1. Allez sur <https://rockylinux.org/download> et téléchargez **Rocky Linux 9** pour **x86_64** : l'ISO **Minimal** (`Rocky-9.x-x86_64-minimal.iso`, environ 1,7 Go) ou **DVD** (≈ 10 Go).
2. Vérifiez l'empreinte SHA-256 :

```bash
sha256sum Rocky-9*-x86_64-minimal.iso   # Linux ; macOS : shasum -a 256
```

```powershell
Get-FileHash .\Rocky-9.x-x86_64-minimal.iso -Algorithm SHA256   # Windows
```

3. Comparez avec la valeur du fichier `CHECKSUM` publié à côté de l'ISO (sur le serveur de téléchargement de Rocky).

## 3. Créer la VM

Cliquez sur **Nouvelle** :

1. **Nom** : `rocky9-devops`.
2. **Image ISO** : sélectionnez l'ISO.
3. Cochez **Ignorer l'installation automatique** (*Skip Unattended Installation*) : vous voulez voir et comprendre chaque étape.
4. **Type** : Linux — **Version** : Red Hat (64-bit) (ou *Oracle Linux 9 (64-bit)*).
5. **Matériel** : mémoire **4096 Mo**, processeurs **2** (4 si possible). *EFI* : facultatif (BIOS ou EFI : les deux conviennent).
6. **Disque dur** : *Créer un disque dur virtuel maintenant*, **40 Go**, **ne pas** cocher « Pré-allouer toute la taille » (allocation dynamique).
7. Terminez.

## 4. Paramètres recommandés (Configuration)

| Menu | Réglage | Valeur |
|---|---|---|
| Système → Carte mère | Mémoire vive | 4096 Mo |
| Système → Processeur | Processeurs | 2 à 4 (+ *Activer PAE/NX*) |
| Affichage → Écran | Mémoire vidéo | 16 Mo (Minimal) ou 128 Mo (avec interface graphique) |
| Stockage | Contrôleur SATA | ISO de Rocky insérée dans le lecteur optique |
| Réseau → Adaptateur 1 | Mode d'accès réseau | **NAT** |
| Réseau → Adaptateur 2 *(facultatif)* | Réseau privé hôte (*Host-only*) | Pour joindre la VM depuis l'hôte (comme la VM Vagrant : `192.168.56.x`) |
| Presse-papiers partagé | Bidirectionnel | Pratique, à désactiver si vous craignez des fuites |

### Redirection de port (utile pour SSH dès maintenant)

En mode NAT, la VM n'est pas joignable depuis l'hôte. Ajoutez une règle :

**Réseau → Avancé → Redirection de ports → Ajouter** :

| Nom | Protocole | IP hôte | Port hôte | IP invité | Port invité |
|---|---|---|---|---|---|
| ssh | TCP | 127.0.0.1 | 2222 | *(vide)* | 22 |

Vous pourrez alors faire `ssh -p 2222 votre-utilisateur@127.0.0.1` depuis votre hôte (module 02).

## 5. Installer Rocky Linux

Démarrez la VM : le menu de démarrage propose **Install Rocky Linux 9** (validez avec `Entrée`). L'assistant **Anaconda** s'affiche (en mode graphique, y compris pour l'ISO minimale). Le **résumé de l'installation** liste les sections à compléter (les icônes avec un triangle jaune sont obligatoires) :

1. **Langue** : *English* (ou *Français*). Clavier : choisissez le vôtre et testez-le.
2. **Heure et date** (*Time & Date*) : choisissez votre fuseau horaire (ex. Africa/Douala) et laissez l'heure réseau activée.
3. **Source d'installation** : par défaut (l'ISO ; pour l'ISO minimale, le réseau peut servir de source).
4. **Sélection de logiciels** (*Software Selection*) : **Minimal Install** (serveur sans interface graphique) ou *Server with GUI* si vous voulez un bureau.
5. **Destination d'installation** : sélectionnez le disque virtuel de 40 Go, laissez **Automatique** (le partitionnement par défaut utilise LVM et XFS ; la disposition exacte — XFS ou ext4, LVM ou partitions simples — varie selon l'installation et la box : les cours expliquent comment la lire avec `lsblk -f` et `df -T`).
6. **Réseau et nom d'hôte** : activez l'interface (interrupteur sur **ON** : DHCP, IP du type `10.0.2.15` en NAT VirtualBox) et saisissez le nom d'hôte **`devops-lab`**.
7. **Mot de passe root** : *Disable root account* (recommandé : on utilisera `sudo`), ou un mot de passe robuste.
8. **Création d'utilisateur** : nom `vagrant` (comme dans la VM `make up`) ou votre identifiant, mot de passe robuste, cochez **Make this user administrator** : l'utilisateur rejoint le groupe `wheel` (droits `sudo`).
9. Cliquez sur **Begin Installation** (environ 5 à 10 minutes).
10. Fin de l'installation → **Reboot System**. Quand l'écran de démarrage réapparaît avec l'ISO, faites **Périphériques → Lecteurs optiques → Retirer le disque** (ou *Forcer le démontage*), puis laissez la VM redémarrer.

Pour **Server with GUI**, un assistant de premier démarrage (*Initial Setup*) peut demander d'accepter la licence : acceptez et terminez.

## 6. Premiers contrôles

```bash
cat /etc/rocky-release    # Rocky Linux release 9.x (Blue Onyx)
ip -br a                  # 10.0.2.15 en NAT
ping -c 2 rockylinux.org  # accès Internet
```

## 7. Additions invité (Guest Additions)

Elles améliorent l'intégration (résolution, presse-papiers, dossiers partagés). Elles se **compilent** pour le noyau en cours : il faut donc les outils de compilation et les en-têtes du noyau.

```bash
sudo dnf install -y epel-release
sudo dnf install -y kernel-devel-$(uname -r) kernel-headers gcc make perl bzip2 tar elfutils-libelf-devel
```

Puis dans le menu VirtualBox : **Périphériques → Insérer l'image CD des Additions invité…**, et dans la VM :

```bash
sudo mount /dev/cdrom /mnt
sudo sh /mnt/VBoxLinuxAdditions.run
sudo umount /mnt
sudo reboot
```

> 💡 **Conseil** : pour un serveur en console seule, les Additions ne sont pas indispensables (mais elles sont nécessaires pour les **dossiers partagés** comme `/vagrant`).
> 🧱 Avec `make up`, tu n'as normalement rien à installer : si `ls /vagrant` ne renvoie rien, installe le plugin `vagrant-vbguest` (voir le [guide, § 5.1](../GUIDE-ENVIRONNEMENT.md#51-méthode-1--le-dossier-synchronisé-vagrant)). Si l'installation signale « Could not find the Linux kernel headers », vérifiez que `kernel-devel-$(uname -r)` correspond bien au noyau (`uname -r`) : faites d'abord `sudo dnf upgrade -y && sudo reboot`.

## 8. Snapshot

1. Éteignez proprement la VM (`sudo poweroff`) ou laissez-la allumée.
2. Dans VirtualBox : **Machine → Instantanés** (onglet *Snapshots*) → **Prendre**.
3. Nom : `00-installation-propre`.
4. Restauration : sélectionnez l'instantané → **Restaurer**.

> ⚠️ **Attention** : restaurer un instantané **perd** tout ce qui a été fait depuis. Copiez vos fichiers importants
> sur l'hôte (ou dans un dépôt Git) avant.

## 9. Problèmes fréquents

| Symptôme | Cause | Solution |
|---|---|---|
| « VT-x is not available » | Hyper-V actif sous Windows | `bcdedit /set hypervisorlaunchtype off` puis redémarrer, ou désactiver la fonctionnalité Windows « Plateforme de machine virtuelle » |
| Écran noir après installation | Carte graphique virtuelle | Mettre le contrôleur graphique sur *VMSVGA* |
| « Kernel panic » au démarrage | Mémoire ou type de VM incorrect | Vérifier Type = Linux, 64-bit |
| Anaconda affiche « Installation source not ready » | ISO minimale sans réseau | Activer le réseau (étape 6 de l'installation) puis rouvrir *Installation Source* |
| Pas d'Internet | Adaptateur désactivé | Réseau → Adaptateur 1 → *Activer*, mode NAT ; dans la VM : `nmcli device status` |
| Souris capturée | Pas d'Additions | `Ctrl` droit pour libérer la souris |
| `dnf` : « Failed to download metadata » | Pas de réseau ou DNS | `ping 8.8.8.8` puis `ping rockylinux.org` |

## Étape suivante

Déroulez la [checklist post-installation](checklist-post-installation.md).
