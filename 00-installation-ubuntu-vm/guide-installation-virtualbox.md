# Guide d'installation d'Ubuntu 24.04 LTS avec VirtualBox

VirtualBox (Oracle) est gratuit, open source et disponible sous Windows, Linux et macOS
(Intel). Ce guide utilise VirtualBox 7.x.

> ⚠️ **Attention** : sur Mac Apple Silicon, privilégiez VMware Fusion ou UTM (voir le
> [README du module](README.md)).

## 1. Prérequis

- Virtualisation matérielle (VT-x / AMD-V) activée dans le BIOS/UEFI.
- 8 Go de RAM sur l'hôte, 60 Go de disque libre.
- VirtualBox et son *Extension Pack* (facultatif) installés depuis <https://www.virtualbox.org/wiki/Downloads>.

## 2. Télécharger et vérifier l'ISO

1. Allez sur <https://ubuntu.com/download> et téléchargez **Ubuntu Server 24.04 LTS** (ou Desktop), amd64.
2. Vérifiez l'empreinte SHA-256 :

```bash
sha256sum ubuntu-24.04*-live-server-amd64.iso   # Linux ; macOS : shasum -a 256
```

```powershell
Get-FileHash .\ubuntu-24.04-live-server-amd64.iso -Algorithm SHA256   # Windows
```

3. Comparez avec la valeur du fichier `SHA256SUMS` publié par Ubuntu.

## 3. Créer la VM

Cliquez sur **Nouvelle** :

1. **Nom** : `ubuntu-2404-devops`.
2. **Image ISO** : sélectionnez l'ISO.
3. Cochez **Ignorer l'installation automatique** (*Skip Unattended Installation*) : vous voulez voir et comprendre chaque étape.
4. **Type** : Linux — **Version** : Ubuntu (64-bit).
5. **Matériel** : mémoire **4096 Mo**, processeurs **4**, cochez **Activer EFI**.
6. **Disque dur** : *Créer un disque dur virtuel maintenant*, **40 Go**, **ne pas** cocher « Pré-allouer toute la taille » (allocation dynamique).
7. Terminez.

## 4. Paramètres recommandés (Configuration)

| Menu | Réglage | Valeur |
|---|---|---|
| Système → Carte mère | Mémoire vive | 4096 Mo |
| Système → Processeur | Processeurs | 4 (+ *Activer PAE/NX*) |
| Affichage → Écran | Mémoire vidéo | 16 Mo (Server) ou 128 Mo (Desktop) |
| Stockage | Contrôleur SATA | ISO d'Ubuntu insérée dans le lecteur optique |
| Réseau → Adaptateur 1 | Mode d'accès réseau | **NAT** |
| Presse-papiers partagé | Bidirectionnel | Pratique, à désactiver si vous craignez des fuites |

### Redirection de port (utile pour SSH dès maintenant)

En mode NAT, la VM n'est pas joignable depuis l'hôte. Ajoutez une règle :

**Réseau → Avancé → Redirection de ports → Ajouter** :

| Nom | Protocole | IP hôte | Port hôte | IP invité | Port invité |
|---|---|---|---|---|---|
| ssh | TCP | 127.0.0.1 | 2222 | *(vide)* | 22 |

Vous pourrez alors faire `ssh -p 2222 etudiant@127.0.0.1` depuis votre hôte (module 02).

## 5. Installer Ubuntu

Démarrez la VM. Pour **Ubuntu Server** :

1. Langue : *English* (ou *Français*). Clavier : choisissez le vôtre et testez.
2. Type : *Ubuntu Server*.
3. Réseau : DHCP (IP du type `10.0.2.15` en NAT VirtualBox).
4. Proxy et miroir : par défaut.
5. Stockage : *Use an entire disk*, **sans** LVM pour l'instant.
6. Profil : serveur `ubuntu-devops`, utilisateur `etudiant`, mot de passe robuste.
7. Ubuntu Pro : passer.
8. **Install OpenSSH server** : coché.
9. Snaps : aucun.
10. Fin de l'installation → **Reboot Now**. Quand on demande de retirer le support d'installation, faites **Périphériques → Lecteurs optiques → Retirer le disque**, puis `Entrée`.

Pour **Ubuntu Desktop**, suivez l'assistant graphique : « Installer Ubuntu » → installation par défaut → « Effacer le disque » (le disque virtuel uniquement).

## 6. Premiers contrôles

```bash
lsb_release -a         # Ubuntu 24.04.x LTS
ip -br a               # 10.0.2.15 en NAT
ping -c 2 ubuntu.com   # accès Internet
```

## 7. Additions invité (Guest Additions)

Elles améliorent l'intégration (résolution, presse-papiers, dossiers partagés). Sous Ubuntu :

```bash
sudo apt update
sudo apt install -y virtualbox-guest-utils            # Server
sudo apt install -y virtualbox-guest-x11              # Desktop (affichage + presse-papiers)
sudo reboot
```

> 💡 **Conseil** : pour un serveur en console seule, les Additions ne sont pas indispensables.

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
| Écran noir après installation | EFI / carte graphique | Mettre le contrôleur graphique sur *VMSVGA* |
| « Kernel panic » au démarrage | Mémoire ou type de VM incorrect | Vérifier Type = Linux, 64-bit |
| Pas d'Internet | Adaptateur désactivé | Réseau → Adaptateur 1 → *Activer*, mode NAT |
| Souris capturée | Pas d'Additions | `Ctrl` droit pour libérer la souris |

## Étape suivante

Déroulez la [checklist post-installation](checklist-post-installation.md).
