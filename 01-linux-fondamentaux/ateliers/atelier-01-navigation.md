# Atelier 01 — Navigation dans le système de fichiers

## 🎯 Objectifs

- Se repérer dans l'arborescence Linux avec `pwd`, `cd`, `ls`, `tree`.
- Distinguer chemins absolus et relatifs.
- Lire des métadonnées (`ls -l`, `stat`, inodes) et identifier les types de fichiers.
- Explorer `/etc`, `/var/log`, `/proc` et `/dev`.

## 📋 Prérequis

- VM Rocky Linux 9 prête ([Guide de l'environnement](../../GUIDE-ENVIRONNEMENT.md), [module 00](../../00-installation-ubuntu-vm/README.md)) et snapshot pris.
- Cours lus : [Introduction](../cours/01-introduction-linux.md), [Système de fichiers](../cours/02-systeme-fichiers.md), [Navigation](../cours/03-navigation-commandes-base.md) (sections 1 à 3).

## 🧪 Scénario

Vous êtes nouvel administrateur chez *Kamer Logistics*. Le serveur `devops-lab` vous est confié, mais
personne n'a documenté son contenu. Votre première mission : **cartographier** le serveur et rédiger un
rapport d'inventaire de quelques lignes.

## Étapes

### Étape 1 — Où suis-je ?

```bash
whoami
hostname
pwd
```

Vous êtes dans votre dossier personnel. 

> ❓ **Question 1** : Pourquoi `pwd` affiche-t-il `/home/<votre-nom>` et non `~` ?
> *(Indice : `~` est une abréviation interprétée par le shell, `pwd` affiche le chemin réel.)*

### Étape 2 — Explorer la racine

```bash
cd /
ls
ls -l
tree -L 1 /
```

Si `tree` est absent : `sudo dnf install -y tree`.

> ❓ **Question 2** : `/bin` est un lien symbolique. Vers quoi pointe-t-il ? Quelle commande l'a révélé ?

### Étape 3 — Chemins absolus et relatifs

```bash
cd /var/log
pwd
cd ../lib                  # chemin relatif
pwd
cd /etc/ssh                # chemin absolu
pwd
cd -                       # retour au dossier précédent
pwd
cd ~                       # puis retour à la maison
pwd
```

> ❓ **Question 3** : Depuis `/var/log`, quel chemin relatif mène à `/etc/ssh` ? Écrivez-le puis testez-le.

### Étape 4 — Lire une ligne `ls -l`

```bash
ls -la /etc | head -15
ls -lh /var/log
ls -lt /var/log | head -5       # les plus récents d'abord
ls -lS /usr/bin | head -5       # les plus gros d'abord
```

Choisissez une ligne et décodez-la : type, droits, propriétaire, groupe, taille, date.

> ❓ **Question 4** : Pourquoi `ls -a` montre-t-il toujours deux entrées `.` et `..` ?

### Étape 5 — Les types de fichiers

```bash
ls -l /etc/hosts        # fichier ordinaire
ls -ld /etc             # répertoire
ls -l /dev/null /dev/tty /dev/sda* 2>/dev/null   # périphériques c et b
file /bin/ls /etc/hosts /etc
```

Relevez un exemple de chaque type : `-`, `d`, `l`, `c`, `b`.

> ❓ **Question 5** : Pourquoi `/dev/null` est-il un périphérique de type `c` (caractère) et `/dev/sda` de type `b` (bloc) ?

### Étape 6 — Inodes

```bash
cd ~
echo "inventaire" > test-inode.txt
ls -i test-inode.txt
stat test-inode.txt
df -i /
```

Notez : le numéro d'inode, le nombre de liens, les trois dates (Access, Modify, Change).

> ❓ **Question 6** : Que se passerait-il si le pourcentage `IUse%` de `df -i` atteignait 100 % alors que `df -h` indique encore de la place ?

### Étape 7 — Le monde de `/proc` et `/etc`

```bash
head -n 5 /proc/cpuinfo
grep -E "MemTotal|MemFree" /proc/meminfo
cat /proc/version
cat /etc/os-release
ls /etc | wc -l
```

> ❓ **Question 7** : Ces fichiers de `/proc` ont une taille de 0 octet (`ls -l /proc/version`) mais ont du contenu. Pourquoi ?

### Étape 8 — Rédiger le rapport d'inventaire

```bash
mkdir -p ~/rapports
{
  echo "=== Inventaire du serveur $(hostname) ==="
  echo "Date : $(date)"
  echo "Utilisateur : $(whoami)"
  echo "Système : $(grep PRETTY_NAME /etc/os-release | cut -d= -f2)"
  echo "Noyau : $(uname -r)"
  echo "Éléments dans /etc : $(ls /etc | wc -l)"
  echo "Disque / : $(df -h / | tail -1)"
} > ~/rapports/inventaire.txt
cat ~/rapports/inventaire.txt
```

## ✅ Validation

Vérifiez chaque point :

- [ ] Vous savez dire où vous êtes sans regarder le prompt (`pwd`).
- [ ] Vous avez navigué avec un chemin absolu **et** un chemin relatif.
- [ ] Vous avez identifié un fichier de chacun des types `-`, `d`, `l`, `c`, `b`.
- [ ] Vous avez relevé le numéro d'inode de `test-inode.txt` et la valeur de `IUse%`.
- [ ] `~/rapports/inventaire.txt` existe et contient 7 lignes.

Contrôle automatique :

```bash
[ "$(wc -l < ~/rapports/inventaire.txt)" -eq 7 ] && echo "OK rapport" || echo "KO rapport"
```

*(Le rapport compte 7 lignes : un titre et 6 informations.)*

## 💡 Pour aller plus loin

- **Défi 1** : trouvez, avec `ls` et `tree`, les 3 plus gros dossiers de `/usr` (`du -sh /usr/* 2>/dev/null | sort -h | tail -3`).
- **Défi 2** : créez un chemin de 5 niveaux en une commande (`mkdir -p`) puis revenez à votre dossier personnel en une seule commande `cd`.
- **Défi 3** : expliquez la différence entre `/run` et `/tmp` après avoir exploré `df -h /run /tmp`.
- **Défi 4** : trouvez tous les liens symboliques de `/` : `find / -maxdepth 1 -type l -ls`.

---

## 🏆 Défi du jour

**Objectif** : Produire en quelques minutes un petit rapport sur le contenu de `/var/log`, uniquement avec `ls`, `find`, `grep` et `wc`.

**Contexte** : Le responsable sécurité doit intervenir sur ton serveur et veut savoir, avant de se connecter, combien de journaux `.log` existent, lequel est le plus gros et où se trouve le journal des paquets de DNF (`dnf.log`).

**Consignes** :
- Crée le fichier `~/defi-j1.txt` **sans l'écrire à la main** : chaque ligne doit être produite par une commande.
- Ligne 1 : `Nombre de fichiers .log : N` (fichiers ordinaires dont le nom se termine par `.log`, dans `/var/log` et ses sous-dossiers).
- Ligne 2 : `Plus gros fichier : ` suivi de la ligne `ls -l` du fichier ordinaire le plus volumineux **directement** dans `/var/log`.
- Ligne 3 : `Chemin de dnf.log : ` suivi du chemin absolu trouvé avec `find`.

**Indices** (à consulter seulement si bloqué) :
- `find /var/log -type f -name '*.log' 2>/dev/null | wc -l` compte les fichiers (`2>/dev/null` masque les « Permission denied »).
- `ls -lS` trie par taille décroissante ; `grep '^-'` ne garde que les fichiers ordinaires (premier caractère `-`) ; `head -n 1` garde le premier.
- Pour regrouper plusieurs `echo` dans un seul fichier : `{ echo … ; echo … ; } > fichier`.

**Critères de réussite** :
- [ ] `~/defi-j1.txt` existe et contient exactement 3 lignes.
- [ ] La ligne 1 contient un nombre supérieur ou égal à 1.
- [ ] La ligne 3 se termine par `/var/log/dnf.log`.
- [ ] Tu as produit le fichier avec des commandes (pas de nombre écrit à la main).

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
{
  echo "Nombre de fichiers .log : $(find /var/log -type f -name '*.log' 2>/dev/null | wc -l)"
  echo "Plus gros fichier : $(ls -lS /var/log | grep '^-' | head -n 1)"
  echo "Chemin de dnf.log : $(find /var/log -name dnf.log 2>/dev/null)"
} > ~/defi-j1.txt
cat ~/defi-j1.txt
wc -l ~/defi-j1.txt        # 3
```

`$(…)` insère la sortie d'une commande dans le texte ; `{ … } > fichier` redirige l'ensemble des trois `echo` vers un seul fichier.

</details>

---

Atelier suivant : [Gestion de fichiers](atelier-02-gestion-fichiers.md).
