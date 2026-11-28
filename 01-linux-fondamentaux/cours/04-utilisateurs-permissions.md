# Utilisateurs, groupes et permissions

> 🐧 **Note Red Hat**
> Ce cours utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.

## Pourquoi ce cours ?

Linux est un système **multi-utilisateur** : chaque fichier et chaque processus appartient à
quelqu'un. Les permissions sont la première ligne de défense d'un serveur. Une mauvaise
permission (`chmod 777`) est l'une des erreurs de sécurité les plus courantes. Ce cours explique
le modèle, son fonctionnement interne et les cas particuliers (`setuid`, `sudo`, PAM).

## 1. Utilisateurs et groupes

Chaque utilisateur possède un **UID** (nombre) ; chaque groupe un **GID**. Le noyau ne connaît que
des nombres : les noms sont une commodité.

| Plage d'UID | Type |
|---|---|
| 0 | `root`, le super-utilisateur |
| 1–999 | Comptes **système** (services : `apache`, `sshd`, `chrony`…) |
| 1000+ | Comptes **humains** |

```bash
id                  # mon UID, GID et groupes
id root
whoami
groups              # mes groupes
who                 # qui est connecté
last -5             # dernières connexions
```

### Les fichiers de comptes

```bash
cat /etc/passwd     # comptes : nom:x:UID:GID:commentaire:home:shell
cat /etc/group      # groupes : nom:x:GID:membres
sudo cat /etc/shadow  # empreintes de mots de passe (lisible par root uniquement)
```

```text
etudiant:x:1000:1000:Etudiant:/home/etudiant:/bin/bash
│        │ │    │    │        │              └ shell de connexion
│        │ │    │    │        └ répertoire personnel
│        │ │    │    └ commentaire (GECOS)
│        │ │    └ GID principal
│        │ └ UID
│        └ « x » : le mot de passe est dans /etc/shadow
└ nom
```

> 📌 **À retenir** : `/etc/passwd` est lisible par tous (les programmes en ont besoin pour convertir UID ↔ nom). Les **empreintes** de mots de passe sont dans `/etc/shadow`, lisible uniquement par root. Un shell `/usr/sbin/nologin` interdit la connexion interactive (comptes de service).

## 2. Gérer les utilisateurs et les groupes

```bash
sudo useradd -m -s /bin/bash alice    # crée le compte et son home (-m), avec le shell (-s)
sudo passwd alice                     # définit le mot de passe (étape distincte de la création)
sudo useradd -m -s /bin/bash bob
sudo passwd bob
sudo usermod -aG wheel,developpeurs bob  # ajoute aux groupes (-a ! sinon écrase) ; « wheel » = droits sudo
sudo groupadd developpeurs
sudo usermod -L bob                   # verrouille le compte
sudo usermod -U bob                   # déverrouille
sudo userdel -r bob                   # supprime le compte et son home
sudo chage -l alice                   # politique d'expiration du mot de passe
```

> 💡 **Ubuntu vs Rocky** : Debian/Ubuntu proposent `adduser` / `deluser` (interactifs, plus conviviaux). Sous Rocky/RHEL, **`useradd` / `userdel` / `passwd`** sont la méthode normale : `useradd` crée le compte mais **pas le mot de passe** (compte verrouillé tant que `passwd` n'a pas été exécuté). Le groupe qui donne les droits `sudo` s'appelle **`wheel`** (et non `sudo`) : la ligne `%wheel ALL=(ALL) ALL` de `/etc/sudoers` l'autorise. Dans la VM du cours, `vagrant` est dans `wheel` et dispose en plus d'un `sudo` **sans mot de passe** (`/etc/sudoers.d/vagrant`).

Les modifications de groupes ne s'appliquent qu'à une **nouvelle session** : déconnectez-vous et reconnectez-vous, ou utilisez `newgrp`.

## 3. Le modèle de permissions

Chaque fichier a **un propriétaire**, **un groupe** et trois ensembles de droits.

```text
 - rwx r-x r--
 │ │   │   └─ autres (others)
 │ │   └──── groupe (group)
 │ └──────── propriétaire (user)
 └────────── type
```

| Droit | Sur un fichier | Sur un répertoire |
|---|---|---|
| `r` (4) | Lire le contenu | **Lister** les noms (`ls`) |
| `w` (2) | Modifier le contenu | **Créer/supprimer/renommer** des entrées |
| `x` (1) | Exécuter comme programme | **Traverser** (`cd`, accéder aux éléments) |

> ⚠️ **Attention** : pour **supprimer** un fichier, c'est le droit `w` sur le **répertoire** qui compte, pas sur le fichier. Un fichier en lecture seule peut être supprimé si vous pouvez écrire dans son dossier.

Le noyau applique la règle suivante : si vous êtes le propriétaire, seuls les droits « user » comptent ; sinon, si vous êtes dans le groupe, les droits « group » ; sinon « others ». Root contourne ces contrôles (sauf cas d'attributs immuables).

## 4. Modifier les permissions : `chmod`

### Notation octale

Chaque droit vaut un poids : `r=4`, `w=2`, `x=1`. On additionne par ensemble.

| Octal | Binaire | Droits |
|---|---|---|
| 7 | 111 | `rwx` |
| 6 | 110 | `rw-` |
| 5 | 101 | `r-x` |
| 4 | 100 | `r--` |
| 0 | 000 | `---` |

```bash
chmod 644 notes.txt      # rw-r--r--  : fichier de données classique
chmod 755 script.sh      # rwxr-xr-x  : programme / dossier public
chmod 600 cle-privee     # rw-------  : secret (obligatoire pour les clés SSH)
chmod 700 ~/.ssh         # rwx------
```

### Notation symbolique

```bash
chmod u+x script.sh      # ajoute x au propriétaire (u=user, g=group, o=others, a=all)
chmod g-w fichier        # retire w au groupe
chmod o= fichier         # retire tout aux autres
chmod a+r fichier        # lecture pour tous
chmod -R u=rwX,g=rX,o= projet/   # récursif ; X = x seulement sur dossiers/ fichiers déjà exécutables
```

## 5. Changer le propriétaire : `chown` et `chgrp`

```bash
sudo chown alice fichier           # change le propriétaire
sudo chown alice:developpeurs fichier   # propriétaire et groupe
sudo chown -R apache: /var/www     # récursif ; « : » seul = groupe de connexion (utilisateur du serveur web : apache)
sudo chgrp developpeurs projet/
```

## 6. Le `umask`

Le `umask` définit les droits **retirés** à la création d'un fichier. Les valeurs de base sont 666 pour les fichiers et 777 pour les dossiers.

```bash
umask          # 0002 pour un utilisateur ordinaire (groupe privé, comme sous Ubuntu), 0022 pour root
```

Avec `umask 022` : fichier = 666 − 022 = **644** ; dossier = 777 − 022 = **755**.
Avec `umask 077` : fichier **600**, dossier **700** (très restrictif).

## 7. Permissions spéciales

| Bit | Octal | Effet sur fichier exécutable | Effet sur répertoire |
|---|---|---|---|
| **setuid** (`s` chez user) | 4000 | S'exécute avec les droits du **propriétaire** | — |
| **setgid** (`s` chez group) | 2000 | S'exécute avec les droits du **groupe** | Les nouveaux fichiers héritent du **groupe** du dossier |
| **sticky** (`t`) | 1000 | — | Seul le propriétaire du fichier (ou root) peut supprimer |

```bash
ls -l /usr/bin/passwd      # -rwsr-xr-x : setuid root
ls -ld /tmp                # drwxrwxrwt : sticky bit
chmod 2775 /srv/projet     # setgid : les fichiers héritent du groupe du projet
chmod +t /srv/partage      # sticky
```

> 📌 **À retenir** : `passwd` est *setuid root* : c'est ainsi qu'un utilisateur ordinaire peut modifier `/etc/shadow` via ce programme précis. Ces binaires sont une cible d'attaque privilégiée. Auditez-les : `find / -perm -4000 -type f 2>/dev/null`.

## 8. `sudo` : élévation contrôlée

`sudo` exécute **une commande** avec les droits d'un autre utilisateur (root par défaut), après authentification **de l'utilisateur appelant**, et journalise l'action dans `/var/log/secure` (Ubuntu : `/var/log/auth.log`) et dans le journal systemd (`journalctl _COMM=sudo`).

```bash
sudo dnf check-update    # une commande en root
sudo -i                  # shell root interactif (à éviter)
sudo -u alice ls /home/alice   # exécuter en tant qu'un autre utilisateur
sudo -l                  # que m'est-il autorisé de faire ?
su - alice               # se connecter comme alice (demande le mot de passe d'alice)
```

La configuration est dans `/etc/sudoers` et `/etc/sudoers.d/`. **N'éditez jamais directement** : utilisez `visudo`, qui vérifie la syntaxe avant d'enregistrer (une erreur peut vous verrouiller hors de sudo).

```bash
sudo visudo -f /etc/sudoers.d/developpeurs
# Contenu possible :
# %developpeurs ALL=(ALL) /usr/bin/systemctl restart nginx
```

La syntaxe est `QUI  OÙ=(COMME_QUI)  COMMANDES`. Le principe du **moindre privilège** conseille de n'autoriser que les commandes nécessaires.

## 9. Fonctionnement interne : PAM

Quand vous vous authentifiez (connexion, `sudo`, `ssh`), les programmes ne vérifient pas eux-mêmes les mots de passe. Ils s'appuient sur **PAM** (*Pluggable Authentication Modules*), une couche modulaire configurée dans `/etc/pam.d/`.

```text
  sudo / sshd / login
          │
          ▼
        PAM  ── /etc/pam.d/sudo ──►  modules : pam_unix (mot de passe),
                                              pam_faillock (verrouillage),
                                              pam_pwquality (complexité)
```

Chaque ligne d'un fichier PAM suit le schéma `type  contrôle  module  [arguments]`. Quatre types : `auth` (qui êtes-vous ?), `account` (compte valide ?), `password` (changement de mot de passe), `session` (ouverture/fermeture de session).

```bash
ls /etc/pam.d/
cat /etc/pam.d/sudo
```

> ⚠️ **Attention** : une erreur dans `/etc/pam.d/` peut vous empêcher de vous connecter. Gardez toujours une session root ouverte pendant vos tests.

## 10. ACL : permissions plus fines

Pour donner des droits à un utilisateur précis sans changer le propriétaire ou le groupe :

```bash
rpm -q acl                           # installé par défaut sur Rocky (sinon : sudo dnf install -y acl)
setfacl -m u:alice:rw fichier.txt    # donne rw à alice
getfacl fichier.txt                  # affiche les ACL
setfacl -x u:alice fichier.txt       # retire l'ACL
```

Un `+` à la fin des droits (`-rw-rw-r--+`) signale la présence d'ACL.

## Résumé

- Un utilisateur = UID ; comptes dans `/etc/passwd`, mots de passe hachés dans `/etc/shadow`.
- Permissions `rwx` pour **propriétaire / groupe / autres** ; sens différent pour fichiers et dossiers.
- `chmod` (octal ou symbolique), `chown`, `chgrp`, `umask`.
- Bits spéciaux : **setuid**, **setgid**, **sticky**.
- `sudo` = élévation ponctuelle et journalisée ; `visudo` pour éditer ; principe du moindre privilège.
- **PAM** centralise l'authentification dans `/etc/pam.d/`.

## Pour aller plus loin

- `man 5 sudoers`, `man pam.conf`, `man 7 credentials`, `man acl`.
- Capabilities Linux (`man 7 capabilities`) : découper les pouvoirs de root.
- **SELinux** (module de sécurité par défaut de Rocky/RHEL) : voir le [cours de durcissement](../../03-linux-avance/cours/04-securite-durcissement.md#8-selinux--contrôle-daccès-obligatoire) ; sous Ubuntu, c'est AppArmor.
- Ateliers : [Permissions](../ateliers/atelier-03-permissions.md). Module suivant : [Processus et services](../../02-linux-intermediaire/cours/01-processus-services.md).
