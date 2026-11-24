# Sécurité et durcissement d'un serveur Linux

## Pourquoi ce cours ?

Un serveur connecté à Internet est attaqué **dans les minutes** qui suivent sa mise en ligne : scans de ports,
force brute SSH, exploitation de services obsolètes. Le **durcissement** (*hardening*) consiste à réduire la
**surface d'attaque** et à renforcer chaque couche. Aucune mesure n'est parfaite ; c'est leur empilement
(*défense en profondeur*) qui rend une intrusion coûteuse.

```text
Défense en profondeur
┌───────────────────────────────────────────────┐
│ Réseau : pare-feu, ports minimaux             │
│ ┌───────────────────────────────────────────┐ │
│ │ Accès : SSH par clé, sudo, comptes        │ │
│ │ ┌───────────────────────────────────────┐ │ │
│ │ │ Système : mises à jour, services,     │ │ │
│ │ │ noyau (sysctl), AppArmor              │ │ │
│ │ │ ┌───────────────────────────────────┐ │ │ │
│ │ │ │ Données : permissions, sauvegardes│ │ │ │
│ │ │ └───────────────────────────────────┘ │ │ │
│ │ └───────────────────────────────────────┘ │ │
│ └───────────────────────────────────────────┘ │
└───────────────────────────────────────────────┘
        + Surveillance : logs, audit, alertes
```

## 1. Principes directeurs

1. **Moindre privilège** : chaque utilisateur et service n'a que les droits dont il a besoin.
2. **Réduction de la surface d'attaque** : ce qui n'est pas installé/ouvert ne peut pas être attaqué.
3. **Défense en profondeur** : plusieurs barrières indépendantes.
4. **Sécurité par défaut** : tout est refusé, on autorise explicitement.
5. **Traçabilité** : on ne protège bien que ce qu'on peut observer.

## 2. Mises à jour de sécurité

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades
[ -f /var/run/reboot-required ] && echo "Redémarrage requis"
```

Les correctifs du noyau nécessitent un redémarrage (ou *Livepatch* avec Ubuntu Pro).

## 3. Comptes et authentification

```bash
# Comptes avec UID 0 (doit être SEUL root)
awk -F: '$3==0 {print $1}' /etc/passwd
# Comptes sans mot de passe (ne doit rien renvoyer)
sudo awk -F: '$2=="" {print $1}' /etc/shadow
# Comptes qui ont un shell de connexion
grep -vE "nologin|false" /etc/passwd
# Verrouiller le compte root pour la connexion directe
sudo passwd -l root
```

### Politique de mots de passe (PAM)

```bash
sudo apt install -y libpam-pwquality
sudo nano /etc/security/pwquality.conf
```

```text
minlen = 12
minclass = 3
retry = 3
```

### Limiter les essais : verrouillage de compte

Ubuntu 24.04 fournit `pam_faillock`. Exemple de `/etc/security/faillock.conf` :

```text
deny = 5
unlock_time = 600
fail_interval = 900
```

> ⚠️ **Attention** : testez toute modification de PAM avec une **seconde session root ouverte**. Une erreur peut interdire toute connexion.

## 4. SSH

Reprenez le durcissement vu dans le [cours SSH](../../02-linux-intermediaire/cours/04-ssh-cles.md) : pas de root, pas de mot de passe, `AllowUsers`, `MaxAuthTries`.

### `fail2ban` : bannir les agresseurs

```bash
sudo apt install -y fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
EOF
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip 203.0.113.5     # débannir
```

`fail2ban` surveille les journaux et ajoute des règles de pare-feu temporaires contre les IP qui échouent trop souvent.

## 5. Pare-feu : netfilter, nftables et ufw

Le noyau Linux filtre les paquets grâce à **netfilter**, qui expose des « crochets » (*hooks*) dans le parcours des paquets. On les pilote avec **nftables** (successeur d'`iptables`), ou via la surcouche **ufw**.

```text
                 ┌──────────── INPUT ─────────► processus locaux
 paquet entrant ─► PREROUTING ─┤                                     │
                 └──── FORWARD ───► POSTROUTING ──► sortie     OUTPUT ─┘
```

| Chaîne | Rôle |
|---|---|
| `INPUT` | Paquets destinés à la machine |
| `OUTPUT` | Paquets émis par la machine |
| `FORWARD` | Paquets routés à travers la machine |
| `PREROUTING` / `POSTROUTING` | Avant/après le routage (NAT) |

### `ufw` : politique « tout refuser en entrée »

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow from 192.168.1.0/24 to any port 5432 proto tcp     # restreindre à un réseau
sudo ufw limit OpenSSH                                            # limite le taux de connexions
sudo ufw enable
sudo ufw status numbered
sudo ufw delete 3
```

### Aperçu de `nftables`

```bash
sudo nft list ruleset | head -30       # ufw génère des règles (via iptables-nft)
```

Exemple minimal :

```text
table inet filtre {
  chain input {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    iif lo accept
    tcp dport 22 accept
    icmp type echo-request accept
  }
}
```

> 📌 **À retenir** : `ct state established,related accept` laisse passer les réponses aux connexions déjà autorisées : c'est le principe d'un pare-feu **à état** (*stateful*).

## 6. Réduire la surface d'attaque : services et ports

```bash
sudo ss -tulpn                              # qui écoute ?
systemctl list-unit-files --state=enabled   # services activés
sudo systemctl disable --now cups avahi-daemon 2>/dev/null   # exemples si inutiles
sudo apt purge -y telnet rsh-client 2>/dev/null
```

Règle : tout service qui n'a pas besoin d'être joignable de l'extérieur doit écouter sur `127.0.0.1`.

## 7. Durcissement du noyau avec `sysctl`

Paramètres du noyau modifiables à chaud via `/proc/sys`, rendus permanents dans `/etc/sysctl.d/`.

```bash
sudo tee /etc/sysctl.d/99-durcissement.conf > /dev/null <<'EOF'
# Anti-usurpation d'adresse source (reverse path filtering)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Ne pas accepter les redirections ICMP ni le routage source
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_redirects = 0
# Protection contre les inondations SYN
net.ipv4.tcp_syncookies = 1
# Ignorer les pings broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Journaliser les paquets « martiens »
net.ipv4.conf.all.log_martians = 1
# Cacher les adresses du noyau et restreindre dmesg
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
# Désactiver le SysRq complet
kernel.sysrq = 0
EOF
sudo sysctl --system | tail -5
sysctl net.ipv4.tcp_syncookies
```

## 8. AppArmor : contrôle d'accès obligatoire

Les permissions classiques (DAC) laissent un processus compromis accéder à tout ce que son utilisateur peut atteindre. **AppArmor** (par défaut sur Ubuntu) confine chaque programme avec un **profil** listant les fichiers, capacités et réseaux autorisés.

```bash
sudo aa-status                       # profils chargés (enforce / complain)
sudo apt install -y apparmor-utils
sudo aa-complain /usr/sbin/nginx     # mode apprentissage (journalise sans bloquer)
sudo aa-enforce  /usr/sbin/nginx     # mode strict
sudo journalctl -k | grep -i apparmor | tail
```

## 9. Permissions sensibles et audit de fichiers

```bash
ls -l /etc/passwd /etc/shadow /etc/ssh/sshd_config
find / -xdev -perm -4000 -type f 2>/dev/null          # fichiers setuid
find / -xdev -type f -perm -0002 2>/dev/null          # fichiers modifiables par tous
find / -xdev -nouser -o -nogroup 2>/dev/null          # fichiers sans propriétaire
```

### `auditd` : tracer les accès

```bash
sudo apt install -y auditd
sudo auditctl -w /etc/passwd -p wa -k identite       # surveiller écriture/attribut de /etc/passwd
sudo auditctl -w /etc/sudoers.d/ -p wa -k sudo
sudo ausearch -k identite --start today | tail
```

## 10. Audit global avec Lynis

```bash
sudo apt install -y lynis
sudo lynis audit system
sudo grep -E "warning|suggestion" /var/log/lynis-report.dat | head -20
```

Lynis donne un **score** (*hardening index*) et des suggestions. Visez une amélioration progressive, pas la perfection.

## 11. Chiffrement et secrets

- **En transit** : TLS/HTTPS (Let's Encrypt / `certbot`), SSH.
- **Au repos** : LUKS (`cryptsetup`) pour les disques.
- **Secrets** : jamais dans le dépôt Git ni en clair dans les scripts ; utilisez des variables d'environnement protégées, des fichiers en `chmod 600`, ou un gestionnaire de secrets (Vault).

```bash
openssl rand -base64 32            # génère un secret aléatoire
```

## 12. Checklist de durcissement

| Domaine | Action | Vérification |
|---|---|---|
| Mises à jour | `unattended-upgrades` actif | `systemctl is-enabled unattended-upgrades` |
| SSH | Clés seules, pas de root | `sudo sshd -T \| grep -E "passwordauth\|permitroot"` |
| Pare-feu | Politique `deny incoming` | `sudo ufw status verbose` |
| Brute force | `fail2ban` actif | `sudo fail2ban-client status` |
| Services | Seul le nécessaire écoute | `sudo ss -tulpn` |
| Noyau | `sysctl` durci | `sysctl net.ipv4.tcp_syncookies` |
| MAC | AppArmor en *enforce* | `sudo aa-status` |
| Audit | `auditd` / `lynis` | `sudo lynis audit system` |

> 💡 **Conseil** : durcissez par **petites étapes vérifiables**, avec un snapshot et une session de secours ouverte, plutôt qu'en appliquant un script géant que vous ne comprenez pas.

## Résumé

- Principes : **moindre privilège**, **surface minimale**, **défense en profondeur**, **traçabilité**.
- Mettre à jour automatiquement ; verrouiller les comptes inutiles ; politique de mots de passe via PAM.
- SSH par clé + `fail2ban` ; pare-feu **deny par défaut** (`ufw` au-dessus de netfilter/nftables).
- `sysctl` durcit le noyau ; **AppArmor** confine les processus ; `auditd` et `lynis` auditent.

## Pour aller plus loin

- Référentiels : **CIS Benchmarks** Ubuntu 24.04, guides de l'ANSSI (« Recommandations de configuration d'un système GNU/Linux »).
- `man nft`, `man ufw`, `man sysctl`, `man apparmor`, `man auditd`.
- SELinux (famille Red Hat) vs AppArmor ; seccomp ; capabilities (`man 7 capabilities`).
- Atelier associé : [Durcissement d'un serveur](../ateliers/atelier-04-durcissement-serveur.md).
- Module suivant : [Noyau et performance](../../04-linux-expert/cours/01-noyau-performance.md).
