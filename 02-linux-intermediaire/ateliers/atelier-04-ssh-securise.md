# Atelier 04 — SSH sécurisé

## 🎯 Objectifs

- Générer une paire de clés **ed25519** protégée par passphrase.
- Déployer la clé publique et se connecter sans mot de passe.
- Configurer `~/.ssh/config` et utiliser `scp`/`rsync` et un tunnel.
- Durcir `sshd` (pas de root, pas de mot de passe) **sans s'enfermer dehors**.

## 📋 Prérequis

- Ateliers [01](atelier-01-processus-systemd.md) à [03](atelier-03-diagnostic-reseau.md) terminés.
- Cours lu : [SSH et authentification par clés](../cours/04-ssh-cles.md).
- Serveur SSH actif : `systemctl is-active sshd`.

## 🧪 Scénario

*Kamer Logistics* a subi des tentatives d'intrusion par force brute. Vous devez interdire les mots de passe
sur le serveur et imposer l'authentification par clé. Pour pouvoir tout faire **dans une seule VM**, vous
allez créer un utilisateur `deploy` qui jouera le rôle du « client », et le serveur sera la VM elle-même (`localhost`).
*(Variante : jouez le client depuis votre hôte avec `ssh -p 2222 -i <clé de vagrant ssh-config> vagrant@127.0.0.1`.)*

> ⚠️ **Attention** : gardez **une deuxième session ouverte** (un autre terminal) tout au long de l'étape de durcissement. En cas d'erreur de configuration, elle vous permet de revenir en arrière.

## Étapes

### Étape 1 — Créer l'utilisateur client

```bash
sudo useradd -m -s /bin/bash deploy
sudo passwd deploy                    # définissez un mot de passe d'exercice
sudo -iu deploy
whoami
```

Vous êtes maintenant `deploy`. Pour la suite, les commandes « client » sont lancées en tant que `deploy`.

### Étape 2 — Connexion par mot de passe (état initial)

> 🐧 La box Rocky **refuse déjà** les mots de passe en SSH (durcissement). Pour réaliser cet état initial, on les autorise **temporairement** avec un fichier qui passe **avant** celui de la box (ordre alphabétique : `00-atelier…` < `00-worketyamo…`) :
>
> ```bash
> echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/00-atelier-mdp.conf
> sudo sshd -t && sudo systemctl reload sshd
> sudo sshd -T | grep passwordauthentication       # yes
> ```
>
> Le mot de passe du compte `vagrant` est `vagrant`. **Ce fichier est supprimé au début de l'étape 8.**

```bash
ssh vagrant@localhost            # remplacez « vagrant » par votre identifiant sur la VM
# Acceptez l'empreinte d'hôte (yes), saisissez le mot de passe, puis :
exit
cat ~/.ssh/known_hosts | cut -c1-60
```

> ❓ **Question 1** : Que contient `~/.ssh/known_hosts` ? Quelle attaque l'empreinte d'hôte permet-elle de repérer ?

### Étape 3 — Générer la paire de clés

```bash
ssh-keygen -t ed25519 -C "deploy@kamer-atelier" -f ~/.ssh/id_ed25519
# Saisissez une passphrase (obligatoire pour l'exercice)
ls -l ~/.ssh
cat ~/.ssh/id_ed25519.pub
ssh-keygen -lf ~/.ssh/id_ed25519.pub      # empreinte de la clé
```

> ❓ **Question 2** : Laquelle des deux clés ne doit **jamais** quitter votre machine ? Que se passe-t-il si quelqu'un s'en empare, sachant qu'elle est protégée par une passphrase ?

### Étape 4 — Déployer la clé publique

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub vagrant@localhost
ssh vagrant@localhost "echo connecté sans mot de passe serveur ; hostname"
```

On vous demande la **passphrase de la clé**, et non plus le mot de passe du compte.

Côté serveur, constatez le résultat (exécutez en tant que `vagrant` dans une autre fenêtre) :

```bash
cat ~/.ssh/authorized_keys
ls -ld ~/.ssh ; ls -l ~/.ssh/authorized_keys
```

> ❓ **Question 3** : Quels droits doivent avoir `~/.ssh` et `authorized_keys` ? Que fait `sshd` si les droits sont trop larges ?

### Étape 5 — Agent SSH

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add -l
ssh vagrant@localhost hostname        # plus de passphrase demandée
```

> ❓ **Question 4** : Où la clé déchiffrée est-elle conservée ? Quel est le compromis sécurité/confort ?

### Étape 6 — Fichier `~/.ssh/config`

```bash
cat > ~/.ssh/config <<'EOF'
Host kamer
    HostName localhost
    User vagrant
    IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
ssh kamer hostname
```

### Étape 7 — Transferts et tunnel

```bash
echo "rapport du jour" > rapport.txt
scp rapport.txt kamer:/tmp/
ssh kamer "cat /tmp/rapport.txt"
mkdir -p dossier && date > dossier/a.txt
rsync -avz dossier/ kamer:/tmp/dossier/
```

Tunnel : exposez un serveur local limité au « serveur » (ici la même VM) :

```bash
python3 -m http.server 9000 --bind 127.0.0.1 &
ssh -f -N -L 9100:localhost:9000 kamer
curl -s http://localhost:9100 | head -3
pkill -f "ssh -f -N -L 9100"
kill %1
```

> ❓ **Question 5** : Que fait `-L 9100:localhost:9000` ? Où `localhost` est-il interprété : côté client ou côté serveur ?

### Étape 8 — Durcir `sshd` (repassez en `vagrant`)

Commencez par retirer l'autorisation temporaire de l'étape 2 : `sudo rm /etc/ssh/sshd_config.d/00-atelier-mdp.conf`.

Quittez la session `deploy` (`exit`). **Ouvrez un second terminal connecté en SSH et laissez-le ouvert.** Puis :

```bash
sudo tee /etc/ssh/sshd_config.d/00-durcissement.conf > /dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
EOF
sudo sshd -t && echo "syntaxe OK"
sudo sshd -T | grep -Ei "^(permitrootlogin|passwordauthentication|maxauthtries)"
sudo systemctl reload sshd
```

> ❓ **Question 6** : Pourquoi `sshd -t` **avant** `reload` ? Pourquoi `reload` plutôt que `restart` ?

> 💡 **Conseil** : sous Rocky comme sous Ubuntu 24.04, `/etc/ssh/sshd_config.d/*.conf` est lu **avant** les lignes de `sshd_config` et la première valeur rencontrée l'emporte (ordre alphabétique des fichiers). Un autre fichier peut donc imposer une valeur : si `sshd -T` ne montre pas celle attendue, nommez le vôtre avec un préfixe qui passe **avant** (comme ici `00-`), et supprimez `00-atelier-mdp.conf`.

### Étape 9 — Vérifier le durcissement

Depuis le compte `deploy` (la clé n'est connue que de lui) :

```bash
sudo -iu deploy
ssh kamer hostname                                                    # OK : par clé
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password kamer hostname
# attendu : Permission denied (publickey).
ssh -o PubkeyAuthentication=no root@localhost                         # refusé
exit
```

> ❓ **Question 7** : Pourquoi l'interdiction du mot de passe protège-t-elle efficacement contre les attaques par force brute ?

### Étape 10 — Observer les journaux

```bash
sudo journalctl -u sshd --since "10 minutes ago" --no-pager | grep -E "Accepted|Failed|Invalid" | tail
sudo lastb 2>/dev/null | head -5
```

### Étape 11 — Nettoyage

```bash
sudo rm /etc/ssh/sshd_config.d/00-durcissement.conf
sudo sshd -t && sudo systemctl reload sshd
sudo userdel -r deploy
sed -i '/deploy@kamer-atelier/d' ~/.ssh/authorized_keys
```

*(Dans un contexte réel, vous **conserveriez** le durcissement.)*

## ✅ Validation

- [ ] La clé `id_ed25519` (600) et `id_ed25519.pub` (644) existent.
- [ ] La connexion par clé fonctionne (`ssh kamer hostname`).
- [ ] `sudo sshd -T` affiche `passwordauthentication no` et `permitrootlogin no`.
- [ ] La tentative par mot de passe est refusée avec `Permission denied (publickey)`.
- [ ] `scp`, `rsync` et le tunnel `-L` ont fonctionné.
- [ ] Vous n'avez jamais perdu l'accès à la VM.

## 💡 Pour aller plus loin

- **Défi 1** : *(sur une VM jetable, avec snapshot ; ne le faites pas sur la VM Vagrant du cours : `vagrant ssh` utilise le port 22 de la VM)* changez le port SSH vers 2222 : `Port 2222` dans `sshd_config`, `sudo semanage port -a -t ssh_port_t -p tcp 2222` (SELinux), `sudo firewall-cmd --permanent --add-port=2222/tcp && sudo firewall-cmd --reload` (firewalld).
- **Défi 2** : utilisez `fail2ban` (EPEL, déjà installé dans la VM ; voir le [cours de durcissement](../../03-linux-avance/cours/04-securite-durcissement.md)) et observez le blocage d'une IP après 3 échecs.
- **Défi 3** : limitez la clé de `deploy` à une seule commande avec `command="…"` dans `authorized_keys`.
- **Défi 4** : utilisez `ProxyJump` pour atteindre une seconde VM via la première.

---

## 🏆 Défi du jour

**Objectif** : Configurer un **alias SSH** avec une clé dédiée, puis l'utiliser pour une synchronisation `rsync`.

**Contexte** : Tu administres plusieurs serveurs et tu en as assez de taper des options à rallonge. Tu veux une clé dédiée à ce serveur, un alias court et un transfert de fichiers sécurisé, sans mot de passe.

**Consignes** :
- Génère une paire **ed25519** dédiée `~/.ssh/id_ed25519_defi` (avec ou sans passphrase) ; installe sa partie publique avec `ssh-copy-id -i … ton-utilisateur@localhost`.
- Crée (ou complète) `~/.ssh/config` avec un alias `serveur-defi` pointant vers `localhost`, ton utilisateur et cette clé (`IdentityFile`). Droits `600` sur le fichier.
- Vérifie `ssh serveur-defi hostname` **sans mot de passe de compte**.
- Synchronise un dossier `~/defi-ssh-source/` (avec 2 fichiers) vers `serveur-defi:~/defi-ssh-copie/` avec `rsync -avz`, puis prouve la copie avec `ssh serveur-defi ls ~/defi-ssh-copie`.
- Contrôle les droits : `~/.ssh` en `700`, clé privée en `600`.

**Indices** (à consulter seulement si bloqué) :
- `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_defi` ; `ssh-copy-id -i ~/.ssh/id_ed25519_defi.pub $USER@localhost`.
- Dans `config` : `Host`, `HostName`, `User`, `IdentityFile`, et éventuellement `IdentitiesOnly yes`.
- `rsync -avz dossier-source/ alias:chemin/` : le `/` final de la source copie son **contenu**.

**Critères de réussite** :
- [ ] `ssh serveur-defi hostname` affiche le nom de la machine sans demander le mot de passe du compte.
- [ ] `ssh serveur-defi ls ~/defi-ssh-copie` liste les 2 fichiers.
- [ ] `stat -c %a ~/.ssh ~/.ssh/config ~/.ssh/id_ed25519_defi` affiche `700`, `600`, `600`.
- [ ] La clé privée n'a jamais quitté ta machine.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_defi -N "" -C "defi-j4"
ssh-copy-id -i ~/.ssh/id_ed25519_defi.pub "$USER@localhost"

cat >> ~/.ssh/config <<EOF
Host serveur-defi
    HostName localhost
    User $USER
    IdentityFile ~/.ssh/id_ed25519_defi
    IdentitiesOnly yes
EOF
chmod 700 ~/.ssh && chmod 600 ~/.ssh/config ~/.ssh/id_ed25519_defi

ssh serveur-defi hostname

mkdir -p ~/defi-ssh-source && echo a > ~/defi-ssh-source/a.txt && echo b > ~/defi-ssh-source/b.txt
rsync -avz ~/defi-ssh-source/ serveur-defi:~/defi-ssh-copie/
ssh serveur-defi ls ~/defi-ssh-copie              # a.txt  b.txt
stat -c '%a %n' ~/.ssh ~/.ssh/config ~/.ssh/id_ed25519_defi
```

`-N ""` crée la clé sans passphrase (acceptable ici, **déconseillé** pour une vraie clé). `IdentitiesOnly yes` force SSH à n'utiliser que la clé indiquée.

</details>

---

Module suivant : [Scripting Bash](../../03-linux-avance/cours/01-scripting-bash.md).
