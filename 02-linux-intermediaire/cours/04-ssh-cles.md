# SSH et authentification par clés

## Pourquoi ce cours ?

**SSH** (*Secure Shell*) est la porte d'entrée de pratiquement tous les serveurs Linux. Il remplace
`telnet` et `rsh`, qui transmettaient tout en clair. Un serveur SSH mal configuré (mot de passe faible,
connexion root autorisée) est compromis en quelques heures : les robots scannent Internet en
permanence. Maîtriser les clés et la configuration de `sshd` est une compétence de sécurité de base.

## 1. Principe de fonctionnement

SSH établit un **canal chiffré** entre un client et un serveur (port TCP 22 par défaut).

```text
Client                                          Serveur (sshd)
  │ ──── 1. négociation des algorithmes ─────────► │
  │ ◄─── 2. clé publique d'hôte du serveur ─────── │   (le client vérifie son empreinte)
  │ ═══ 3. échange de clés (Diffie-Hellman) ═══════│   → clé de session partagée
  │ ═══ 4. canal chiffré établi ═══════════════════│
  │ ──── 5. authentification (mot de passe / clé) ►│
  │ ◄─── 6. session shell / commande / transfert ──│
```

## 2. Première connexion et empreinte d'hôte

```bash
ssh etudiant@192.168.1.20
```

```text
The authenticity of host '192.168.1.20' can't be established.
ED25519 key fingerprint is SHA256:abcd...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Ce message sert à vous protéger d'une attaque de l'homme du milieu : vérifiez l'empreinte par un autre canal. Après `yes`, la clé d'hôte est enregistrée dans `~/.ssh/known_hosts`. Si elle **change** plus tard, SSH affiche un avertissement : ne l'ignorez pas.

```bash
ssh -p 2222 etudiant@127.0.0.1        # port non standard
ssh etudiant@serveur "uptime"         # exécuter une seule commande
ssh-keygen -R 192.168.1.20            # oublier une clé d'hôte (après réinstallation légitime)
```

## 3. Cryptographie asymétrique

Une paire de clés se compose de :

- une **clé privée** : secrète, ne quitte **jamais** votre machine ;
- une **clé publique** : peut être distribuée librement (le fichier `.pub`).

Ce qui est signé avec la clé privée est vérifiable avec la clé publique. Lors de la connexion, le serveur envoie un défi que seul le détenteur de la clé privée peut signer : **le secret ne circule jamais sur le réseau**.

```text
 Client (clé privée)                    Serveur (clé publique dans authorized_keys)
   │  « je veux me connecter, clé X »  ► │
   │ ◄ défi aléatoire ────────────────── │
   │  signature du défi (clé privée)   ► │  vérifie avec la clé publique → accès accordé
```

## 4. Générer et déployer une clé

```bash
ssh-keygen -t ed25519 -C "etudiant@portable-2025"
# Fichier par défaut : ~/.ssh/id_ed25519 (privée) et ~/.ssh/id_ed25519.pub (publique)
# Choisissez une PASSPHRASE : elle chiffre la clé privée sur le disque.
ls -l ~/.ssh
cat ~/.ssh/id_ed25519.pub
```

| Algorithme | Recommandation |
|---|---|
| **ed25519** | Recommandé : rapide, clés courtes, sûr |
| RSA ≥ 3072 bits | Acceptable pour compatibilité (`-t rsa -b 4096`) |
| DSA, RSA 1024 | Obsolètes, à proscrire |

Déployer la clé publique sur le serveur :

```bash
ssh-copy-id etudiant@192.168.1.20
# équivaut à ajouter la ligne de id_ed25519.pub dans ~/.ssh/authorized_keys du serveur
ssh etudiant@192.168.1.20          # connexion sans mot de passe serveur
```

### Droits obligatoires

`sshd` refuse les clés si les permissions sont trop larges (`StrictModes`).

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

> ⚠️ **Attention** : ne partagez, n'envoyez par e-mail et ne versionnez **jamais** votre clé privée. Si elle est compromise, supprimez sa ligne dans tous les `authorized_keys` concernés.

## 5. L'agent SSH

Saisir la passphrase à chaque connexion est pénible. `ssh-agent` garde la clé déchiffrée en mémoire pour la session.

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add -l                      # clés chargées
```

## 6. Configuration du client : `~/.ssh/config`

```text
Host web01
    HostName 192.168.1.20
    User etudiant
    Port 22
    IdentityFile ~/.ssh/id_ed25519

Host vm
    HostName 127.0.0.1
    Port 2222
    User etudiant
```

```bash
ssh web01        # remplace ssh -i ~/.ssh/id_ed25519 etudiant@192.168.1.20
chmod 600 ~/.ssh/config
```

## 7. Transferts de fichiers

```bash
scp fichier.txt web01:/tmp/                 # copie vers le serveur
scp web01:/var/log/syslog ./                # copie depuis le serveur
scp -r dossier/ web01:~/                    # récursif
rsync -avz --progress dossier/ web01:~/dossier/   # synchronisation incrémentale (recommandé)
sftp web01                                  # session interactive
```

## 8. Tunnels (redirection de ports)

```bash
# Redirection locale : mon port 8080 → port 80 du serveur
ssh -L 8080:localhost:80 web01
# Puis ouvrir http://localhost:8080 sur la machine locale

# Redirection dynamique : proxy SOCKS sur le port 1080
ssh -D 1080 -N web01

# Saut par un bastion (ProxyJump)
ssh -J bastion web01
```

## 9. Durcir le serveur : `sshd_config`

La configuration est dans `/etc/ssh/sshd_config` et les fragments de `/etc/ssh/sshd_config.d/`.

```bash
sudo sshd -T | grep -Ei "permitrootlogin|passwordauthentication|port|pubkeyauthentication"
```

Fichier de durcissement, par exemple `/etc/ssh/sshd_config.d/99-durcissement.conf` :

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
MaxAuthTries 3
LoginGraceTime 30
AllowUsers etudiant
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
```

| Directive | Effet |
|---|---|
| `PermitRootLogin no` | Interdit la connexion directe de root |
| `PasswordAuthentication no` | Impose les clés (supprime les attaques par force brute sur mot de passe) |
| `MaxAuthTries 3` | Limite les essais par connexion |
| `AllowUsers` | Liste blanche d'utilisateurs |
| `Port 2222` | Change le port (réduit le bruit des journaux ; **n'est pas** une vraie protection) |

**Toujours** valider avant de recharger, et garder une seconde session ouverte :

```bash
sudo sshd -t                       # test de syntaxe (aucune sortie = OK)
sudo systemctl reload ssh          # applique sans couper les sessions existantes
```

> ⚠️ **Attention** : désactivez `PasswordAuthentication` **seulement après** avoir confirmé que la connexion par clé fonctionne depuis une autre fenêtre. Sinon, vous vous enfermez dehors.

> 💡 **Conseil** : sous Ubuntu 24.04, `ssh` est géré par `ssh.service` et peut démarrer par socket (`ssh.socket`). Si vous changez de port, vérifiez la configuration du socket (`systemctl cat ssh.socket`).

## 10. Surveiller

```bash
sudo journalctl -u ssh --since today | grep -E "Failed|Accepted"
sudo grep "Failed password" /var/log/auth.log | tail
last -a | head
sudo lastb | head           # tentatives échouées
```

Pour bloquer automatiquement les attaquants : `fail2ban` (voir le module [durcissement](../../03-linux-avance/cours/04-securite-durcissement.md)).

> 📌 **À retenir** : le trio de base est **clé ed25519 + passphrase**, **pas de mot de passe**, **pas de root**. Avec ces trois réglages, vous éliminez l'essentiel des attaques automatisées.

## Résumé

- SSH chiffre la session ; la **clé d'hôte** authentifie le serveur, la **clé utilisateur** authentifie le client.
- Générez en **ed25519** avec une **passphrase** ; déployez avec `ssh-copy-id`.
- Permissions strictes : `~/.ssh` en 700, clés privées en 600.
- `~/.ssh/config` simplifie les connexions ; `scp`/`rsync` transfèrent ; `-L`/`-D`/`-J` créent tunnels et rebonds.
- Durcir : pas de root, pas de mot de passe, `AllowUsers`, `sshd -t` avant `reload`.

## Pour aller plus loin

- `man ssh`, `man sshd_config`, `man ssh_config`, `man ssh-keygen`.
- Autorités de certification SSH, clés matérielles FIDO2 (`ed25519-sk`).
- `fail2ban`, `sshguard`, authentification à deux facteurs.
- Atelier associé : [SSH sécurisé](../ateliers/atelier-04-ssh-securise.md).
- Module suivant : [Scripting Bash](../../03-linux-avance/cours/01-scripting-bash.md).
