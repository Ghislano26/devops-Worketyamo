# Checklist post-installation de Rocky Linux 9

> 🐧 **Note Red Hat**
> Cette checklist utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.
> **VM `make up`** : une grande partie de ces étapes est déjà faite par les scripts de provisioning (`environnement/scripts/`, voir le [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md)). Cette checklist sert pour une **installation manuelle**.

À exécuter **une seule fois**, juste après l'installation, avant le premier cours. Toutes les
commandes sont à saisir dans le terminal de la VM (ou en SSH).

> 📌 **À retenir** : `sudo` signifie « exécuter en tant que super-utilisateur ». Le mot de passe demandé est
> **le vôtre**, pas celui de `root`.

## 1. Vérifier le système

```bash
cat /etc/rocky-release    # version de Rocky : doit indiquer « Rocky Linux release 9.x »
uname -r                  # version du noyau
hostnamectl               # nom d'hôte, architecture, virtualisation
nproc                     # nombre de vCPU (attendu : 2 ou plus)
free -h                   # mémoire (attendu : ~4 Go)
df -h /                   # espace disque
ip -br a                  # adresses IP
ping -c 2 rockylinux.org  # accès Internet
```

## 2. Mettre à jour le système

```bash
sudo dnf check-update     # liste les mises à jour disponibles (code de sortie 100 s'il y en a)
sudo dnf upgrade -y       # installe les mises à jour
sudo dnf autoremove -y    # supprime les paquets devenus inutiles
```

> 💡 **Conseil** : si le message « Waiting for process with pid … to finish » apparaît, une autre
> transaction DNF tourne. Patientez quelques minutes.

Si le noyau a été mis à jour, redémarrez :

```bash
sudo dnf needs-restarting -r || sudo reboot      # (paquet dnf-utils) code 1 = redémarrage nécessaire
```

## 3. Installer les outils de base

```bash
sudo dnf install -y epel-release          # dépôt EPEL : htop, ncdu, fail2ban, stress-ng, lynis…
sudo dnf install -y \
  vim-enhanced nano curl wget git tree htop \
  net-tools bind-utils iputils traceroute nmap-ncat \
  unzip zip rsync lsof ncdu tmux jq \
  bash-completion man-db man-pages \
  tcpdump strace sysstat psmisc perf \
  policycoreutils-python-utils dnf-utils
sudo dnf groupinstall -y "Development Tools"      # gcc, make… (équivalent de build-essential)
```

| Outil | Usage |
|---|---|
| `vim-enhanced`, `nano` | Éditeurs de texte en console (`vim-minimal` seul fournit juste `vi`) |
| `curl`, `wget` | Téléchargement / requêtes HTTP |
| `git` | Gestion de versions |
| `tree`, `ncdu` | Visualiser l'arborescence / l'usage disque (`ncdu` : EPEL) |
| `htop` | Moniteur de processus interactif (EPEL) |
| `net-tools`, `bind-utils` | `ifconfig`, `netstat` ; `dig`, `nslookup` (Ubuntu : `dnsutils`) |
| `nmap-ncat` | La commande `nc` (Ubuntu : `netcat-openbsd`) |
| `Development Tools` | Compilateur `gcc`, `make` (Ubuntu : `build-essential`) |
| `policycoreutils-python-utils` | `semanage`, `audit2allow` (SELinux) |

## 4. Créer un utilisateur administrateur (si besoin)

L'utilisateur créé à l'installation est déjà membre du groupe `wheel` (si vous avez coché *Make this user administrator*). Vérifiez :

```bash
id                        # doit lister le groupe « wheel »
sudo whoami               # doit afficher « root »
```

> 🐧 Sous Ubuntu, ce groupe s'appelle `sudo` ; sous Rocky/RHEL, c'est **`wheel`**.

Pour créer un utilisateur supplémentaire avec droits `sudo` (utile aux ateliers) :

```bash
sudo useradd -m -s /bin/bash admin2  # crée l'utilisateur et son répertoire personnel
sudo passwd admin2                   # définit son mot de passe (obligatoire : useradd ne le fait pas)
sudo usermod -aG wheel admin2        # l'ajoute au groupe wheel (-a = ajouter, -G = groupe)
id admin2                            # vérification
```

> ⚠️ **Attention** : `usermod -G wheel` **sans** `-a` remplacerait tous les groupes de l'utilisateur.
> Utilisez toujours `-aG`.

## 5. Configurer le fuseau horaire, la langue et le clavier

```bash
sudo timedatectl set-timezone Africa/Douala     # adaptez : Europe/Paris, Africa/Abidjan...
timedatectl                                     # contrôle
sudo localectl set-keymap fr                    # clavier de la console (Ubuntu : dpkg-reconfigure keyboard-configuration)
sudo dnf install -y glibc-langpack-fr           # pack de langue française
sudo localectl set-locale LANG=fr_FR.UTF-8      # langue du système (facultatif : le cours reste lisible en en_US)
localectl status
```

## 6. Configurer l'éditeur et l'historique

```bash
# Quelques alias et réglages confortables (Vim comme éditeur par défaut)
cat >> ~/.bashrc <<'EOF'
alias ll='ls -alh --color=auto'
alias ..='cd ..'
export EDITOR=vim
export HISTSIZE=5000
export HISTTIMEFORMAT='%F %T '
EOF
source ~/.bashrc
```

## 7. Vérifier SSH (serveur)

```bash
systemctl status sshd --no-pager      # doit être « active (running) » (le service s'appelle sshd)
ss -tlnp | grep :22                   # le port 22 est à l'écoute
sudo systemctl enable --now sshd      # si besoin (installez : sudo dnf install -y openssh-server)
```

## 8. Vérifier le pare-feu et SELinux (sans les modifier)

```bash
sudo firewall-cmd --state             # « running » : firewalld est actif par défaut sur Rocky
sudo firewall-cmd --list-services     # doit contenir « ssh »
getenforce                            # « Enforcing » après une installation standard
```

> ⚠️ **Attention** : ne retirez **jamais** le service `ssh` de `firewalld` sur une machine distante, sinon vous perdez
> votre accès. Nous le configurerons proprement au module 02 (réseau) puis au module 03 (durcissement).

> 🐧 La VM `make up` passe SELinux en mode **Permissive** (script `03-hardening.sh`, choix pédagogique) ; une installation manuelle standard est en **Enforcing**. Les deux conviennent pour suivre le cursus : voir la [section SELinux](../03-linux-avance/cours/04-securite-durcissement.md#8-selinux--contrôle-daccès-obligatoire).

## 9. Prendre le snapshot de référence

Éteignez ou laissez la VM allumée, puis dans votre hyperviseur :

- **VMware** : VM → Snapshot → *Take Snapshot* → `00-installation-propre`.
- **VirtualBox** : Machine → Instantanés → *Prendre* → `00-installation-propre`.
- **Vagrant** : `vagrant snapshot save clean`.

## 10. Validation finale

Copiez-collez ce bloc : tout doit afficher `OK`.

```bash
. /etc/os-release
{ [ "$ID" = "rocky" ] && [ "${VERSION_ID%%.*}" = "9" ]; } && echo "OK  Rocky Linux 9" || echo "KO  version inattendue : $ID $VERSION_ID"
[ "$(nproc)" -ge 2 ]          && echo "OK  CPU"       || echo "KO  CPU"
ping -c1 -W3 rockylinux.org >/dev/null 2>&1 && echo "OK  Internet" || echo "KO  Internet"
id -nG | grep -qw wheel       && echo "OK  sudo (wheel)" || echo "KO  sudo (wheel)"
command -v git vim curl >/dev/null && echo "OK  outils" || echo "KO  outils"
systemctl is-active --quiet firewalld && echo "OK  firewalld" || echo "KO  firewalld"
```

- [ ] Système à jour
- [ ] Outils de base installés
- [ ] Utilisateur avec `sudo` fonctionnel
- [ ] Fuseau horaire et clavier corrects
- [ ] Snapshot `00-installation-propre` créé

## Suite

Vous êtes prêt : [Module 01 — Introduction à Linux](../01-linux-fondamentaux/cours/01-introduction-linux.md).
