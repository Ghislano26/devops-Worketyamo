# Gestion des paquets avec DNF

> 🐧 **Note Red Hat**
> Ce cours utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.

## Pourquoi ce cours ?

Installer un logiciel en téléchargeant un `.exe` depuis un site inconnu n'est pas la norme sous Linux.
On utilise un **gestionnaire de paquets** : un outil qui installe, met à jour et supprime les logiciels
depuis des **dépôts** de confiance, en résolvant automatiquement les dépendances et en vérifiant
les signatures. C'est la base de la maintenance et de la sécurité d'un serveur.

> 💡 **Sous Ubuntu**, on utiliserait `apt` et `dpkg` (paquets `.deb`). **Sous Rocky Linux (et RHEL, Fedora, AlmaLinux)**, on utilise **`dnf`** et **`rpm`** (paquets `.rpm`). La logique est la même ; seuls les noms des commandes et des fichiers changent.

## 1. Notions fondamentales

| Terme | Définition |
|---|---|
| **Paquet** | Archive `.rpm` contenant les fichiers du logiciel, des métadonnées et des scripts d'installation |
| **Dépendance** | Autre paquet dont celui-ci a besoin pour fonctionner |
| **Dépôt** (*repository*) | Serveur qui publie des paquets et des métadonnées signées |
| **Métadonnées** | Liste locale des paquets disponibles (mise en cache, rafraîchie par `dnf makecache`) |
| **rpm** | Outil bas niveau : installe un `.rpm` **sans** résoudre les dépendances automatiquement |
| **DNF** | Outil haut niveau : télécharge, résout les dépendances, appelle `rpm` (successeur de `yum`) |

```text
   dnf (résolution des dépendances, dépôts, historique)
     └──► rpm (installation d'un .rpm sur le disque)
              └──► /var/lib/rpm/ (base de données des paquets installés)
```

> 📌 **À retenir** : la commande `yum` existe encore sur Rocky 9, mais c'est un simple **alias** de `dnf`. Dans la documentation, tu verras les deux : ils sont équivalents.

## 2. Les commandes de base

```bash
sudo dnf check-update              # liste les mises à jour disponibles (aucune installation)
sudo dnf upgrade                   # met à jour tous les paquets installés
sudo dnf install nginx             # installe un paquet (et ses dépendances)
sudo dnf install -y curl git       # -y : répond oui automatiquement
sudo dnf remove nginx              # désinstalle le paquet
sudo dnf autoremove                # supprime les dépendances devenues inutiles
sudo dnf clean all                 # vide le cache (métadonnées et paquets téléchargés)
sudo dnf makecache                 # reconstruit le cache des métadonnées
```

| Ubuntu (`apt`) | Rocky / RHEL (`dnf`) |
|---|---|
| `apt update` | `dnf check-update` (ou `dnf makecache`) |
| `apt upgrade` | `dnf upgrade` |
| `apt install` | `dnf install` |
| `apt remove` / `apt purge` | `dnf remove` (voir la remarque ci-dessous) |
| `apt autoremove` | `dnf autoremove` |
| `apt clean` | `dnf clean all` |
| `apt search` / `apt show` | `dnf search` / `dnf info` |

> 📌 **À retenir** : contrairement à `apt update`, **`dnf` rafraîchit automatiquement ses métadonnées** quand elles sont périmées. `dnf check-update` est une commande de **lecture** : elle ne modifie rien et renvoie le code de sortie **100** s'il existe des mises à jour (0 sinon), pratique dans un script.

> 💡 **`remove` et `purge`** : il n'y a pas de `purge` sous DNF. `dnf remove` supprime les fichiers du paquet ; les fichiers de configuration **modifiés par l'administrateur** sont conservés sous le nom `*.rpmsave`, les autres sont supprimés.

### Rechercher et inspecter

```bash
dnf search "web server"            # recherche par mot-clé (nom et résumé)
dnf info nginx                     # description, version, dépôt d'origine, taille
dnf list installed | wc -l         # nombre de paquets installés
dnf list --upgrades                # paquets pouvant être mis à jour
dnf repoquery --requires nginx     # dépendances d'un paquet
dnf repoquery --whatrequires zlib  # paquets qui dépendent d'un autre
dnf provides /usr/sbin/nginx       # quel paquet fournit ce fichier (même non installé) ?
dnf provides '*/dig'               # quel paquet contient la commande « dig » ?
```

Exemple de sortie :

```text
$ dnf list installed | head -n 4
Installed Packages
NetworkManager.x86_64             1:1.46.0-26.el9_4       @baseos
audit.x86_64                      3.1.2-2.el9             @baseos
bash.x86_64                       5.1.8-9.el9             @anaconda
```

La colonne de droite indique le **dépôt d'origine** (`@baseos`, `@appstream`, `@epel`…).

### Interroger avec `rpm`

```bash
rpm -qa | grep nginx               # paquets installés correspondant (q = query, a = all)
rpm -ql nginx                      # fichiers installés par le paquet
rpm -qf /usr/sbin/nginx            # à quel paquet appartient ce fichier ?
rpm -qi nginx                      # informations détaillées (version, packager, date)
rpm -qc nginx                      # fichiers de configuration du paquet
rpm -V nginx                       # vérifie l'intégrité des fichiers par rapport au paquet
```

| Ubuntu (`dpkg`) | Rocky / RHEL (`rpm`) |
|---|---|
| `dpkg -l \| grep nginx` | `rpm -qa \| grep nginx` |
| `dpkg -L nginx` | `rpm -ql nginx` |
| `dpkg -S /usr/sbin/nginx` | `rpm -qf /usr/sbin/nginx` |
| `dpkg -s nginx` | `rpm -qi nginx` |

> ⚠️ **Attention** : `rpm -ivh paquet.rpm` installe un fichier **sans résoudre les dépendances** ; préférez `sudo dnf install ./paquet.rpm`, qui les installe depuis les dépôts.

## 3. Les dépôts : `/etc/yum.repos.d/`

Les dépôts sont décrits par des fichiers `.repo` dans **`/etc/yum.repos.d/`** (équivalent de `/etc/apt/sources.list.d/`).

```bash
ls /etc/yum.repos.d/
dnf repolist                       # dépôts actifs
dnf repolist --all                 # tous les dépôts, activés ou non
cat /etc/yum.repos.d/rocky.repo | head -n 12
```

```text
[baseos]
name=Rocky Linux $releasever - BaseOS
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
```

| Élément | Signification |
|---|---|
| `[baseos]` | Identifiant du dépôt (utilisé par `--enablerepo` / `--disablerepo`) |
| `mirrorlist` / `baseurl` | Où télécharger : liste de miroirs ou URL directe |
| `gpgcheck=1` | Vérifie la signature de **chaque** paquet |
| `gpgkey` | Clé publique de confiance pour ce dépôt |
| `enabled=1` | Dépôt actif (0 = désactivé) |

Les dépôts principaux de Rocky Linux 9 :

| Dépôt | Contenu |
|---|---|
| **BaseOS** | Système de base : noyau, `systemd`, bibliothèques, outils essentiels |
| **AppStream** | Applications et langages (nginx, PostgreSQL, Python, Node.js…), parfois en **modules** (plusieurs versions) |
| **CRB** (*CodeReady Builder*) | Bibliothèques de développement (désactivé par défaut) |
| **extras** | Paquets complémentaires (`epel-release`, etc.) |
| **EPEL** (*Extra Packages for Enterprise Linux*) | Paquets supplémentaires de la communauté Fedora (`htop`, `fail2ban`, `lynis`, `stress-ng`, `ncdu`…) |

```bash
sudo dnf install -y epel-release   # active EPEL (déjà fait dans la VM du cours)
sudo dnf config-manager --set-enabled crb
```

> ⚠️ **Attention** : plus vous ajoutez de dépôts tiers, plus vous élargissez votre surface d'attaque et le risque de conflits. N'ajoutez un dépôt externe que s'il est officiel et signé.

## 4. Ajouter un dépôt tiers de façon sécurisée

Les paquets `.rpm` sont **signés** avec GPG : DNF refuse un paquet dont la signature ne correspond pas à une clé de confiance (`gpgcheck=1`). Un dépôt tiers s'ajoute en créant un fichier `.repo` qui référence **sa propre clé**.

```bash
sudo tee /etc/yum.repos.d/exemple.repo <<'EOF'
[exemple]
name=Dépôt exemple
baseurl=https://exemple.org/rpm/el9/$basearch
enabled=1
gpgcheck=1
gpgkey=https://exemple.org/cle.gpg
EOF
sudo dnf makecache                 # DNF propose d'importer la clé : vérifiez l'empreinte !
rpm -qa gpg-pubkey*                # clés publiques importées dans la base RPM
```

*(L'URL ci-dessus est fictive : c'est un modèle à adapter.)*

### COPR (équivalent des PPA)

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable utilisateur/projet      # active un dépôt communautaire COPR
```

Un **COPR** est l'équivalent Fedora/Red Hat d'un PPA Ubuntu : un dépôt personnel, **non validé** par le projet. Vérifiez la réputation de l'auteur.

## 5. Fonctionnement d'une mise à jour

```text
dnf makecache / check-update
 ├─ lit /etc/yum.repos.d/*.repo
 ├─ télécharge repomd.xml (index signé) de chaque dépôt
 ├─ vérifie les sommes de contrôle
 └─ stocke les métadonnées dans /var/cache/dnf/

dnf install nginx
 ├─ résout les dépendances (via les métadonnées)
 ├─ télécharge les .rpm (/var/cache/dnf/)
 ├─ vérifie la signature GPG et les sommes de contrôle
 └─ rpm installe, exécute les scriptlets (%post), enregistre dans /var/lib/rpm/
```

Chaque transaction est enregistrée dans un **historique**, ce que `apt` ne propose pas aussi simplement :

```bash
sudo dnf history                   # liste des transactions (ID, commande, date, nombre d'actions)
sudo dnf history info 12           # détail de la transaction n° 12
sudo dnf history undo 12           # annule la transaction 12 (paquets installés → supprimés, et inversement)
```

## 6. Verrous, paquets bloqués et incidents

DNF utilise des **verrous** pour éviter deux transactions simultanées. Message typique :
`Waiting for process with pid 1234 to finish.`

```bash
ps -p 1234 -o pid,etime,cmd        # qui détient le verrou ?
sudo dnf check                     # contrôle la cohérence de la base de paquets
sudo rpm --rebuilddb               # reconstruit la base RPM si elle est corrompue
sudo dnf distro-sync               # resynchronise les paquets avec les dépôts
```

> ⚠️ **Attention** : n'interrompez pas (`kill -9`) une transaction DNF/RPM en cours, et ne supprimez **jamais** les fichiers de verrou à la main : vous risquez de corrompre `/var/lib/rpm/`.

### Figer une version

```bash
sudo dnf install -y python3-dnf-plugin-versionlock
sudo dnf versionlock add nginx     # empêche la mise à jour du paquet
sudo dnf versionlock list
sudo dnf versionlock delete nginx
sudo dnf install nginx-1.20.1      # version précise (voir dnf --showduplicates list nginx)
```

### Modules AppStream (plusieurs versions d'un logiciel)

```bash
dnf module list nginx              # flux (streams) disponibles : 1.22, 1.24...
sudo dnf module enable nginx:1.22  # choisit un flux
sudo dnf install nginx
```

## 7. Mises à jour automatiques de sécurité

Sous Ubuntu, `unattended-upgrades` est actif par défaut. Sous Rocky, on installe et on active **`dnf-automatic`** :

```bash
sudo dnf install -y dnf-automatic
grep -E '^(upgrade_type|apply_updates)' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic-install.timer
systemctl list-timers 'dnf-automatic*' --no-pager
```

Dans `/etc/dnf/automatic.conf`, mettez `upgrade_type = security` (correctifs de sécurité seulement) et `apply_updates = yes`.

```bash
sudo dnf upgrade --security -y     # applique uniquement les correctifs de sécurité
sudo dnf needs-restarting -r       # un redémarrage est-il nécessaire ? (code 1 = oui)
sudo dnf needs-restarting          # quels processus utilisent d'anciennes bibliothèques ?
```

C'est une protection essentielle pour un serveur exposé.

## 8. Autres formats : `.rpm` locaux et Flatpak

```bash
sudo dnf install ./monpaquet.rpm   # installe un .rpm local en résolvant les dépendances
sudo dnf download nginx            # télécharge le .rpm sans l'installer (dnf-plugins-core)
rpm -qpl monpaquet.rpm             # liste le contenu d'un .rpm avant installation
```

Rocky Linux ne fournit pas **Snap**. Pour les applications « autonomes », on utilise plutôt **Flatpak** (surtout sur poste de travail) ou des conteneurs (**Podman**, voir le module Docker). Sur un serveur, le gestionnaire de paquets reste la méthode normale.

> 💡 **Conseil** : avant d'installer, simulez avec `sudo dnf install --assumeno paquet` : vous voyez ce qui sera ajouté ou supprimé, **sans rien modifier**.

## Résumé

- **DNF** (haut niveau) s'appuie sur **rpm** (bas niveau) ; les paquets viennent de **dépôts** décrits dans `/etc/yum.repos.d/` et signés (GPG).
- Cycle : `check-update` → `upgrade` / `install` → `autoremove` ; `dnf` rafraîchit ses métadonnées tout seul.
- `dnf remove` n'a pas de variante `purge` ; `dnf history undo` annule une transaction.
- Inspecter : `dnf info/search/provides/repoquery`, `rpm -qa/-ql/-qf/-qi`.
- Dépôts tiers : fichier `.repo` + `gpgcheck=1` + `gpgkey` ; **EPEL** pour les paquets communautaires ; **COPR** ≈ PPA.
- `dnf versionlock` fige une version ; `dnf-automatic` applique les correctifs de sécurité.

## Pour aller plus loin

- `man dnf`, `man dnf.conf`, `man yum.conf`, `man rpm`, `man dnf-automatic`.
- Construire un paquet `.rpm` (`rpmbuild`, fichier `.spec`).
- Atelier associé : [DNF et gestion de paquets](../ateliers/atelier-02-apt-gestion-paquets.md).
- Cours suivant : [Réseau, bases](03-reseaux-base.md).
