# Stockage Linux et LVM

## Pourquoi ce cours ?

« Le disque est plein ! » est l'un des incidents les plus fréquents. Sans LVM, agrandir une partition
oblige à arrêter le service, repartitionner, parfois tout restaurer. Avec **LVM** (*Logical Volume Manager*), on
agrandit un volume **à chaud**, on ajoute un disque, on prend des instantanés. Comprendre les couches du
stockage (bloc → partition → LVM → système de fichiers) est indispensable pour intervenir sereinement.

## 1. Les couches du stockage

```text
Application / fichiers
        │
  Système de fichiers (ext4, xfs)      ← mkfs
        │
  Volume logique (LV)                  ← lvcreate
        │
  Groupe de volumes (VG)               ← vgcreate     (« réservoir » d'espace)
        │
  Volume physique (PV)                 ← pvcreate     (disque ou partition préparé)
        │
  Partition / disque brut (/dev/sdb)
        │
  Matériel
```

| Terme | Définition |
|---|---|
| **PV** (Physical Volume) | Disque ou partition initialisé pour LVM |
| **VG** (Volume Group) | Ensemble de PV formant un pool d'espace |
| **LV** (Logical Volume) | « Partition » souple découpée dans un VG |
| **PE** (Physical Extent) | Plus petit bloc d'allocation (4 Mio par défaut) |

## 2. Observer le stockage existant

```bash
lsblk                         # arbre des disques, partitions, LV
lsblk -f                      # + systèmes de fichiers, UUID
sudo fdisk -l                 # tables de partitions
df -hT                        # espace par système de fichiers monté
findmnt                       # arbre des montages
blkid                         # UUID et types
cat /etc/fstab                # montages permanents
```

Les disques apparaissent sous la forme `/dev/sda`, `/dev/sdb` (SATA/SCSI/virtio) ou `/dev/nvme0n1`. Les partitions : `sda1`, `sda2`.

> ⚠️ **Attention** : avant toute opération sur un disque, **identifiez-le avec `lsblk`** : une erreur de lettre (`sda` au lieu de `sdb`) peut détruire votre système.

## 3. Partitionnement : MBR et GPT

| | MBR | GPT |
|---|---|---|
| Taille max d'un disque | 2 To | 9,4 Zo |
| Partitions | 4 primaires | 128 |
| Démarrage | BIOS | UEFI (et BIOS) |

```bash
sudo parted /dev/sdb --script mklabel gpt
sudo parted /dev/sdb --script mkpart primary 0% 100%
# ou, plus interactif : sudo fdisk /dev/sdb   (n = nouvelle, t = type, w = écrire)
```

## 4. Systèmes de fichiers et montage

```bash
sudo mkfs.ext4 /dev/sdb1           # crée un ext4 (formate : efface les données !)
sudo mkfs.xfs  /dev/sdb1           # XFS : agrandissable, non réductible
sudo mkdir -p /mnt/donnees
sudo mount /dev/sdb1 /mnt/donnees
sudo umount /mnt/donnees
```

| | ext4 | XFS |
|---|---|---|
| Agrandir à chaud | ✅ | ✅ |
| Réduire | ✅ (démonté) | ❌ |
| Usage | Général (défaut Ubuntu) | Gros fichiers, serveurs |

### Montage permanent avec `/etc/fstab`

Utilisez l'**UUID**, plus stable que `/dev/sdb1` (qui peut changer d'ordre).

```bash
sudo blkid /dev/sdb1
# /etc/fstab :
# UUID=xxxxxxxx-xxxx  /mnt/donnees  ext4  defaults,nofail  0  2
sudo mount -a                       # teste fstab : toute erreur ici avant le reboot
```

Les six colonnes : *source*, *point de montage*, *type*, *options*, *dump* (0), *fsck* (0 = jamais, 1 = racine, 2 = autres).

> ⚠️ **Attention** : une erreur dans `/etc/fstab` peut empêcher le démarrage. Utilisez `nofail` pour les disques secondaires et lancez **`sudo mount -a`** avant de redémarrer.

## 5. LVM : mise en pratique

### Création de A à Z

```bash
sudo apt install -y lvm2
sudo pvcreate /dev/sdb /dev/sdc            # initialise deux disques en PV
sudo vgcreate vg_data /dev/sdb /dev/sdc    # crée le groupe de volumes
sudo lvcreate -n lv_web  -L 5G  vg_data    # volume de 5 Go
sudo lvcreate -n lv_logs -l 50%FREE vg_data   # 50 % de l'espace libre
sudo mkfs.ext4 /dev/vg_data/lv_web
sudo mkdir -p /srv/web
sudo mount /dev/vg_data/lv_web /srv/web
```

### Inspecter

```bash
sudo pvs ; sudo vgs ; sudo lvs             # résumés
sudo pvdisplay ; sudo vgdisplay ; sudo lvdisplay   # détails
lsblk
```

### Agrandir à chaud (le grand intérêt de LVM)

```bash
sudo lvextend -L +2G /dev/vg_data/lv_web          # +2 Go au volume
sudo resize2fs /dev/vg_data/lv_web                # agrandit l'ext4 pour occuper l'espace
# ou en une commande :
sudo lvextend -r -L +2G /dev/vg_data/lv_web       # -r : redimensionne aussi le FS
sudo xfs_growfs /srv/web                          # pour du XFS (point de montage)
```

### Ajouter un disque au groupe

```bash
sudo pvcreate /dev/sdd
sudo vgextend vg_data /dev/sdd
sudo vgs                                           # l'espace libre (VFree) augmente
```

### Réduire (ext4 seulement, démonté, avec sauvegarde)

```bash
sudo umount /srv/web
sudo e2fsck -f /dev/vg_data/lv_web
sudo resize2fs /dev/vg_data/lv_web 3G       # d'abord réduire le FS...
sudo lvreduce -L 3G /dev/vg_data/lv_web     # ...puis le volume
```

> ⚠️ **Attention** : réduire dans le **mauvais ordre** (volume avant système de fichiers) détruit les données. Faites toujours une sauvegarde avant. Retenez : *agrandir = volume puis FS ; réduire = FS puis volume.*

## 6. Instantanés (snapshots) LVM

Un snapshot fige l'état d'un volume en utilisant le **copy-on-write** : seules les modifications ultérieures consomment de l'espace.

```bash
sudo lvcreate -s -n snap_web -L 1G /dev/vg_data/lv_web
sudo mkdir -p /mnt/snap && sudo mount -o ro /dev/vg_data/snap_web /mnt/snap
# ... copier/sauvegarder depuis /mnt/snap ...
sudo umount /mnt/snap
sudo lvremove vg_data/snap_web
sudo lvconvert --merge vg_data/snap_web      # alternative : restaurer l'état du volume d'origine
```

> 📌 **À retenir** : un snapshot n'est **pas une sauvegarde** : il dépend du volume source. Si l'espace réservé (`-L 1G`) est saturé, le snapshot devient invalide.

## 7. Diagnostic d'un disque plein

```bash
df -h                                  # quel FS est plein ?
df -i                                  # inodes ?
sudo du -xh / --max-depth=1 2>/dev/null | sort -h | tail     # gros répertoires (-x : reste sur ce FS)
sudo ncdu -x /                         # exploration interactive
sudo lsof +L1                          # fichiers supprimés mais encore ouverts
```

> 💡 **Conseil** : si `df` indique « plein » mais que `du` trouve moins, un processus garde probablement ouvert un gros fichier **supprimé** (`lsof +L1`). Redémarrez le service concerné pour libérer l'espace.

## 8. RAID, swap et fichiers-disque (aperçu)

- **RAID** (`mdadm`) : RAID 1 (miroir), RAID 5 (parité), RAID 10 : redondance contre la panne d'un disque. **Ce n'est pas une sauvegarde.**
- **Swap** : espace disque servant de mémoire de secours.

```bash
swapon --show ; free -h
sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```

- **Disque virtuel dans un fichier** (excellent pour s'entraîner sans disque physique) :

```bash
sudo dd if=/dev/zero of=/var/disque1.img bs=1M count=512
sudo losetup -f --show /var/disque1.img        # affiche /dev/loopN
```

## 9. Sauvegarde : rappel des bases

Règle **3-2-1** : 3 copies, sur 2 supports différents, dont 1 hors site.

```bash
tar czf /backup/web-$(date +%F).tar.gz -C /srv web
rsync -aH --delete /srv/web/ /backup/web/
```

## Résumé

- Couches : disque → **PV** → **VG** → **LV** → système de fichiers → montage.
- `lsblk`, `df -h`, `df -i` pour observer ; **UUID** dans `/etc/fstab` ; `mount -a` pour tester.
- LVM : `pvcreate` → `vgcreate` → `lvcreate` → `mkfs` → `mount`.
- Agrandir à chaud : `lvextend -r` ; réduire : seulement ext4, démonté, FS d'abord.
- Snapshots LVM : copy-on-write, **pas** une sauvegarde.
- Disque plein : `df`, `du`, `ncdu`, `lsof +L1`.

## Pour aller plus loin

- `man lvm`, `man lvcreate`, `man fstab`, `man mdadm`.
- LVM thin provisioning, chiffrement LUKS (`cryptsetup`), Btrfs/ZFS.
- Atelier associé : [LVM](../ateliers/atelier-03-lvm.md).
- Cours suivant : [Sécurité et durcissement](04-securite-durcissement.md).
