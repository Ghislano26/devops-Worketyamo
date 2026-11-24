# Atelier 04 — Durcissement d'un serveur Ubuntu

## 🎯 Objectifs

- Mesurer l'état de sécurité initial (score Lynis, ports ouverts, comptes).
- Appliquer des mesures de durcissement : mises à jour auto, SSH, pare-feu, `fail2ban`, `sysctl`.
- Vérifier chaque mesure par un test concret.
- Comparer avant/après et produire un rapport.

## 📋 Prérequis

- Ateliers [01](atelier-01-scripts-automatisation.md) à [03](atelier-03-lvm.md) et atelier SSH ([module 02](../../02-linux-intermediaire/ateliers/atelier-04-ssh-securise.md)) terminés.
- Cours lu : [Sécurité et durcissement](../cours/04-securite-durcissement.md).
- Snapshot de la VM pris. **Gardez une seconde session ouverte** pendant tout l'atelier.
- Une clé SSH fonctionnelle pour votre utilisateur (sinon, **ne désactivez pas** l'authentification par mot de passe).

> ⚠️ **Attention** : ne faites pas cet atelier sur un serveur de production réel sans plan de retour arrière.

## 🧪 Scénario

*Kamer Logistics* ouvre son serveur `ubuntu-devops` sur Internet dans 48 heures. Un audit interne exige : zéro
mot de passe SSH, pare-feu *deny by default*, protection anti-force-brute, noyau durci, et un score d'audit
mesurable. Vous êtes responsable du durcissement et devez livrer un **avant/après**.

## Étapes

### Étape 1 — État initial (« avant »)

```bash
mkdir -p ~/durcissement && cd ~/durcissement
sudo apt update && sudo apt install -y lynis fail2ban ufw auditd libpam-pwquality
sudo lynis audit system --quiet --no-colors > lynis-avant.txt 2>&1
grep -E "Hardening index" lynis-avant.txt
sudo ss -tulpn > ports-avant.txt
sudo sshd -T | grep -E "^(permitrootlogin|passwordauthentication|maxauthtries|x11forwarding)" > ssh-avant.txt
cat ssh-avant.txt
sudo ufw status | head -1
```

Notez votre **Hardening index** : c'est votre point de départ.

> ❓ **Question 1** : Pourquoi mesure-t-on avant de durcir ? Quels risques présente un durcissement « à l'aveugle » ?

### Étape 2 — Inventaire des comptes

```bash
awk -F: '$3==0 {print "UID 0 :", $1}' /etc/passwd
sudo awk -F: '$2=="" {print "SANS MOT DE PASSE :", $1}' /etc/shadow
grep -vE "nologin|false|sync" /etc/passwd | cut -d: -f1,7
getent group sudo
```

> ❓ **Question 2** : Quel est le seul compte censé avoir l'UID 0 ? Que signifierait un second compte avec l'UID 0 ?

### Étape 3 — Mises à jour de sécurité automatiques

```bash
sudo apt update && sudo apt upgrade -y
cat /etc/apt/apt.conf.d/20auto-upgrades
sudo systemctl enable --now unattended-upgrades
systemctl is-active unattended-upgrades
sudo unattended-upgrade --dry-run --debug 2>&1 | grep -E "Allowed origins|Packages that will be upgraded" 
```

### Étape 4 — SSH durci

```bash
sudo tee /etc/ssh/sshd_config.d/00-durcissement.conf > /dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowAgentForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
sudo sshd -t && echo "syntaxe OK"
sudo sshd -T | grep -E "^(permitrootlogin|passwordauthentication|maxauthtries|x11forwarding)"
```

**Avant** de recharger, ouvrez une **deuxième connexion SSH par clé** pour vous assurer qu'elle fonctionne, puis :

```bash
sudo systemctl reload ssh
```

> ❓ **Question 3** : Que vérifie-t-on en ouvrant la seconde session *avant* de recharger ?

### Étape 5 — Pare-feu *deny by default*

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit OpenSSH
sudo ufw --force enable
sudo ufw status verbose
sudo ufw status numbered
```

> ❓ **Question 4** : Quelle différence entre `ufw allow OpenSSH` et `ufw limit OpenSSH` ? Pourquoi l'ordre « autoriser SSH puis activer » est-il vital ?

### Étape 6 — `fail2ban`

```bash
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime  = 10m
findtime = 10m
maxretry = 3

[sshd]
enabled = true
EOF
sudo systemctl enable --now fail2ban
sudo systemctl restart fail2ban
sleep 2
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

Test d'attaque simulée (depuis la VM elle-même, via `localhost`) :

```bash
for i in 1 2 3 4; do ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o ConnectTimeout=3 inconnu@localhost true 2>&1 | tail -1; done
sleep 3
sudo fail2ban-client status sshd
```

> 💡 **Conseil** : `fail2ban` ne bannit pas `127.0.0.1` par défaut (`ignoreip`). Si rien n'est banni, c'est normal pour `localhost` : observez les compteurs *Currently failed* / *Total failed*. Pour un vrai test, attaquez depuis une seconde VM ou votre hôte.

Pour débannir : `sudo fail2ban-client set sshd unbanip <IP>`.

> ❓ **Question 5** : Comment `fail2ban` agit-il concrètement sur le pare-feu ? Où lit-il les échecs de connexion ?

### Étape 7 — Durcissement du noyau avec `sysctl`

```bash
sudo tee /etc/sysctl.d/99-durcissement.conf > /dev/null <<'EOF'
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
EOF
sudo sysctl --system > /dev/null
sysctl net.ipv4.tcp_syncookies kernel.dmesg_restrict kernel.kptr_restrict
```

> ❓ **Question 6** : Que protège `rp_filter` ? Que se passe-t-il à la prochaine mise sous tension si l'on n'écrit pas dans `/etc/sysctl.d/` ?

### Étape 8 — Politique de mots de passe

```bash
sudo tee -a /etc/security/pwquality.conf > /dev/null <<'EOF'
minlen = 12
minclass = 3
EOF
echo 'Test1234' | pwscore                       # score faible attendu / refus
echo 'T4ngo!Violet-Soleil' | pwscore
sudo chage -l "$USER"
```

### Étape 9 — Surveillance : `auditd`

```bash
sudo systemctl enable --now auditd
sudo auditctl -w /etc/passwd -p wa -k identite
sudo auditctl -w /etc/sudoers.d/ -p wa -k sudo
sudo useradd -M -s /usr/sbin/nologin temoin-audit
sudo ausearch -k identite --start recent 2>/dev/null | grep -E "type=(PATH|SYSCALL)" | tail -4
sudo userdel temoin-audit
sudo auditctl -l
```

> ❓ **Question 7** : Pourquoi surveille-t-on les écritures sur `/etc/passwd` ? Quels autres fichiers ajouteriez-vous ?

### Étape 10 — Réduire la surface d'attaque

```bash
sudo ss -tulpn
systemctl list-unit-files --state=enabled --type=service | head -30
find / -xdev -perm -4000 -type f 2>/dev/null | wc -l
find / -xdev -type f -perm -0002 2>/dev/null | head
sudo aa-status | head -5
```

Pour chaque port à l'écoute : « Est-il nécessaire ? Doit-il écouter sur `127.0.0.1` seulement ? »

### Étape 11 — Mesure finale (« après ») et rapport

```bash
sudo lynis audit system --quiet --no-colors > lynis-apres.txt 2>&1
echo "AVANT : $(grep 'Hardening index' lynis-avant.txt)"
echo "APRES : $(grep 'Hardening index' lynis-apres.txt)"
sudo ss -tulpn > ports-apres.txt
diff ports-avant.txt ports-apres.txt || true
sudo sshd -T | grep -E "^(permitrootlogin|passwordauthentication|maxauthtries|x11forwarding)" | diff ssh-avant.txt - || true
sudo grep -E "^(warning|suggestion)\[\]=" /var/log/lynis-report.dat | head -10
```

Rédigez ensuite `rapport.md` avec : score avant/après, mesures appliquées, risques résiduels, prochaines actions.

## ✅ Validation

- [ ] `sudo sshd -T` : `passwordauthentication no`, `permitrootlogin no`, `maxauthtries 3`.
- [ ] Vous vous connectez toujours en SSH **par clé**.
- [ ] `sudo ufw status verbose` : `Default: deny (incoming), allow (outgoing)`, SSH limité.
- [ ] `sudo fail2ban-client status sshd` montre la jail active.
- [ ] `sysctl net.ipv4.tcp_syncookies` → `1` ; `sysctl kernel.dmesg_restrict` → `1`.
- [ ] `unattended-upgrades` est actif.
- [ ] Le score Lynis « après » est **supérieur** au score « avant ».
- [ ] Le rapport `~/durcissement/rapport.md` est rédigé.

## 💡 Pour aller plus loin

- **Défi 1** : visez un Hardening index ≥ 75 en traitant les suggestions Lynis une à une.
- **Défi 2** : passez un profil AppArmor en mode *complain* puis *enforce* (`aa-complain`, `aa-enforce`) et lisez le journal.
- **Défi 3** : écrivez un script qui vérifie automatiquement la checklist de durcissement et renvoie un code d'erreur si un contrôle échoue.
- **Défi 4** : consultez les recommandations CIS ou ANSSI et choisissez 5 mesures supplémentaires à appliquer.

Module suivant : [Noyau et performance](../../04-linux-expert/cours/01-noyau-performance.md).
