# Guide d'installation d'Ubuntu 24.04 LTS avec VMware

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

1. Rendez-vous sur <https://ubuntu.com/download>.
2. Choisissez **Ubuntu Server 24.04 LTS** (ou Desktop), architecture **amd64** (ou **arm64** sur Mac Apple Silicon).
3. Téléchargez le fichier `.iso` (environ 2 à 6 Go).
4. **Vérifiez l'intégrité** (bonne pratique de sécurité). Récupérez le fichier `SHA256SUMS` sur la même page, puis :

```bash
# Linux / macOS
sha256sum ubuntu-24.04*-live-server-amd64.iso     # macOS : shasum -a 256 <fichier>
```

```powershell
# Windows PowerShell
Get-FileHash .\ubuntu-24.04-live-server-amd64.iso -Algorithm SHA256
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
5. Système invité : **Linux**, version **Ubuntu 64-bit** (ou *Ubuntu 64-bit Arm* sur Apple Silicon).
6. Nom : `ubuntu-2404-devops`. Emplacement : un disque avec assez de place.
7. Firmware : **UEFI**. Désactivez *Secure Boot* si l'installation échoue au démarrage.

## 4. Paramètres recommandés

| Paramètre | Valeur | Justification |
|---|---|---|
| Processeurs | **4 vCPU** (1 socket × 4 cœurs) | Compiler, lancer des conteneurs sans lenteur |
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

## 5. Installation d'Ubuntu

Démarrez la VM (**Power on**). L'installeur démarre sur l'ISO. Version **Server** :

1. **Langue** : *English* ou *Français*. Pour un serveur, l'anglais facilite la recherche d'erreurs sur Internet.
2. **Disposition du clavier** : *French* (ou celle de votre clavier). Testez avec la zone de test.
3. **Type d'installation** : *Ubuntu Server*. Ne cochez pas « minimized » pour ce cours.
4. **Réseau** : laissez le DHCP. Une adresse du type `192.168.xx.xx` doit apparaître.
5. **Proxy** : vide.
6. **Miroir d'archive** : laissez par défaut.
7. **Stockage** : *Use an entire disk*. Décochez **« Set up this disk as an LVM group »** pour l'instant (nous étudierons LVM au module 03).
8. **Profil** : nom, nom du serveur (`ubuntu-devops`), identifiant (ex. `etudiant`), mot de passe robuste.
9. **Ubuntu Pro** : *Skip for now*.
10. **SSH** : cochez **Install OpenSSH server**. Pas d'import de clés pour le moment.
11. **Snaps** : n'en sélectionnez aucun.
12. Attendez la fin, puis **Reboot Now**. Si le message demande de retirer le support, appuyez sur `Entrée` (VMware éjecte l'ISO automatiquement).

> 💡 **Conseil** : version **Desktop** — l'assistant graphique est similaire : choisissez « Installer Ubuntu »,
> « Installation interactive », « Installation par défaut », « Effacer le disque et installer Ubuntu » (cela n'efface
> que le disque virtuel).

## 6. Premier démarrage

Connectez-vous avec l'utilisateur créé. Vérifiez :

```bash
lsb_release -a        # doit afficher Ubuntu 24.04.x LTS
ip -br a              # adresses IP des interfaces
ping -c 2 ubuntu.com  # test d'accès à Internet
```

## 7. VMware Tools (open-vm-tools)

Sous Ubuntu, le paquet libre `open-vm-tools` est généralement préinstallé. Il permet le
copier-coller, la résolution dynamique et un arrêt propre depuis VMware.

```bash
sudo apt update
sudo apt install -y open-vm-tools          # Server
sudo apt install -y open-vm-tools-desktop  # Desktop uniquement
```

## 8. Prendre le snapshot

1. VM → **Snapshot** → **Take Snapshot…**
2. Nom : `00-installation-propre`. Description : « Ubuntu 24.04 fraîchement installé et mis à jour ».
3. Pour restaurer : VM → Snapshot → **Snapshot Manager** → sélectionner → **Go To**.

> ⚠️ **Attention** : un snapshot n'est **pas** une sauvegarde. Il dépend du disque d'origine. Ne gardez pas
> dix snapshots en chaîne : ils ralentissent la VM et occupent de la place.

## 9. Problèmes fréquents

| Symptôme | Cause probable | Solution |
|---|---|---|
| « VT-x is disabled » | Virtualisation désactivée | L'activer dans le BIOS/UEFI |
| L'écran reste noir au démarrage | Secure Boot / UEFI | Désactiver Secure Boot (VM → Settings → Options → Advanced) |
| Pas d'Internet dans la VM | Adaptateur non connecté | Vérifier *Network Adapter = NAT* et *Connected* |
| Clavier mal configuré | Mauvaise disposition | `sudo dpkg-reconfigure keyboard-configuration` |
| VM très lente | RAM hôte insuffisante | Réduire à 2 vCPU / 3 Go, fermer les applications lourdes |

## Étape suivante

Déroulez la [checklist post-installation](checklist-post-installation.md).
