# Sécurité et durcissement d'un serveur Linux

> 🐧 **Note Red Hat**
> Ce cours utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.

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
│ │ │ noyau (sysctl), SELinux               │ │ │
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
sudo dnf upgrade --security -y             # applique uniquement les correctifs de sécurité
sudo dnf upgrade -y                        # ou toutes les mises à jour
sudo dnf install -y dnf-automatic
sudo sed -i 's/^upgrade_type.*/upgrade_type = security/; s/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic-install.timer
sudo dnf needs-restarting -r || echo "Redémarrage requis"
```

Les correctifs du noyau nécessitent un redémarrage (Ubuntu propose *Livepatch* avec Ubuntu Pro ; côté Red Hat, `kpatch` avec RHEL). `dnf-automatic` remplace `unattended-upgrades` (voir le [cours sur les paquets](../../02-linux-intermediaire/cours/02-gestion-paquets.md)).

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
rpm -q libpwquality            # installé par défaut sur Rocky (paquet libpwquality)
sudo nano /etc/security/pwquality.conf
```

```text
minlen = 12
minclass = 3
retry = 3
```

### Limiter les essais : verrouillage de compte

Sur RHEL/Rocky, la pile PAM est gérée par **`authselect`** : on active des *fonctionnalités* plutôt que d'éditer `/etc/pam.d/` à la main.

```bash
authselect current                                   # profil actif (ex. sssd)
sudo authselect enable-feature with-faillock         # active pam_faillock
sudo authselect apply-changes
```

Paramètres dans `/etc/security/faillock.conf` :

```text
deny = 5
unlock_time = 600
fail_interval = 900
```

```bash
sudo faillock --user alice            # compteur d'échecs de l'utilisateur
sudo faillock --user alice --reset    # débloquer
```

> ⚠️ **Attention** : testez toute modification de PAM avec une **seconde session root ouverte**. Une erreur peut interdire toute connexion. N'éditez jamais directement les fichiers générés par `authselect` (`/etc/pam.d/system-auth`).

## 4. SSH

Reprenez le durcissement vu dans le [cours SSH](../../02-linux-intermediaire/cours/04-ssh-cles.md) : pas de root, pas de mot de passe, `AllowUsers`, `MaxAuthTries`.

### `fail2ban` : bannir les agresseurs

```bash
# fail2ban est dans le dépôt EPEL : sudo dnf install -y epel-release
sudo dnf install -y fail2ban fail2ban-firewalld
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
banaction = firewallcmd-rich-rules
backend = systemd

[sshd]
enabled = true
EOF
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip 203.0.113.5     # débannir
```

`fail2ban` surveille les journaux (ici le journal `systemd`) et ajoute des **règles riches `firewalld`** temporaires contre les IP qui échouent trop souvent.

## 5. Pare-feu : netfilter, nftables et firewalld

Le noyau Linux filtre les paquets grâce à **netfilter**, qui expose des « crochets » (*hooks*) dans le parcours des paquets. On les pilote avec **nftables** (successeur d'`iptables`), ou via une surcouche : **`ufw`** sous Ubuntu, **`firewalld`** sous Rocky/RHEL (qui s'appuie sur nftables).

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

### `firewalld` : politique « tout refuser en entrée »

Le fonctionnement complet (zones, services, ports, règles riches) est expliqué dans le [cours Réseau, section « firewalld »](../../02-linux-intermediaire/cours/03-reseaux-base.md). Sur Rocky, la zone **`public`** est déjà « refuser tout sauf ce qui est autorisé ».

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --get-default-zone                       # public
sudo firewall-cmd --permanent --add-service=ssh             # AVANT tout rechargement
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="5432" protocol="tcp" accept'   # restreindre à un réseau
sudo firewall-cmd --permanent --add-rich-rule='rule service name="ssh" limit value="10/m" accept'                                         # limite le taux de connexions
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --remove-rich-rule='rule service name="ssh" limit value="10/m" accept' && sudo firewall-cmd --reload
```

> 💡 **Conseil** : `--timeout=60` ouvre un port ou un service temporairement ; `sudo firewall-cmd --panic-on` **coupe tout le trafic** (urgence extrême : ne l'utilisez jamais en SSH !).

### Aperçu de `nftables`

```bash
sudo nft list ruleset | head -30       # firewalld génère ses règles avec nftables
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
sudo dnf remove -y telnet rsh 2>/dev/null
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

## 8. SELinux : contrôle d'accès obligatoire

Les permissions classiques (DAC : propriétaire, groupe, `rwx`) laissent un processus compromis accéder à tout ce que son utilisateur peut atteindre. **SELinux** (*Security-Enhanced Linux*, par défaut sur Rocky/RHEL/Fedora) ajoute un contrôle **obligatoire** (MAC) : chaque **processus** et chaque **fichier** porte une **étiquette** (*contexte*), et une **politique** décrit précisément quelle étiquette de processus peut faire quoi sur quelle étiquette de fichier. Même `root` y est soumis.

> 🐧 **Ubuntu vs Rocky** : Ubuntu utilise **AppArmor** (profils par **chemin de fichier**, `aa-status`, `aa-enforce`, `aa-complain`). Rocky utilise **SELinux** (étiquettes attachées aux fichiers). Même objectif (confiner les programmes), mécanisme différent.

| | AppArmor (Ubuntu) | SELinux (Rocky / RHEL) |
|---|---|---|
| Principe | Profil par programme, basé sur les **chemins** | **Étiquettes** sur processus et fichiers + politique globale |
| Voir l'état | `aa-status` | `getenforce`, `sestatus` |
| Mode strict / apprentissage | `aa-enforce` / `aa-complain` | `setenforce 1` / `setenforce 0` ; `semanage permissive -a` |
| Journal des refus | `journalctl -k \| grep apparmor` | `ausearch -m avc` (`/var/log/audit/audit.log`) |

### 8.1 Les trois modes

| Mode | Comportement |
|---|---|
| **Enforcing** | La politique est **appliquée** : les accès non autorisés sont **bloqués** et journalisés |
| **Permissive** | La politique n'est **pas appliquée** : les accès non autorisés sont seulement **journalisés** (idéal pour apprendre et diagnostiquer) |
| **Disabled** | SELinux est **désactivé** (déconseillé : repasser en *enforcing* exige un réétiquetage complet) |

```bash
getenforce                          # Enforcing | Permissive | Disabled
sestatus                            # état détaillé : mode courant, mode configuré, politique
sudo setenforce 0                   # passe en permissive (immédiat, perdu au redémarrage)
sudo setenforce 1                   # passe en enforcing (immédiat, perdu au redémarrage)
grep -E '^SELINUX=' /etc/selinux/config     # mode au démarrage : enforcing | permissive | disabled
```

Pour rendre un mode **persistant**, on modifie `/etc/selinux/config` (`SELINUX=enforcing`) puis on redémarre. Si on repasse de `disabled` à `enforcing`, il faut d'abord demander un réétiquetage : `sudo touch /.autorelabel && sudo reboot`.

> 📌 **À retenir** : **ne désactivez pas SELinux** pour « faire marcher » un programme. Passez en *permissive* le temps du diagnostic, lisez les refus, corrigez (étiquette, booléen, port), puis revenez en *enforcing*.

> 🐧 **Dans la VM du cours** : la box est livrée en mode **permissive** (réglage persistant dans `/etc/selinux/config`). C'est un choix **pédagogique** : en laboratoire, un refus SELinux imprévu bloquerait des exercices dont ce n'est pas le sujet. Les refus restent **journalisés** (vous pouvez les lire avec `ausearch`). Le passage en *enforcing* est prévu (`TODO` dans `environnement/scripts/03-hardening.sh`) quand le cursus comportera une partie SELinux complète. En production, on vise toujours **enforcing**.

### 8.2 Les contextes (étiquettes)

Un contexte a la forme `utilisateur:rôle:type:niveau`. Dans la politique **targeted** (par défaut), seul le **type** (suffixe `_t`) compte vraiment.

```bash
id -Z                               # contexte de ma session : unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
ls -Z /etc/passwd /var/www /home    # contextes des fichiers
ps -eZ | grep -E 'sshd|chronyd'     # contextes des processus : sshd_t, chronyd_t...
ls -dZ /tmp /root /var/log
```

```text
-rw-r--r--. root root system_u:object_r:passwd_file_t:s0 /etc/passwd
system_u:system_r:sshd_t:s0-s0:c0.c1023  812 ?  00:00:00 sshd
```

Le point final (`.`) après les permissions de `ls -l` indique qu'un contexte SELinux est attaché au fichier.

Règle de base : un processus de type `httpd_t` (serveur web) ne peut lire que des fichiers dont le type est autorisé par la politique (`httpd_sys_content_t`, etc.), **quelles que soient les permissions Unix**.

### 8.3 Étiqueter correctement : `restorecon`, `chcon`, `semanage fcontext`

Cas classique : on déplace des fichiers vers un dossier non standard (`/srv/web`) et le serveur web ne les lit plus (« 403 Forbidden » alors que les permissions sont bonnes).

```bash
sudo mkdir -p /srv/web && echo "<h1>Bonjour</h1>" | sudo tee /srv/web/index.html
ls -Z /srv/web/index.html                    # type : var_t (étiquette par défaut du parent)
matchpathcon /var/www/html/index.html        # quelle étiquette la politique attend-elle ici ?
```

| Commande | Rôle | Durée |
|---|---|---|
| `restorecon -Rv /chemin` | **Remet** l'étiquette prévue par la politique | Selon la politique |
| `chcon -t httpd_sys_content_t fichier` | Change l'étiquette **à la main** | **Temporaire** : perdue au prochain `restorecon` ou réétiquetage |
| `semanage fcontext -a -t <type> "regex"` | **Enregistre** une règle d'étiquetage permanente | **Permanente** (à appliquer avec `restorecon`) |

La méthode correcte et durable :

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/web(/.*)?"   # règle permanente
sudo restorecon -Rv /srv/web                                         # applique l'étiquette
ls -Z /srv/web/index.html                                            # httpd_sys_content_t
sudo semanage fcontext -l | grep '/srv/web'                          # vérification
```

> ⚠️ **Attention** : `semanage` appartient au paquet `policycoreutils-python-utils` (installé dans la VM du cours). `chcon` est pratique pour un essai, mais **ne survit pas** à un réétiquetage : pour une correction durable, utilisez `semanage fcontext` + `restorecon`. Copier un fichier (`cp`) lui donne l'étiquette du dossier de destination, alors que le **déplacer** (`mv`) conserve son ancienne étiquette : c'est la cause n°1 des erreurs SELinux.

### 8.4 Les booléens

Des **booléens** activent ou désactivent des comportements prévus par la politique, sans réécrire celle-ci.

```bash
getsebool -a | grep httpd | head          # booléens liés au serveur web
getsebool httpd_can_network_connect       # httpd_can_network_connect --> off
sudo setsebool -P httpd_can_network_connect on    # -P : persistant (sinon perdu au redémarrage)
sudo semanage boolean -l | grep httpd_can_network_connect    # description et valeurs
```

Exemples : `httpd_can_network_connect` (le serveur web peut joindre le réseau, par exemple une base distante), `httpd_enable_homedirs` (servir les dossiers personnels), `ftp_home_dir`, `samba_enable_home_dirs`.

### 8.5 Ports et politiques : `semanage port`, `semanage permissive`, `semanage login`

```bash
sudo semanage port -l | grep -w http_port_t                  # ports autorisés pour un serveur web
sudo semanage port -a -t http_port_t -p tcp 8081             # autoriser un port non standard
sudo semanage permissive -a httpd_t                          # met UN SEUL domaine en permissive (journalise sans bloquer)
sudo semanage permissive -l                                  # domaines en permissive
sudo semanage permissive -d httpd_t                          # retour en enforcing pour ce domaine
sudo semanage login -l                                       # correspondance utilisateurs Linux → utilisateurs SELinux
sudo semanage user -l                                        # utilisateurs SELinux et leurs rôles
```

`semanage permissive -a <domaine>` est plus fin que `setenforce 0` : seul le programme concerné est en apprentissage, le reste du système reste protégé. C'est l'équivalent d'`aa-complain` sous AppArmor.

### 8.6 Lire les refus : `ausearch`, `audit2why`, `audit2allow`

Chaque refus est un message **AVC** (*Access Vector Cache*) écrit par `auditd` dans `/var/log/audit/audit.log`.

```bash
sudo ausearch -m avc -ts recent                    # refus récents
sudo ausearch -m avc -ts today | audit2why         # explication en clair et piste de solution
sudo ausearch -m avc -ts today | audit2allow       # règle de politique qui autoriserait ces accès
sudo journalctl -t setroubleshoot --since today    # si setroubleshoot-server est installé
```

Exemple de message et de sa traduction :

```text
type=AVC msg=audit(1731000000.123:456): avc:  denied  { read } for  pid=1200 comm="nginx"
  name="index.html" dev="sda3" ino=131073 scontext=system_u:system_r:httpd_t:s0
  tcontext=unconfined_u:object_r:var_t:s0 tclass=file permissive=0
```

→ le processus de type `httpd_t` (`scontext`) s'est vu refuser la lecture (`read`) d'un fichier de type `var_t` (`tcontext`). `permissive=0` : refus **appliqué** (en mode permissive : `permissive=1`, l'accès est autorisé mais journalisé). La bonne correction est ici d'**étiqueter** le fichier (§ 8.3), pas d'élargir la politique.

Dernier recours — créer un petit module de politique personnalisé :

```bash
sudo ausearch -m avc -ts today | audit2allow -M monmodule     # génère monmodule.te et monmodule.pp
sudo semodule -i monmodule.pp                                  # installe le module
sudo semodule -l | grep monmodule
sudo semodule -r monmodule                                     # le retirer
```

> ⚠️ **Attention** : `audit2allow` autorise **tout** ce qui a été refusé, y compris des accès qu'un attaquant pourrait exploiter. Relisez toujours le fichier `.te` produit et préférez : (1) corriger l'étiquette, (2) activer un booléen existant, (3) déclarer le port, **avant** d'écrire un module.

### 8.7 Démarche de diagnostic

1. Le problème disparaît-il en `setenforce 0` ? Si oui, c'est SELinux (remettez `setenforce 1`).
2. `sudo ausearch -m avc -ts recent | audit2why` : lisez la cause.
3. Corrigez dans l'ordre : **étiquette** (`semanage fcontext` + `restorecon`) → **booléen** (`setsebool -P`) → **port** (`semanage port`) → **module** (`audit2allow -M`).
4. Vérifiez, repassez en *enforcing*, documentez.

## 9. Permissions sensibles et audit de fichiers

```bash
ls -l /etc/passwd /etc/shadow /etc/ssh/sshd_config
find / -xdev -perm -4000 -type f 2>/dev/null          # fichiers setuid
find / -xdev -type f -perm -0002 2>/dev/null          # fichiers modifiables par tous
find / -xdev -nouser -o -nogroup 2>/dev/null          # fichiers sans propriétaire
```

### `auditd` : tracer les accès

```bash
rpm -q audit                       # le démon auditd est installé par défaut sur Rocky
sudo systemctl enable --now auditd  # (arrêt/redémarrage : service auditd restart)
sudo auditctl -w /etc/passwd -p wa -k identite       # surveiller écriture/attribut de /etc/passwd
sudo auditctl -w /etc/sudoers.d/ -p wa -k sudo
sudo ausearch -k identite --start today | tail
```

Pour rendre une règle **permanente**, écrivez-la dans `/etc/audit/rules.d/*.rules` (`-w /etc/passwd -p wa -k identite`) puis `sudo augenrules --load`.

## 10. Audit global avec Lynis

```bash
sudo dnf install -y lynis             # dépôt EPEL
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
| Mises à jour | `dnf-automatic` actif | `systemctl is-enabled dnf-automatic-install.timer` |
| SSH | Clés seules, pas de root | `sudo sshd -T \| grep -E "passwordauth\|permitroot"` |
| Pare-feu | `firewalld` actif, zone `public`, services minimaux | `sudo firewall-cmd --list-all` |
| Brute force | `fail2ban` actif | `sudo fail2ban-client status` |
| Services | Seul le nécessaire écoute | `sudo ss -tulpn` |
| Noyau | `sysctl` durci | `sysctl net.ipv4.tcp_syncookies` |
| MAC | SELinux en *enforcing* (en production) | `getenforce` ; `sestatus` |
| Audit | `auditd` / `lynis` | `sudo lynis audit system` |

> 💡 **Conseil** : durcissez par **petites étapes vérifiables**, avec un snapshot et une session de secours ouverte, plutôt qu'en appliquant un script géant que vous ne comprenez pas.

## Résumé

- Principes : **moindre privilège**, **surface minimale**, **défense en profondeur**, **traçabilité**.
- Mettre à jour automatiquement ; verrouiller les comptes inutiles ; politique de mots de passe via PAM.
- SSH par clé + `fail2ban` ; pare-feu **deny par défaut** (`firewalld` au-dessus de netfilter/nftables).
- `sysctl` durcit le noyau ; **SELinux** confine les processus (modes, contextes, booléens, `audit2why`) ; `auditd` et `lynis` auditent.

## Pour aller plus loin

- Référentiels : **CIS Benchmarks** Rocky Linux 9 / RHEL 9, guides de l'ANSSI (« Recommandations de configuration d'un système GNU/Linux »).
- `man nft`, `man firewall-cmd`, `man sysctl`, `man selinux`, `man semanage`, `man auditd`.
- Audit automatisé de conformité : **OpenSCAP** (`oscap`, paquet `scap-security-guide`) ; seccomp ; capabilities (`man 7 capabilities`).
- Atelier associé : [Durcissement d'un serveur](../ateliers/atelier-04-durcissement-serveur.md).
- Module suivant : [Noyau et performance](../../04-linux-expert/cours/01-noyau-performance.md).
