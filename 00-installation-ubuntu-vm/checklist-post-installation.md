# Checklist post-installation d'Ubuntu 24.04 LTS

À exécuter **une seule fois**, juste après l'installation, avant le premier cours. Toutes les
commandes sont à saisir dans le terminal de la VM (ou en SSH).

> 📌 **À retenir** : `sudo` signifie « exécuter en tant que super-utilisateur ». Le mot de passe demandé est
> **le vôtre**, pas celui de `root`.

## 1. Vérifier le système

```bash
lsb_release -a            # version d'Ubuntu : doit indiquer 24.04
uname -r                  # version du noyau
hostnamectl               # nom d'hôte, architecture, virtualisation
nproc                     # nombre de vCPU (attendu : 4)
free -h                   # mémoire (attendu : ~4 Go)
df -h /                   # espace disque
ip -br a                  # adresses IP
ping -c 2 ubuntu.com      # accès Internet
```

## 2. Mettre à jour le système

```bash
sudo apt update           # rafraîchit la liste des paquets disponibles
sudo apt upgrade -y       # installe les mises à jour
sudo apt autoremove -y    # supprime les paquets devenus inutiles
```

> 💡 **Conseil** : si le message « Waiting for cache lock » apparaît, un processus de mise à jour
> automatique tourne. Patientez quelques minutes.

Si le noyau a été mis à jour, redémarrez :

```bash
[ -f /var/run/reboot-required ] && sudo reboot
```

## 3. Installer les outils de base

```bash
sudo apt install -y \
  vim nano curl wget git tree htop \
  net-tools dnsutils iputils-ping traceroute \
  unzip zip rsync lsof ncdu \
  bash-completion man-db \
  build-essential
```

| Outil | Usage |
|---|---|
| `vim`, `nano` | Éditeurs de texte en console |
| `curl`, `wget` | Téléchargement / requêtes HTTP |
| `git` | Gestion de versions |
| `tree`, `ncdu` | Visualiser l'arborescence / l'usage disque |
| `htop` | Moniteur de processus interactif |
| `net-tools`, `dnsutils` | `ifconfig`, `netstat`, `dig`, `nslookup` |
| `build-essential` | Compilateur `gcc`, `make` |

## 4. Créer un utilisateur administrateur (si besoin)

L'utilisateur créé à l'installation est déjà membre du groupe `sudo`. Vérifiez :

```bash
id                        # doit lister le groupe « sudo »
sudo whoami               # doit afficher « root »
```

Pour créer un utilisateur supplémentaire avec droits `sudo` (utile aux ateliers) :

```bash
sudo adduser admin2                  # crée l'utilisateur et son répertoire personnel
sudo usermod -aG sudo admin2         # l'ajoute au groupe sudo (-a = ajouter, -G = groupe)
id admin2                            # vérification
```

> ⚠️ **Attention** : `usermod -G sudo` **sans** `-a` remplacerait tous les groupes de l'utilisateur.
> Utilisez toujours `-aG`.

## 5. Configurer le fuseau horaire, la langue et le clavier

```bash
sudo timedatectl set-timezone Africa/Douala     # adaptez : Europe/Paris, Africa/Abidjan...
timedatectl                                     # contrôle
sudo dpkg-reconfigure keyboard-configuration    # si le clavier est incorrect
localectl status                                # langue du système
```

## 6. Configurer l'éditeur et l'historique

```bash
# Vim comme éditeur par défaut
sudo update-alternatives --set editor /usr/bin/vim.basic

# Quelques alias confortables
cat >> ~/.bashrc <<'EOF'
alias ll='ls -alh --color=auto'
alias ..='cd ..'
export HISTSIZE=5000
export HISTTIMEFORMAT='%F %T '
EOF
source ~/.bashrc
```

## 7. Vérifier SSH (serveur)

```bash
systemctl status ssh --no-pager       # doit être « active (running) »
ss -tlnp | grep :22                   # le port 22 est à l'écoute
```

## 8. Vérifier le pare-feu (sans l'activer)

```bash
sudo ufw status          # « inactive » est normal à ce stade
```

> ⚠️ **Attention** : n'activez pas `ufw` avant d'avoir autorisé SSH (`sudo ufw allow OpenSSH`). Sinon vous perdez
> votre accès. Nous le ferons proprement au module 03.

## 9. Prendre le snapshot de référence

Éteignez ou laissez la VM allumée, puis dans votre hyperviseur :

- **VMware** : VM → Snapshot → *Take Snapshot* → `00-installation-propre`.
- **VirtualBox** : Machine → Instantanés → *Prendre* → `00-installation-propre`.

## 10. Validation finale

Copiez-collez ce bloc : tout doit afficher `OK`.

```bash
. /etc/os-release
[ "$VERSION_ID" = "24.04" ] && echo "OK  Ubuntu 24.04" || echo "KO  version inattendue : $VERSION_ID"
[ "$(nproc)" -ge 2 ]          && echo "OK  CPU"       || echo "KO  CPU"
ping -c1 -W3 ubuntu.com >/dev/null 2>&1 && echo "OK  Internet" || echo "KO  Internet"
id -nG | grep -qw sudo        && echo "OK  sudo"      || echo "KO  sudo"
command -v git vim curl >/dev/null && echo "OK  outils" || echo "KO  outils"
```

- [ ] Système à jour
- [ ] Outils de base installés
- [ ] Utilisateur avec `sudo` fonctionnel
- [ ] Fuseau horaire et clavier corrects
- [ ] Snapshot `00-installation-propre` créé

## Suite

Vous êtes prêt : [Module 01 — Introduction à Linux](../01-linux-fondamentaux/cours/01-introduction-linux.md).
