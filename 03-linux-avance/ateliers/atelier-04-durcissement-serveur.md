# Atelier 04 — Durcissement d'un serveur Rocky Linux

> 🐧 *Version Rocky Linux 9 : `dnf-automatic`, `firewalld` et SELinux remplacent `unattended-upgrades`, `ufw` et AppArmor. La box livrée applique déjà un durcissement SSH minimal et active `firewalld` : l'état « avant » n'est donc pas celui d'un serveur vierge.*

## 🎯 Objectifs

- Mesurer l'état de sécurité initial (score Lynis, ports ouverts, comptes).
- Appliquer des mesures de durcissement : mises à jour auto, SSH, pare-feu, `fail2ban`, `sysctl`.
- Vérifier chaque mesure par un test concret.
- Comparer avant/après et produire un rapport.

## 📋 Prérequis

- Ateliers [01](atelier-01-scripts-automatisation.md) à [03](atelier-03-lvm.md) et atelier SSH ([module 02](../../02-linux-intermediaire/ateliers/atelier-04-ssh-securise.md)) terminés.
- Cours lu : [Sécurité et durcissement](../cours/04-securite-durcissement.md).
- Snapshot de la VM pris (`vagrant snapshot save avant-durcissement`). **Gardez une seconde session ouverte** (`vagrant ssh` dans un autre terminal) pendant tout l'atelier.
- Une clé SSH fonctionnelle pour votre utilisateur : c'est le cas avec `vagrant ssh` (clé gérée par Vagrant). Ne désactivez **jamais** l'authentification par mot de passe sans clé valide.

> ⚠️ **Attention** : ne faites pas cet atelier sur un serveur de production réel sans plan de retour arrière.

## 🧪 Scénario

*Kamer Logistics* ouvre son serveur `devops-lab` sur Internet dans 48 heures. Un audit interne exige : zéro
mot de passe SSH, pare-feu *deny by default*, protection anti-force-brute, noyau durci, et un score d'audit
mesurable. Vous êtes responsable du durcissement et devez livrer un **avant/après**.

## Étapes

### Étape 1 — État initial (« avant »)

```bash
mkdir -p ~/durcissement && cd ~/durcissement
sudo dnf install -y lynis fail2ban fail2ban-firewalld audit libpwquality     # lynis et fail2ban : dépôt EPEL
sudo lynis audit system --quiet --no-colors > lynis-avant.txt 2>&1
grep -E "Hardening index" lynis-avant.txt
sudo ss -tulpn > ports-avant.txt
sudo sshd -T | grep -E "^(permitrootlogin|passwordauthentication|maxauthtries|x11forwarding)" > ssh-avant.txt
cat ssh-avant.txt
sudo firewall-cmd --state
```

Notez votre **Hardening index** : c'est votre point de départ.

> ❓ **Question 1** : Pourquoi mesure-t-on avant de durcir ? Quels risques présente un durcissement « à l'aveugle » ?

### Étape 2 — Inventaire des comptes

```bash
awk -F: '$3==0 {print "UID 0 :", $1}' /etc/passwd
sudo awk -F: '$2=="" {print "SANS MOT DE PASSE :", $1}' /etc/shadow
grep -vE "nologin|false|sync" /etc/passwd | cut -d: -f1,7
getent group wheel
```

> ❓ **Question 2** : Quel est le seul compte censé avoir l'UID 0 ? Que signifierait un second compte avec l'UID 0 ? Quel groupe donne les droits `sudo` sur Rocky (équivalent du groupe `sudo` d'Ubuntu) ?

### Étape 3 — Mises à jour de sécurité automatiques

```bash
sudo dnf upgrade -y
sudo dnf install -y dnf-automatic
grep -E '^(upgrade_type|apply_updates)' /etc/dnf/automatic.conf
sudo sed -i 's/^upgrade_type.*/upgrade_type = security/; s/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic-install.timer
systemctl is-enabled dnf-automatic-install.timer
systemctl list-timers 'dnf-automatic*' --no-pager
sudo dnf upgrade --security --assumeno 2>&1 | tail -n 5
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

> 💡 La box contient déjà `/etc/ssh/sshd_config.d/00-worketyamo-hardening.conf` (pas de root, pas de mot de passe). Notre fichier `00-durcissement.conf` complète ce réglage ; avec `sshd`, la **première** valeur lue l'emporte, et les fichiers sont lus dans l'ordre alphabétique.

**Avant** de recharger, ouvrez une **deuxième connexion SSH par clé** (`vagrant ssh` dans un autre terminal) pour vous assurer qu'elle fonctionne, puis :

```bash
sudo systemctl reload sshd
```

> ❓ **Question 3** : Que vérifie-t-on en ouvrant la seconde session *avant* de recharger ?

### Étape 5 — Pare-feu *deny by default* (`firewalld`)

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --list-all
# Réduire aux services strictement nécessaires (SSH seul)
sudo firewall-cmd --permanent --remove-service=dhcpv6-client 2>/dev/null
sudo firewall-cmd --permanent --remove-service=cockpit 2>/dev/null
sudo firewall-cmd --permanent --add-service=ssh
# Journaliser les connexions SSH, avec limite de débit des messages
sudo firewall-cmd --permanent --add-rich-rule='rule service name="ssh" log prefix="SSH-" level="info" limit value="5/m" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
sudo firewall-cmd --list-rich-rules
```

> ❓ **Question 4** : Quelle différence entre `--add-service=ssh` et la règle riche qui journalise ? Pourquoi faut-il `--permanent` **et** `--reload` ? Pourquoi autoriser SSH **avant** de recharger est-il vital ?

### Étape 6 — `fail2ban`

```bash
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime  = 10m
findtime = 10m
maxretry = 3
banaction = firewallcmd-rich-rules
backend = systemd

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

> ❓ **Question 5** : Comment `fail2ban` agit-il concrètement sur le pare-feu (indice : `sudo firewall-cmd --list-rich-rules` pendant un bannissement) ? Où lit-il les échecs de connexion (`backend = systemd`) ?

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
getenforce                                     # Permissive dans la VM du cours
sudo ausearch -m avc -ts today 2>/dev/null | tail -n 3     # refus SELinux journalisés
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
- [ ] `sudo firewall-cmd --list-all` : zone `public`, seul le service `ssh` autorisé.
- [ ] `sudo fail2ban-client status sshd` montre la jail active.
- [ ] `sysctl net.ipv4.tcp_syncookies` → `1` ; `sysctl kernel.dmesg_restrict` → `1`.
- [ ] `dnf-automatic-install.timer` est activé.
- [ ] Le score Lynis « après » est **supérieur** au score « avant ».
- [ ] Le rapport `~/durcissement/rapport.md` est rédigé.

## 💡 Pour aller plus loin

- **Défi 1** : visez un Hardening index ≥ 75 en traitant les suggestions Lynis une à une.
- **Défi 2** : mettez le domaine `httpd_t` en mode permissif avec `semanage permissive -a httpd_t`, provoquez un refus SELinux, lisez-le avec `ausearch -m avc | audit2why`, puis revenez en enforcing (`semanage permissive -d httpd_t`). Voir la section SELinux du [cours](../cours/04-securite-durcissement.md).
- **Défi 3** : écrivez un script qui vérifie automatiquement la checklist de durcissement et renvoie un code d'erreur si un contrôle échoue.
- **Défi 4** : consultez les recommandations CIS ou ANSSI et choisissez 5 mesures supplémentaires à appliquer.

---

## 🏆 Défi du jour

**Objectif** : Écrire un **script d'audit** qui vérifie cinq règles de durcissement et renvoie en code de retour le nombre de règles non respectées.

**Contexte** : Ton responsable veut pouvoir contrôler en 5 secondes que chaque serveur respecte le socle de sécurité, sans relire les configurations à la main. Un script lisible et rejouable fera l'affaire.

**Consignes** :
- Écris `~/audit.sh` (mode strict **sans** `-e` : une vérification qui échoue ne doit pas arrêter le script).
- Contrôle 1 : `sshd` refuse la connexion de root (`sudo sshd -T`). Contrôle 2 : l'authentification par mot de passe SSH est désactivée.
- Contrôle 3 : `firewalld` est actif (`systemctl is-active`). Contrôle 4 : les mises à jour automatiques sont activées (`systemctl is-enabled dnf-automatic-install.timer`).
- Contrôle 5 : un **seul** compte a l'UID 0 (`awk -F: '$3==0' /etc/passwd`).
- Pour chaque contrôle, affiche `OK  <description>` ou `KO  <description>`. Le code de retour est le **nombre de KO**.
- Lance-le avant et après avoir appliqué les mesures de l'atelier : le nombre de KO doit diminuer.

**Indices** (à consulter seulement si bloqué) :
- `sudo sshd -T | grep -qi '^permitrootlogin no'` renvoie 0 si la ligne existe.
- `systemctl is-active --quiet firewalld` renvoie 0 si le service est actif.
- Une petite fonction `controle "description" commande…` évite de répéter le code : elle exécute la commande et affiche OK/KO.

**Critères de réussite** :
- [ ] `~/audit.sh` affiche exactement 5 lignes commençant par `OK` ou `KO`.
- [ ] `~/audit.sh ; echo $?` donne un nombre égal au nombre de lignes `KO`.
- [ ] Après l'atelier de durcissement, le nombre de `KO` est inférieur à celui d'avant.
- [ ] `shellcheck ~/audit.sh` ne renvoie aucune erreur ni avertissement (les messages `info` SC2329 sur des fonctions appelées indirectement par `controle` sont normaux).

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
cat > ~/audit.sh <<'EOF'
#!/usr/bin/env bash
# audit.sh — 5 contrôles de durcissement ; code de retour = nombre de KO
set -uo pipefail
ko=0
controle() {                    # controle "description" commande...
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "OK  $desc"; else echo "KO  $desc"; ko=$((ko + 1)); fi
}
ssh_sans_root()    { sudo sshd -T | grep -qi '^permitrootlogin no'; }
ssh_sans_mdp()     { sudo sshd -T | grep -qi '^passwordauthentication no'; }
firewalld_actif()  { systemctl is-active --quiet firewalld; }
maj_auto()         { systemctl is-enabled --quiet dnf-automatic-install.timer; }
un_seul_root()     { [[ "$(awk -F: '$3==0' /etc/passwd | wc -l)" -eq 1 ]]; }

controle "SSH : connexion root refusée"          ssh_sans_root
controle "SSH : mot de passe désactivé"          ssh_sans_mdp
controle "Pare-feu firewalld actif"               firewalld_actif
controle "Mises à jour automatiques activées"    maj_auto
controle "Un seul compte UID 0"                  un_seul_root
exit "$ko"
EOF
chmod +x ~/audit.sh
shellcheck ~/audit.sh
~/audit.sh ; echo "KO = $?"
```

Pourquoi pas `set -e` ? Un contrôle négatif ne doit pas interrompre l'audit : on veut **tous** les résultats. Le script réutilise les commandes de l'atelier (`sshd -T`, `systemctl`, `awk` sur `/etc/passwd`).

</details>

---

Module suivant : [Noyau et performance](../../04-linux-expert/cours/01-noyau-performance.md).
