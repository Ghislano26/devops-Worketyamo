# Atelier 03 — Utilisateurs, groupes et permissions

## 🎯 Objectifs

- Créer des utilisateurs et des groupes.
- Appliquer `chmod`, `chown`, `chgrp` en notation octale et symbolique.
- Construire un répertoire partagé sécurisé (setgid + sticky).
- Configurer une règle `sudo` à moindre privilège avec `visudo`.

## 📋 Prérequis

- Ateliers [01](atelier-01-navigation.md) et [02](atelier-02-gestion-fichiers.md) terminés.
- Cours lu : [Utilisateurs et permissions](../cours/04-utilisateurs-permissions.md).
- Snapshot de la VM pris avant de commencer.

## 🧪 Scénario

*Kamer Logistics* embauche deux développeurs, **alice** et **bob**, et une stagiaire, **clara**. Ils doivent
collaborer dans `/srv/projet` : alice et bob peuvent y écrire, clara peut seulement lire, et personne ne
doit pouvoir supprimer les fichiers d'un autre. Alice doit pouvoir redémarrer un service sans être administratrice complète.

## Étapes

### Étape 1 — Créer comptes et groupes

```bash
sudo groupadd developpeurs
sudo groupadd stagiaires
for u in alice bob clara; do
  sudo useradd -m -s /bin/bash "$u"
  echo "$u:Motdepasse!2025" | sudo chpasswd
done
sudo usermod -aG developpeurs alice
sudo usermod -aG developpeurs bob
sudo usermod -aG stagiaires clara
id alice; id bob; id clara
```

> ❓ **Question 1** : Que se passerait-il si vous aviez écrit `usermod -G developpeurs alice` (sans `-a`) pour un compte déjà membre d'autres groupes ?

> ⚠️ **Attention** : ce mot de passe est un mot de passe d'exercice. Sur un vrai serveur, n'écrivez jamais de mot de passe en clair dans une commande (il finit dans l'historique).

### Étape 2 — Inspecter les fichiers de comptes

```bash
grep -E "^(alice|bob|clara):" /etc/passwd
grep -E "^(developpeurs|stagiaires)" /etc/group
sudo grep "^alice:" /etc/shadow | cut -c1-40
```

> ❓ **Question 2** : Pourquoi la lecture de `/etc/shadow` nécessite-t-elle `sudo` alors que `/etc/passwd` est lisible par tous ?

### Étape 3 — Créer le répertoire partagé

```bash
sudo mkdir -p /srv/projet
sudo chown root:developpeurs /srv/projet
sudo chmod 2770 /srv/projet
ls -ld /srv/projet
```

La sortie doit ressembler à `drwxrws--- 2 root developpeurs …`. Le `s` à la place du `x` du groupe est le bit **setgid**.

> ❓ **Question 3** : Que fait le bit setgid sur un répertoire ? *(Indice : cours, section « Permissions spéciales ».)*

### Étape 4 — Tester l'accès

```bash
sudo -u alice touch /srv/projet/fichier-alice.txt && echo "alice : OK"
sudo -u bob   touch /srv/projet/fichier-bob.txt   && echo "bob : OK"
sudo -u clara ls /srv/projet                      || echo "clara : refusé"
ls -l /srv/projet
```

Observez le **groupe** des fichiers créés : `developpeurs`, hérité grâce au setgid.

> ❓ **Question 4** : Pourquoi `clara` est-elle refusée ? Quel ensemble de droits (user/group/others) s'applique à elle ?

### Étape 5 — Donner la lecture seule à la stagiaire avec une ACL

```bash
sudo apt install -y acl
sudo setfacl -m g:stagiaires:rx /srv/projet
sudo setfacl -d -m g:stagiaires:rx /srv/projet      # ACL par défaut pour les futurs fichiers
getfacl /srv/projet
sudo -u clara ls /srv/projet && echo "clara peut lire"
sudo -u clara touch /srv/projet/x || echo "clara ne peut pas écrire"
```

> ❓ **Question 5** : Pourquoi utiliser une ACL plutôt que d'ajouter `clara` au groupe `developpeurs` ?

### Étape 6 — Empêcher la suppression des fichiers d'autrui (sticky bit)

Sans sticky bit, bob peut supprimer le fichier d'alice (car il a `w` sur le dossier).

```bash
sudo -u bob rm -f /srv/projet/fichier-alice.txt && echo "bob a supprimé le fichier d'alice !"
sudo -u alice touch /srv/projet/fichier-alice.txt       # recréation
sudo chmod +t /srv/projet
ls -ld /srv/projet                                      # drwxrws--T ... (T majuscule : sticky sans x pour others)
sudo -u bob rm /srv/projet/fichier-alice.txt            # doit échouer
```

> ❓ **Question 6** : Pourquoi le `t` apparaît-il en majuscule `T` ici ?
> *(Indice : « autres » n'a pas le droit `x`.)*

### Étape 7 — Notation octale et symbolique

```bash
cd ~
echo '#!/bin/bash
echo "Je suis un script"' > hello.sh
ls -l hello.sh
./hello.sh                      # « Permission denied » attendue
chmod u+x hello.sh
./hello.sh
chmod 640 hello.sh
ls -l hello.sh
chmod 755 hello.sh
stat -c '%a %A %U:%G' hello.sh  # affichage octal, symbolique, propriétaire
```

> ❓ **Question 7** : Convertissez de tête `rwxr-x---` en octal. Vérifiez avec `chmod` puis `stat -c %a`.

### Étape 8 — Une règle sudo à moindre privilège

```bash
sudo visudo -f /etc/sudoers.d/alice-ssh
```

Saisissez la ligne suivante, puis enregistrez :

```text
alice ALL=(root) /usr/bin/systemctl restart ssh, /usr/bin/systemctl status ssh
```

Testez :

```bash
sudo -l -U alice
sudo -u alice sudo systemctl status ssh --no-pager | head -3     # autorisé (mot de passe d'alice demandé)
sudo -u alice sudo apt update                                      # refusé
```

> ❓ **Question 8** : Pourquoi est-il dangereux d'écrire `alice ALL=(ALL) ALL` pour une simple délégation de redémarrage ? Pourquoi `visudo` plutôt que `nano` ?

### Étape 9 — Audit des binaires setuid

```bash
find /usr -perm -4000 -type f 2>/dev/null | head
ls -l /usr/bin/passwd /usr/bin/sudo
```

> ❓ **Question 9** : Pourquoi `passwd` est-il setuid root ? Quel risque cela représente-t-il ?

### Étape 10 — Nettoyage

```bash
sudo rm /etc/sudoers.d/alice-ssh
for u in alice bob clara; do sudo userdel -r "$u"; done
sudo groupdel developpeurs; sudo groupdel stagiaires
sudo rm -rf /srv/projet
```

## ✅ Validation

- [ ] `id alice` montre le groupe `developpeurs` ; `id clara` montre `stagiaires`.
- [ ] `/srv/projet` affiche `drwxrws--T` (ou `drwxrws--t`) avec propriétaire `root:developpeurs`.
- [ ] Les fichiers créés par alice et bob appartiennent au groupe `developpeurs`.
- [ ] `clara` peut lister mais pas écrire dans `/srv/projet`.
- [ ] bob **ne peut pas** supprimer le fichier d'alice.
- [ ] `sudo -l -U alice` ne liste que les deux commandes `systemctl` autorisées.
- [ ] Vous savez expliquer setuid, setgid et sticky.

## 💡 Pour aller plus loin

- **Défi 1** : configurez `umask 007` pour alice dans son `~/.bashrc` et vérifiez les droits des nouveaux fichiers.
- **Défi 2** : listez tous les fichiers **world-writable** (`find / -xdev -perm -0002 -type f 2>/dev/null`) et jugez lesquels sont légitimes.
- **Défi 3** : exigez une durée de vie de 90 jours pour le mot de passe d'alice avec `chage`.
- **Défi 4** : lisez `/etc/pam.d/sudo` et identifiez la ligne qui active l'authentification.

Module suivant : [Processus et services](../../02-linux-intermediaire/cours/01-processus-services.md).
