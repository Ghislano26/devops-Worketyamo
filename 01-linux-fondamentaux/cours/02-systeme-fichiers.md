# Le système de fichiers Linux

> 🐧 **Note Red Hat**
> Ce cours utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.

## Pourquoi ce cours ?

Sous Linux, **tout est fichier** : documents, périphériques, processus, configuration. Comprendre
comment l'arborescence est organisée vous évite de chercher à l'aveugle, et comprendre
comment un fichier est réellement stocké (inodes, liens) vous permet de diagnostiquer des
pannes classiques comme « disque plein alors qu'il reste de la place ».

## 1. Une arborescence unique

Contrairement à Windows (`C:\`, `D:\`), Linux possède **une seule racine**, `/`. Tous les disques, clés USB et partitions sont **montés** (rattachés) quelque part dans cet arbre.

```text
/
├── bin  → /usr/bin   (lien symbolique : commandes essentielles)
├── boot              noyau, chargeur de démarrage (GRUB)
├── dev               fichiers de périphériques (sda, null, tty)
├── etc               configuration du système (texte)
├── home              dossiers personnels des utilisateurs
│   └── etudiant
├── lib → /usr/lib    bibliothèques partagées
├── media, mnt        points de montage (supports amovibles, temporaires)
├── opt               logiciels tiers autonomes
├── proc              vue du noyau : processus, mémoire (pseudo-FS)
├── root              dossier personnel de root
├── run               données volatiles depuis le démarrage (tmpfs)
├── sbin → /usr/sbin  commandes d'administration
├── srv               données servies (web, FTP)
├── sys               vue du noyau : périphériques et pilotes (pseudo-FS)
├── tmp               fichiers temporaires
├── usr               programmes et bibliothèques (majorité du système)
└── var               données variables : logs, caches, bases, spool
```

Cette organisation suit le standard **FHS** (*Filesystem Hierarchy Standard*).

| Répertoire | À y chercher |
|---|---|
| `/etc` | Fichiers de configuration (`/etc/ssh/sshd_config`, `/etc/hosts`) |
| `/var/log` | Journaux (`messages`, `secure` ; sous Ubuntu : `syslog`, `auth.log`) |
| `/home/<user>` | Vos documents et vos fichiers de configuration cachés (`.bashrc`) |
| `/tmp` | Fichiers temporaires, vidés au redémarrage ou périodiquement |
| `/proc`, `/sys` | Informations du noyau en temps réel (ne sont pas sur disque) |
| `/dev` | Périphériques : `/dev/null` (trou noir), `/dev/zero`, `/dev/sda` |

> 💡 **Conseil** : `man hier` décrit la hiérarchie du système de fichiers sur votre machine.

## 2. Chemins absolus et relatifs

- **Absolu** : commence par `/`. Valable partout. `/etc/hosts`
- **Relatif** : part du répertoire courant. `../etc/hosts`, `./script.sh`

| Symbole | Signification |
|---|---|
| `.` | Répertoire courant |
| `..` | Répertoire parent |
| `~` | Votre dossier personnel (`/home/etudiant`) |
| `-` | Répertoire précédent (avec `cd -`) |

## 3. Types de fichiers

Le premier caractère de `ls -l` indique le type :

```bash
ls -l /etc/hosts /etc /dev/null /dev/sda /bin
```

| Caractère | Type | Exemple |
|---|---|---|
| `-` | Fichier ordinaire | `/etc/hosts` |
| `d` | Répertoire | `/etc` |
| `l` | Lien symbolique | `/bin → usr/bin` |
| `c` | Périphérique caractère | `/dev/null`, `/dev/tty` |
| `b` | Périphérique bloc | `/dev/sda` |
| `s` | Socket | `/run/systemd/private` |
| `p` | Tube nommé (FIFO) | créé par `mkfifo` |

La commande `file` détermine le contenu réel (pas l'extension) :

```bash
file /bin/ls /etc/hosts /usr/share/doc
```

## 4. Fonctionnement interne : inodes

Un fichier se compose de deux éléments distincts :

1. Des **données** (les blocs sur le disque) ;
2. Un **inode** (*index node*) : une fiche de métadonnées contenant le propriétaire, les permissions, la taille, les dates, et les pointeurs vers les blocs de données.

> 📌 **À retenir** : **le nom du fichier n'est pas dans l'inode.** Le nom est stocké dans le **répertoire**,
> qui est simplement une table associant un nom à un numéro d'inode.

```text
Répertoire /home/etudiant              Inodes                      Blocs de données
┌───────────────┬────────┐         ┌──────────────────┐        ┌───────────────┐
│ notes.txt     │ 131074 │ ──────► │ inode 131074     │ ─────► │ "Bonjour..."  │
│ copie.txt     │ 131074 │ ──────► │ droits, taille,  │        └───────────────┘
│ rapport.pdf   │ 131090 │         │ nb de liens = 2  │
└───────────────┴────────┘         └──────────────────┘
```

```bash
ls -i                    # affiche les numéros d'inodes
stat notes.txt           # affiche toutes les métadonnées de l'inode
df -i                    # utilisation des inodes par système de fichiers
```

> ⚠️ **Attention** : un système de fichiers peut être « plein » parce qu'il n'a plus d'**inodes** libres (des millions de petits fichiers), alors que `df -h` montre de la place. Vérifiez toujours `df -i`.

### Les timestamps

`stat` montre trois dates : **atime** (dernier accès), **mtime** (dernière modification du contenu), **ctime** (dernier changement de l'inode : droits, nom…).

## 5. Liens physiques et liens symboliques

```bash
echo "contenu" > original.txt
ln original.txt lien-dur.txt         # lien physique (hard link)
ln -s original.txt lien-sym.txt      # lien symbolique
ls -li                               # comparez les numéros d'inodes
```

| | Lien physique | Lien symbolique |
|---|---|---|
| Inode | **Même** inode que l'original | Inode propre, contenant un chemin |
| Si l'original est supprimé | Le contenu reste accessible | Le lien est **cassé** (*dangling*) |
| Traverse les systèmes de fichiers | Non | Oui |
| Peut cibler un répertoire | Non | Oui |

Le fichier n'est réellement supprimé que lorsque son **compteur de liens** tombe à 0 **et** qu'aucun processus ne l'a plus ouvert.

## 6. Systèmes de fichiers, partitions et montage

Un disque est découpé en **partitions**. Chacune reçoit un **système de fichiers** (ext4, xfs, btrfs…) qui organise les données. Ubuntu utilise **ext4** par défaut ; **Rocky/RHEL utilisent XFS** par défaut, et la VM du cours est formatée en **ext4** (installation par kickstart).

```bash
lsblk                     # disques et partitions sous forme d'arbre
lsblk -f                  # + type de FS, UUID, point de montage
df -hT                    # espace utilisé par FS monté
findmnt /                 # détails du montage de /
mount | grep ext4         # systèmes ext4 montés
cat /etc/fstab            # montages permanents au démarrage
```

```text
Disque /dev/sda (40 Go)
├─ sda1  1 Go   /boot   (ext4)
├─ sda2  2 Go   [SWAP]
└─ sda3  37 Go  /       (ext4)
```

### Pseudo-systèmes de fichiers

`/proc`, `/sys`, `/dev`, `/run` ne résident pas sur le disque : le noyau les génère en mémoire.

```bash
cat /proc/cpuinfo | head      # informations processeur
cat /proc/meminfo | head -3   # mémoire
cat /proc/version             # version du noyau
```

## 7. Fichiers cachés et jokers (*globbing*)

Un fichier dont le nom commence par `.` est **caché** : `ls -a` le montre (`.bashrc`, `.ssh`).

Le shell développe les **jokers** avant d'exécuter la commande :

| Joker | Signification | Exemple |
|---|---|---|
| `*` | Zéro ou plusieurs caractères | `ls *.txt` |
| `?` | Exactement un caractère | `ls fichier?.txt` |
| `[abc]` | Un caractère parmi la liste | `ls log[123].txt` |
| `[a-z]` | Un caractère dans l'intervalle | `ls [a-c]*` |
| `{a,b}` | Développement d'accolades | `touch f{1,2,3}.txt` |

> 💡 **Conseil** : avant un `rm *.log`, faites d'abord `ls *.log` pour voir ce que le joker va sélectionner.

## 8. Espaces et caractères spéciaux dans les noms

Linux distingue majuscules et minuscules (`Notes.txt` ≠ `notes.txt`). Les espaces posent problème : utilisez des guillemets ou un antislash.

```bash
touch "mon fichier.txt"
ls mon\ fichier.txt
```

Conseil d'hygiène : nommez vos fichiers en minuscules, avec des tirets (`rapport-2025.txt`).

## Résumé

- Une **seule racine** `/` ; les périphériques sont **montés** dans l'arbre.
- Le **FHS** définit le rôle de `/etc`, `/var`, `/home`, `/usr`, `/tmp`…
- Un fichier = **inode** (métadonnées) + **blocs** (données) ; le nom vit dans le répertoire.
- Lien physique : même inode. Lien symbolique : raccourci vers un chemin.
- `df -h` (espace) et `df -i` (inodes) ; `lsblk` pour voir disques et partitions.
- `/proc` et `/sys` sont des vues du noyau, non stockées sur disque.

## Pour aller plus loin

- `man 7 inode`, `man hier`, `man ext4`.
- Autres systèmes de fichiers : XFS, Btrfs, ZFS ; journalisation ext4 (`dumpe2fs`).
- Prochain cours : [Navigation et commandes de base](03-navigation-commandes-base.md).
- Atelier associé : [Atelier 01 — Navigation](../ateliers/atelier-01-navigation.md).
