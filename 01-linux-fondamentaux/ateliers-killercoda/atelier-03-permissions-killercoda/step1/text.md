# Étape 1 : droits et propriétaire d'un fichier

> Sur Killercoda vous êtes déjà **root** : `sudo` n'est pas nécessaire (mais il fonctionne). Sur votre propre serveur, préfixez les commandes d'administration par `sudo`.

Créez un script :

```bash
mkdir -p /tmp/perm && cd /tmp/perm
printf '#!/usr/bin/env bash\necho ok\n' > script.sh
ls -l script.sh
./script.sh
```{{exec}}

(Sans le droit `x` : « Permission denied » pour un utilisateur ordinaire. En **root**, `./script.sh` échoue aussi tant que le bit `x` n'est pas posé.)

## À vous de jouer

1. Donnez à `script.sh` les droits **`750`** (`rwxr-x---` : le propriétaire fait tout, le groupe lit et exécute, les autres rien) ;
2. Changez son propriétaire pour **`nobody`** et son groupe pour **`nogroup`** ;
3. Exécutez-le, puis relisez ses droits.

```bash
chmod 750 script.sh
chown nobody:nogroup script.sh
./script.sh
stat -c '%a %A %U:%G %n' script.sh
```{{exec}}

> Rappel de l'octal : `r=4`, `w=2`, `x=1` ; `7=rwx`, `5=r-x`, `0=---`. Voir le [cours Utilisateurs et permissions](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/cours/04-utilisateurs-permissions.md).

Cliquez sur **Vérifier**.
