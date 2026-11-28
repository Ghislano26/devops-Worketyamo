# Guide d'installation de Rocky Linux 9 avec VMware

> ⚠️ **Méthode recommandée** : `make up` (voir [GUIDE-ENVIRONNEMENT.md](../GUIDE-ENVIRONNEMENT.md)). Ce guide décrit l'installation manuelle, utile si tu veux comprendre ce qui se passe sous le capot ou si tu ne peux pas utiliser Vagrant.

> 🐧 **Ubuntu ?** La création de la VM est identique pour Ubuntu (système invité *Ubuntu 64-bit*) ; seuls l'installeur et les commandes (`apt`…) diffèrent. Le cursus suppose **Rocky Linux 9**.

Ce guide s'applique à **VMware Workstation Pro/Player** (Windows, Linux) et **VMware Fusion**
(macOS). Les libellés exacts peuvent varier légèrement d'une version à l'autre.

## 1. Prérequis

- Virtualisation matérielle activée dans le BIOS/UEFI (VT-x / AMD-V). Sous Windows, vérifiez dans le Gestionnaire des tâches → Performances → CPU → « Virtualisation : activée ».
- 8 Go de RAM minimum sur l'hôte, 60 Go de disque libre.
- VMware installé (téléchargement gratuit pour usage personnel depuis le site de Broadcom).

> ⚠️ **Attention** : sous Windows, certaines fonctions (Hyper-V, Credential Guard, WSL2) peuvent
> entrer en conflit avec la virtualisation. Les versions récentes de VMware cohabitent avec Hyper-V
> (mode « Windows Hypervisor Platform »), mais avec des performances réduites.

## 2. Télécharger l'ISO

1. Rendez-vous sur <https://rockylinux.org/download>.
2. Choisissez **Rocky Linux 9**, architecture **x86_64** (ou **aarch64** sur Mac Apple Silicon avec VMware Fusion), image **Minimal** (≈ 1,7 Go) ou **DVD** (≈ 10 Go).
3. Téléchargez le fichier `.iso`.
4. **Vérifiez l'intégrité** (bonne pratique de sécurité). Récupérez le fichier `CHECKSUM` publié à côté de l'ISO, puis :

```bash
# Linux / macOS
sha256sum Rocky-9*-x86_64-minimal.iso     # macOS : shasum -a 256 <fichier>
```

```powershell
# Windows PowerShell
Get-FileHash .\Rocky-9.x-x86_64-minimal.iso -Algorithm SHA256
```

Comparez l'empreinte obtenue avec celle publiée. Si elles diffèrent, retéléchargez.

> 💡 **Conseil** : l'empreinte (*hash*) est une « signature » du fichier. Un seul bit modifié change tout le hash.

## 3. Créer la machine virtuelle

1. Lancez VMware et choisissez **Create a New Virtual Machine** (Fichier → Nouvelle machine virtuelle).
2. Type de configuration : **Custom (advanced)** pour tout maîtriser (ou *Typical* si vous êtes pressé).
3. Compatibilité matérielle : laissez la valeur par défaut.
4. **Installer disc image file (iso)** : sélectionnez l'ISO téléchargée.
   > ⚠️ Évitez l'« Easy Install » de VMware : il crée un utilisateur à votre place et masque des étapes pédagogiques.
   Choisissez plutôt **« I will install the operating system later »**, puis attachez l'ISO à l'étape 6.
5. Système invité : **Linux**, version **Red Hat Enterprise Linux 9 64-bit** (ou *Rocky Linux 64-bit* si proposé ; *… 64-bit Arm* sur Apple Silicon).
6. Nom : `rocky9-devops`. Emplacement : un disque avec assez de place.
7. Firmware : **BIOS** ou **UEFI**. Avec UEFI, désactivez *Secure Boot* si l'installation échoue au démarrage.

## 4. Paramètres recommandés

| Paramètre | Valeur | Justification |
|---|---|---|
| Processeurs | **2 vCPU** (4 si possible) | Compiler, lancer des conteneurs sans lenteur |
| Mémoire | **4096 Mo** | Confortable pour le serveur et Docker |
| Disque | **40 Go**, *Store as a single file*, **pas** de pré-allocation | Le disque grossit à mesure de l'usage |
| Réseau | **NAT** | La VM accède à Internet via l'hôte, sans être exposée sur votre réseau local |
| USB / son / imprimante | Peuvent être retirés | Moins de ressources consommées |

### Pourquoi le réseau NAT ?

```text
 Internet ◄──► [Box/Routeur] ◄──► [PC hôte] ◄──NAT──► [VM 192.168.x.x]
```

En mode **NAT**, VMware crée un réseau privé et traduit les adresses : la VM sort sur Internet,
mais n'est pas joignable depuis l'extérieur. C'est sûr et sans configuration. Pour l'atelier SSH
(module 02), nous utiliserons la redirection de port ou le réseau « Host-only ».

Pour vérifier ou modifier : **VM → Settings → Network Adapter → NAT**.

## 5. Installation de Rocky Linux

Démarrez la VM (**Power on**). Le menu de démarrage propose **Install Rocky Linux 9** (validez avec `Entrée`). L'assistant graphique **Anaconda** s'affiche ; son **résumé de l'installation** liste les sections à compléter (celles avec un triangle jaune sont obligatoires) :

1. **Langue** : *English* ou *Français*. Pour un serveur, l'anglais facilite la recherche d'erreurs sur Internet.
2. **Clavier** : *French* (ou celui de votre clavier). Testez avec la zone de test.
3. **Heure et date** : choisissez votre fuseau horaire (ex. Africa/Douala).
4. **Sélection de logiciels** : **Minimal Install** (recommandé pour ce cours) ou *Server with GUI*.
5. **Destination d'installation** : sélectionnez le disque de 40 Go, partitionnement **Automatique** (LVM + XFS par défaut ; nous étudierons LVM au module 03).
6. **Réseau et nom d'hôte** : activez l'interface (**ON**, DHCP : une adresse du type `192.168.xx.xx` doit apparaître) et saisissez le nom d'hôte **`devops-lab`**.
7. **Mot de passe root** : *Disable root account* (recommandé), ou un mot de passe robuste.
8. **Création d'utilisateur** : identifiant (`vagrant` comme dans la VM `make up`, ou le vôtre), mot de passe robuste, cochez **Make this user administrator** (groupe `wheel` : droits `sudo`).
9. **Begin Installation**, attendez la fin, puis **Reboot System**. VMware éjecte l'ISO automatiquement ; sinon, déconnectez le lecteur CD/DVD dans *VM → Settings*.

> 💡 **Conseil** : avec *Server with GUI*, un assistant de premier démarrage (*Initial Setup*) peut demander d'accepter la licence : acceptez et terminez.

## 6. Premier démarrage

Connectez-vous avec l'utilisateur créé. Vérifiez :

```bash
cat /etc/rocky-release  # doit afficher Rocky Linux release 9.x
ip -br a              # adresses IP des interfaces
ping -c 2 rockylinux.org  # test d'accès à Internet
```

## 7. VMware Tools (open-vm-tools)

Sous Rocky, le paquet libre `open-vm-tools` est généralement préinstallé sur une machine reconnue comme VMware. Il permet le
copier-coller, la résolution dynamique et un arrêt propre depuis VMware.

```bash
rpm -q open-vm-tools || sudo dnf install -y open-vm-tools   # Server
sudo dnf install -y open-vm-tools-desktop                   # avec interface graphique uniquement
sudo systemctl enable --now vmtoolsd
```

## 8. Prendre le snapshot

1. VM → **Snapshot** → **Take Snapshot…**
2. Nom : `00-installation-propre`. Description : « Rocky Linux 9 fraîchement installé et mis à jour ».
3. Pour restaurer : VM → Snapshot → **Snapshot Manager** → sélectionner → **Go To**.

> ⚠️ **Attention** : un snapshot n'est **pas** une sauvegarde. Il dépend du disque d'origine. Ne gardez pas
> dix snapshots en chaîne : ils ralentissent la VM et occupent de la place.

## 9. Problèmes fréquents

| Symptôme | Cause probable | Solution |
|---|---|---|
| « VT-x is disabled » | Virtualisation désactivée | L'activer dans le BIOS/UEFI |
| L'écran reste noir au démarrage | Secure Boot / UEFI | Désactiver Secure Boot (VM → Settings → Options → Advanced) |
| Pas d'Internet dans la VM | Adaptateur non connecté | Vérifier *Network Adapter = NAT* et *Connected* |
| Clavier mal configuré | Mauvaise disposition | `sudo localectl set-keymap fr` (ou votre disposition) |
| VM très lente | RAM hôte insuffisante | Réduire à 2 vCPU / 3 Go, fermer les applications lourdes |

## Étape suivante

Déroulez la [checklist post-installation](checklist-post-installation.md).
