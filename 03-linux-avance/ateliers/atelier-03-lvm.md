# Atelier 03 — LVM : volumes logiques, extension à chaud et snapshots

## 🎯 Objectifs

- Créer une pile LVM complète (PV → VG → LV → système de fichiers → montage).
- Agrandir un volume **à chaud**, puis ajouter un disque au groupe.
- Utiliser un snapshot pour restaurer des données supprimées par erreur.
- Rendre le montage permanent via `/etc/fstab` (avec UUID).

## 📋 Prérequis

- Atelier [02](atelier-02-awk-sed-grep.md) terminé.
- Cours lu : [Stockage et LVM](../cours/03-stockage-lvm.md).
- **Aucun disque supplémentaire n'est nécessaire** : l'atelier utilise des fichiers images montés en périphériques *loop*, ce qui évite tout risque pour votre vrai disque.
- Snapshot de la VM pris avant de commencer.

> ⚠️ **Attention** : n'appliquez **jamais** ces commandes sur `/dev/sda` ou le disque système. Ici, toutes les cibles sont `/dev/loopN` créés par vous.

## 🧪 Scénario

*Kamer Logistics* stocke ses documents clients dans `/srv/documents`. Le volume est presque plein et le service ne doit
pas être interrompu. Vous allez reproduire la situation : créer un volume de 200 Mo, le remplir, l'agrandir à
chaud avec un second « disque », et vous protéger d'une suppression accidentelle grâce à un snapshot.

## Étapes

### Étape 1 — Installer les outils et fabriquer deux « disques »

```bash
rpm -q lvm2 || sudo dnf install -y lvm2     # déjà installé dans la VM du cours
sudo mkdir -p /var/lvm-atelier
sudo truncate -s 300M /var/lvm-atelier/disque1.img
sudo truncate -s 300M /var/lvm-atelier/disque2.img
D1=$(sudo losetup -f --show /var/lvm-atelier/disque1.img)
D2=$(sudo losetup -f --show /var/lvm-atelier/disque2.img)
echo "Disques : $D1 $D2"
lsblk $D1 $D2
```

> ❓ **Question 1** : Pourquoi `truncate` crée-t-il instantanément un fichier de 300 Mo ? *(Indice : fichier « creux » / *sparse*.)*

Notez bien les noms `loopN` dans `$D1` et `$D2`. Si vous ouvrez un nouveau terminal, réaffectez-les : `D1=/dev/loopX`.

### Étape 2 — Volumes physiques et groupe

```bash
sudo pvcreate $D1
sudo vgcreate vg_atelier $D1
sudo pvs
sudo vgs
```

> ❓ **Question 2** : Quelle est la taille du groupe `vg_atelier` ? Pourquoi est-elle légèrement inférieure à 300 Mo ?

### Étape 3 — Volume logique, système de fichiers, montage

```bash
sudo lvcreate -n lv_docs -L 200M vg_atelier
sudo mkfs.ext4 -L docs /dev/vg_atelier/lv_docs
sudo mkdir -p /srv/documents
sudo mount /dev/vg_atelier/lv_docs /srv/documents
df -h /srv/documents
lsblk -f $D1
sudo lvs
```

### Étape 4 — Remplir le volume (simulation d'usage)

```bash
sudo chown "$USER": /srv/documents
for i in 1 2 3; do echo "Contrat client $i" > /srv/documents/contrat-$i.txt; done
sudo dd if=/dev/urandom of=/srv/documents/archive.bin bs=1M count=140 status=none
df -h /srv/documents
```

Poursuivons jusqu'à saturation :

```bash
dd if=/dev/zero of=/srv/documents/remplissage.bin bs=1M count=100 2>&1 | tail -2
df -h /srv/documents
```

> ❓ **Question 3** : Quel message d'erreur apparaît quand le volume est plein ? `df -i` aurait-il aussi signalé un problème ?

Libérez : `rm /srv/documents/remplissage.bin`.

### Étape 5 — Montage permanent par UUID

```bash
UUID=$(sudo blkid -s UUID -o value /dev/vg_atelier/lv_docs)
echo "UUID : $UUID"
echo "UUID=$UUID /srv/documents ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo umount /srv/documents
sudo mount -a && echo "fstab OK"
df -h /srv/documents
```

> ❓ **Question 4** : Pourquoi utiliser l'UUID plutôt que `/dev/mapper/vg_atelier-lv_docs` ? Pourquoi toujours tester avec `mount -a` ?

> ⚠️ **Attention** : les périphériques *loop* ne sont pas recréés au redémarrage. Notre ligne `fstab` porte `nofail` pour que la VM démarre quand même. Nous retirerons cette ligne à la fin.

### Étape 6 — Agrandir à chaud avec un second disque

```bash
sudo pvcreate $D2
sudo vgextend vg_atelier $D2
sudo vgs
sudo lvextend -r -L +250M /dev/vg_atelier/lv_docs        # -r : redimensionne aussi l'ext4
df -h /srv/documents
sudo lvs
ls /srv/documents                                         # les données sont toujours là
```

> ❓ **Question 5** : Le volume était monté et utilisé pendant l'extension. Quel serait l'équivalent avec un partitionnement classique ?
> ❓ **Question 6** : Quelle est la différence entre `lvextend -L +250M` et `lvextend -L 250M` ?

### Étape 7 — Snapshot : se protéger d'une erreur

```bash
sudo lvcreate -s -n snap_docs -L 100M /dev/vg_atelier/lv_docs
sudo lvs -o lv_name,lv_size,origin,data_percent
```

Simulez une catastrophe :

```bash
rm -f /srv/documents/contrat-*.txt
ls /srv/documents
```

Retrouvez les fichiers dans le snapshot :

```bash
sudo mkdir -p /mnt/snap
sudo mount -o ro /dev/vg_atelier/snap_docs /mnt/snap
ls /mnt/snap
cp /mnt/snap/contrat-*.txt /srv/documents/
sudo umount /mnt/snap
ls /srv/documents
```

> ❓ **Question 7** : Pourquoi un snapshot de 100 Mo peut-il protéger un volume de 450 Mo ? Que se passe-t-il quand ses 100 Mo sont saturés ?

Supprimez le snapshot :

```bash
sudo lvremove -y vg_atelier/snap_docs
```

### Étape 8 — Aperçu de la réduction (lecture seule, à ne pas exécuter)

Réfléchissez à l'ordre correct pour réduire `lv_docs` à 100 Mo, puis comparez avec le cours :

```text
1. umount
2. e2fsck -f
3. resize2fs  (réduire le système de fichiers)
4. lvreduce   (réduire le volume)
5. mount
```

> ❓ **Question 8** : Que se passerait-il si l'on inversait les étapes 3 et 4 ?

### Étape 9 — Nettoyage complet

```bash
sudo umount /srv/documents
sudo sed -i '/\/srv\/documents/d' /etc/fstab
sudo lvremove -y vg_atelier
sudo vgremove -y vg_atelier
sudo pvremove -y $D1 $D2
sudo losetup -d $D1 $D2
sudo rm -rf /var/lvm-atelier /srv/documents /mnt/snap
grep documents /etc/fstab || echo "fstab propre"
```

## ✅ Validation

- [ ] `sudo lvs` a affiché `lv_docs` avec ~200 Mo, puis ~450 Mo après extension.
- [ ] `df -h /srv/documents` a montré l'augmentation de taille sans démontage.
- [ ] `sudo vgs` montre 2 PV après `vgextend`.
- [ ] Les fichiers `contrat-*.txt` supprimés ont été restaurés depuis le snapshot.
- [ ] `sudo mount -a` n'a produit aucune erreur.
- [ ] Après nettoyage, plus aucune ligne `documents` dans `/etc/fstab` et `losetup -a` ne liste plus vos images.

## 💡 Pour aller plus loin

- **Défi 1** : refaites l'atelier avec **XFS** (`mkfs.xfs`, `xfs_growfs`) et constatez qu'on ne peut pas le réduire.
- **Défi 2** : créez un second LV `lv_logs` avec `-l 100%FREE` et montez-le sur `/var/log-atelier`.
- **Défi 3** : si votre hyperviseur le permet, ajoutez un vrai second disque virtuel à la VM et refaites l'extension avec lui.
- **Défi 4** : testez un RAID 1 avec `mdadm` sur deux périphériques *loop*.

---

## 🏆 Défi du jour

**Objectif** : Répartir un groupe de volumes en **deux volumes logiques**, les monter durablement par **UUID** et valider avec `mount -a`.

**Contexte** : Le serveur doit séparer les données applicatives des journaux pour que ces derniers ne saturent plus les données. Tu disposes d'un « disque » de 400 Mo (un fichier monté en périphérique *loop*).

**Consignes** :
- Crée un fichier de 400 Mo `/var/defi-lvm.img` (avec `truncate`), associe-le à un périphérique *loop* et fabrique un PV, puis un VG `vg_defi`.
- Crée `lv_data` de **150 Mo**, puis `lv_logs` avec **tout l'espace restant** (`-l 100%FREE`).
- Formate-les en ext4 et monte-les sur `/mnt/defi-data` et `/mnt/defi-logs`.
- Ajoute-les à `/etc/fstab` **par UUID** avec l'option `nofail`, démonte-les puis revalide avec `sudo mount -a`.
- Écris dans `~/defi-lvm.txt` la sortie de `sudo lvs -o lv_name,lv_size`.
- Nettoie tout (fstab, montages, LV, VG, PV, loop, fichier image).

**Indices** (à consulter seulement si bloqué) :
- `D=$(sudo losetup -f --show /var/defi-lvm.img)` mémorise le nom du périphérique.
- `sudo lvcreate -n lv_logs -l 100%FREE vg_defi` ; `sudo blkid -s UUID -o value /dev/vg_defi/lv_logs`.
- Teste **toujours** `mount -a` avant de redémarrer.

**Critères de réussite** :
- [ ] `lvs` montre `lv_data` (≈ 150 Mo) et `lv_logs` (le reste, ≈ 240 Mo).
- [ ] `findmnt /mnt/defi-data` et `findmnt /mnt/defi-logs` répondent après `mount -a`.
- [ ] Les deux lignes de `/etc/fstab` utilisent `UUID=` et `nofail`.
- [ ] Après nettoyage, `grep defi /etc/fstab` ne renvoie rien et `losetup -a` ne liste plus l'image.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
rpm -q lvm2 || sudo dnf install -y lvm2     # déjà installé dans la VM du cours
sudo truncate -s 400M /var/defi-lvm.img
D=$(sudo losetup -f --show /var/defi-lvm.img)
sudo pvcreate "$D" && sudo vgcreate vg_defi "$D"

sudo lvcreate -n lv_data -L 150M vg_defi
sudo lvcreate -n lv_logs -l 100%FREE vg_defi
sudo mkfs.ext4 -q /dev/vg_defi/lv_data
sudo mkfs.ext4 -q /dev/vg_defi/lv_logs
sudo mkdir -p /mnt/defi-data /mnt/defi-logs

for lv in data logs; do
  U=$(sudo blkid -s UUID -o value /dev/vg_defi/lv_$lv)
  echo "UUID=$U /mnt/defi-$lv ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
done
sudo mount -a && findmnt /mnt/defi-data && findmnt /mnt/defi-logs
sudo lvs -o lv_name,lv_size | tee ~/defi-lvm.txt

# Nettoyage
sudo umount /mnt/defi-data /mnt/defi-logs
sudo sed -i '/defi-data\|defi-logs/d' /etc/fstab
sudo lvremove -y vg_defi && sudo vgremove -y vg_defi && sudo pvremove -y "$D"
sudo losetup -d "$D" && sudo rm /var/defi-lvm.img
```

`-l 100%FREE` alloue **tout l'espace libre** du groupe ; l'UUID est stable alors que le nom du périphérique ne l'est pas ; `nofail` évite un démarrage bloqué si le volume est absent.

</details>

---

Atelier suivant : [Durcissement d'un serveur](atelier-04-durcissement-serveur.md).
