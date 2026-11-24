# Gestion des paquets avec APT

## Pourquoi ce cours ?

Installer un logiciel en téléchargeant un `.exe` depuis un site inconnu n'est pas la norme sous Linux.
On utilise un **gestionnaire de paquets** : un outil qui installe, met à jour et supprime les logiciels
depuis des **dépôts** de confiance, en résolvant automatiquement les dépendances et en vérifiant
les signatures. C'est la base de la maintenance et de la sécurité d'un serveur.

## 1. Notions fondamentales

| Terme | Définition |
|---|---|
| **Paquet** | Archive `.deb` contenant les fichiers du logiciel, des métadonnées et des scripts d'installation |
| **Dépendance** | Autre paquet dont celui-ci a besoin pour fonctionner |
| **Dépôt** (*repository*) | Serveur qui publie des paquets et un index signé |
| **Index** | Liste locale des paquets disponibles (`apt update` le rafraîchit) |
| **dpkg** | Outil bas niveau : installe un `.deb` **sans** résoudre les dépendances |
| **APT** | Outil haut niveau : télécharge, résout les dépendances, appelle `dpkg` |

```text
   apt (résolution des dépendances, dépôts)
     └──► dpkg (installation d'un .deb sur le disque)
              └──► /var/lib/dpkg/ (base de données des paquets installés)
```

## 2. Les commandes de base

```bash
sudo apt update                    # télécharge les index des dépôts (aucune installation)
sudo apt upgrade                   # met à jour les paquets installés (sans suppression)
sudo apt full-upgrade              # idem, avec installations/suppressions si nécessaires
sudo apt install nginx             # installe un paquet (et ses dépendances)
sudo apt install -y curl git       # -y : répond oui automatiquement
sudo apt remove nginx              # désinstalle (garde la configuration)
sudo apt purge nginx               # désinstalle ET supprime la configuration
sudo apt autoremove                # supprime les dépendances orphelines
sudo apt clean                     # vide le cache des .deb téléchargés
```

> 📌 **À retenir** : `apt update` **ne met rien à jour** : il rafraîchit seulement la liste de ce qui est disponible. La mise à jour réelle est `apt upgrade`. Faites toujours `update` avant `install`.

### Rechercher et inspecter

```bash
apt search "web server"            # recherche par mot-clé
apt show nginx                     # description, version, dépendances, taille
apt list --installed | wc -l       # nombre de paquets installés
apt list --upgradable              # paquets pouvant être mis à jour
apt policy nginx                   # version installée / candidate / dépôt d'origine
apt-cache depends nginx            # dépendances
apt-cache rdepends nginx           # paquets qui dépendent de lui
```

### Interroger avec `dpkg`

```bash
dpkg -l | grep nginx               # paquets installés correspondant
dpkg -L nginx                      # fichiers installés par le paquet
dpkg -S /usr/sbin/nginx            # à quel paquet appartient ce fichier ?
dpkg -s nginx                      # statut détaillé
```

## 3. Les dépôts : `sources.list`

Ubuntu 24.04 utilise le nouveau format **deb822**, dans `/etc/apt/sources.list.d/ubuntu.sources` :

```bash
cat /etc/apt/sources.list.d/ubuntu.sources
```

```text
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

| Élément | Signification |
|---|---|
| `noble` | Nom de code de la version 24.04 |
| `noble-updates` | Mises à jour ordinaires |
| `noble-security` | Correctifs de sécurité (dépôt `security.ubuntu.com`) |
| `main` | Logiciels libres supportés officiellement par Canonical |
| `universe` | Logiciels libres maintenus par la communauté |
| `restricted` / `multiverse` | Pilotes propriétaires / logiciels non libres |

> ⚠️ **Attention** : plus vous ajoutez de dépôts tiers, plus vous élargissez votre surface d'attaque et le risque de conflits. N'ajoutez un dépôt externe que s'il est officiel et signé.

## 4. Ajouter un dépôt tiers de façon sécurisée

Les paquets sont **signés** avec GPG : APT refuse un paquet dont la signature ne correspond pas à une clé de confiance. La bonne pratique moderne est de stocker la clé dans `/etc/apt/keyrings/` et de la lier **à un seul dépôt** avec `Signed-By` (et non d'utiliser l'ancien `apt-key`, obsolète).

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://exemple.org/cle.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/exemple.gpg
sudo tee /etc/apt/sources.list.d/exemple.sources <<'EOF'
Types: deb
URIs: https://exemple.org/apt
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/exemple.gpg
EOF
sudo apt update
```

*(L'URL ci-dessus est fictive : c'est un modèle à adapter.)*

### PPA

```bash
sudo add-apt-repository ppa:nom/depot
```

Un **PPA** (*Personal Package Archive*) est un dépôt hébergé sur Launchpad. Il n'est pas validé par Canonical : vérifiez la réputation de l'auteur.

## 5. Fonctionnement d'une mise à jour

```text
apt update
 ├─ lit /etc/apt/sources.list.d/*.sources
 ├─ télécharge InRelease (index signé) de chaque dépôt
 ├─ vérifie la signature (GPG)
 └─ stocke les index dans /var/lib/apt/lists/

apt install nginx
 ├─ résout les dépendances (via les index)
 ├─ télécharge les .deb dans /var/cache/apt/archives/
 ├─ vérifie les sommes de contrôle
 └─ dpkg dépaquette, configure, exécute les scripts postinst
```

## 6. Verrous, paquets bloqués et incidents

APT utilise des **verrous** pour éviter deux installations simultanées (`/var/lib/dpkg/lock-frontend`).

```bash
sudo lsof /var/lib/dpkg/lock-frontend     # qui détient le verrou ?
sudo dpkg --configure -a                  # termine une installation interrompue
sudo apt --fix-broken install             # répare les dépendances cassées
```

> ⚠️ **Attention** : ne supprimez **jamais** les fichiers de verrou à la main tant qu'un processus apt/dpkg tourne : vous risquez de corrompre la base `dpkg`.

### Figer une version

```bash
sudo apt-mark hold nginx           # empêche la mise à jour
apt-mark showhold
sudo apt-mark unhold nginx
apt install nginx=1.24.0-2ubuntu7  # version précise (voir apt policy)
```

## 7. Mises à jour automatiques de sécurité

Ubuntu active `unattended-upgrades` par défaut.

```bash
systemctl status unattended-upgrades --no-pager
cat /etc/apt/apt.conf.d/20auto-upgrades
sudo unattended-upgrade --dry-run --debug | tail
```

C'est une protection essentielle pour un serveur exposé. Le redémarrage nécessaire est indiqué par `/var/run/reboot-required`.

## 8. Autres formats : snap et .deb locaux

```bash
snap list                          # applications snap installées
sudo snap install btop             # installe depuis le Snap Store
sudo snap remove btop
sudo apt install ./monpaquet.deb   # installe un .deb local en résolvant les dépendances
```

| | APT (`.deb`) | Snap |
|---|---|---|
| Dépendances | Partagées avec le système | Embarquées (autonome) |
| Isolation | Aucune | Confinement (AppArmor) |
| Mises à jour | Manuelles / `unattended-upgrades` | Automatiques |
| Taille | Légère | Plus lourde |

> 💡 **Conseil** : avant d'installer, simulez avec `apt install -s paquet` : vous voyez ce qui sera ajouté ou supprimé, sans rien modifier.

## Résumé

- **APT** (haut niveau) s'appuie sur **dpkg** (bas niveau) ; les paquets viennent de **dépôts** signés.
- Cycle : `update` → `upgrade` / `install` → `autoremove`.
- `remove` conserve la configuration ; `purge` la supprime.
- Inspecter : `apt show/policy/search`, `dpkg -L/-S`.
- Dépôts tiers : clé GPG dans `/etc/apt/keyrings/` + `Signed-By`.
- `apt-mark hold` fige une version ; `unattended-upgrades` applique les correctifs de sécurité.

## Pour aller plus loin

- `man apt`, `man sources.list`, `man dpkg`, `man apt-secure`.
- Construire un paquet `.deb` (`dpkg-deb --build`).
- Atelier associé : [APT et gestion de paquets](../ateliers/atelier-02-apt-gestion-paquets.md).
- Cours suivant : [Réseau, bases](03-reseaux-base.md).
