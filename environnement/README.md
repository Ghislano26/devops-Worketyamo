# environnement/ — construction de la box Rocky 9 (formateur)

> 👩‍🏫 **Ce dossier est pour le FORMATEUR.** Les étudiants n'installent pas Packer : ils lisent le
> [**Guide de l'environnement**](../GUIDE-ENVIRONNEMENT.md), téléchargent la box publiée et lancent `vagrant up`.

## Philosophie

- **Reproductibilité** : tout l'environnement est du **code** (kickstart, scripts, Vagrantfile). Reconstruire la box donne le même résultat, et chaque outil est en **version épinglée**.
- **Rocky Linux 9** est **binaire-compatible avec RHEL 9** : on apprend les commandes, les chemins et les outils (`dnf`, `systemd`, `firewalld`, SELinux) rencontrés en entreprise, sans licence.
- **Une seule référence** pour toute la promotion : plus de « ça marche chez moi ».

## Contenu

```text
environnement/
├── README.md                 ce fichier
├── Makefile                  build-box · clean · release (formateur)
├── .gitignore                exclut *.box, packer_cache, output-*, .vagrant/
├── CHEATSHEET.md             aide-mémoire étudiant (imprimable)
├── SCENARIOS.md              situations concrètes pour les étudiants
├── packer/
│   ├── rocky9-devops.pkr.hcl   construction de la box (VirtualBox ; qemu commenté, Linux uniquement)
│   └── http/ks.cfg             kickstart de l'installation automatique
├── scripts/
│   ├── 01-base.sh              paquets de base, git, vim, prompt, Guest Additions
│   ├── 02-devops-tools.sh      kubectl, helm, trivy, syft, act, shellcheck, yq (versions épinglées)
│   └── 03-hardening.sh         firewalld, SSH, SELinux, nettoyage
└── vagrant/
    └── Vagrantfile             utilisé par les étudiants (box rocky9-devops)
```

## Prérequis formateur

| Outil | Version | Remarque |
|---|---|---|
| **VirtualBox** | 7.x | Windows, macOS Intel ou Linux (**pas** Apple Silicon : la box est x86_64) |
| **Packer** | ≥ 1.9 | <https://developer.hashicorp.com/packer/downloads> ; `packer init` télécharge les plugins |
| **make** | indicatif | Linux/macOS natif ; sous **Windows** : Git Bash ou WSL, sinon lancer les commandes à la main (ci-dessous) |
| Disque libre | ≈ 20 Go | Disque virtuel + box finale (≈ 1,5 Go) |
| Connexion | Oui | ISO (≈ 1,7 Go), dépôts Rocky, binaires des outils |

> ⚠️ **Windows** : le pare-feu peut demander l'autorisation à Packer (serveur HTTP temporaire qui sert `ks.cfg` à la VM) : **autorisez-le** sur le réseau privé, sinon l'installation reste bloquée à l'écran du kickstart.

## Construction (15 à 30 minutes)

1. **Renseigner l'empreinte de l'ISO.** Ouvrez le fichier `CHECKSUM` publié à côté de l'ISO (même dossier que l'`iso_url`) et copiez la ligne `SHA256` de `Rocky-9.4-x86_64-minimal.iso` dans `packer/rocky9-devops.pkr.hcl` :

   ```hcl
   variable "iso_checksum" { default = "sha256:<empreinte officielle>" }
   ```

   `make build-box` refuse de démarrer tant que le texte `REMPLACER_PAR_CHECKSUM_OFFICIEL` est présent.

2. **Lancer le build** :

   ```bash
   cd environnement
   make build-box
   ```

   Équivalent sans `make` (PowerShell ou bash) :

   ```bash
   cd environnement/packer
   packer init .
   packer build .
   ```

3. **Résultat** : `environnement/packer/rocky9-devops-1.0.0.box` (≈ 1,5 Go, **ignoré par Git**).

4. **Tester la box avant de la publier** :

   ```bash
   cd environnement
   vagrant box add --name rocky9-devops --force packer/rocky9-devops-1.0.0.box
   cd vagrant && vagrant up        # le provisioning vérifie la présence des 9 outils DevOps
   vagrant ssh -c 'hostname; cat /etc/rocky-release; ls /vagrant | head'
   vagrant destroy -f
   ```

Ce que fait le build, dans l'ordre : installation automatique par **kickstart** → `dnf update` + redémarrage → `01-base.sh` → `02-devops-tools.sh` → `03-hardening.sh` → arrêt → empaquetage en box Vagrant.

> 💡 `rocky_version` désigne l'**ISO de départ**. Comme le build exécute `dnf update`, la box embarque les correctifs 9.x du **jour du build**. Les ISO des versions mineures anciennes sont déplacées dans le *vault* de Rocky (`dl.rockylinux.org/vault/...`) : si l'URL de l'ISO ne répond plus, prenez la version courante sur <https://rockylinux.org/download> et mettez à jour `iso_url`, `iso_checksum` **et** les deux URL de dépôts du `ks.cfg`.

## Distribution

1. Calculer l'empreinte : `sha256sum packer/rocky9-devops-1.0.0.box` (Windows : `Get-FileHash -Algorithm SHA256 <fichier>`).
2. Créer la release sur <https://github.com/Ghislano26/devops-Worketyamo/releases/new> : tag `v1.0.0`, joindre le `.box`, coller le SHA-256 et le changelog.
3. **Noter l'URL** du fichier et la communiquer à la promotion (le guide renvoie vers la page des *Releases*).
4. `make release` affiche ces instructions.

## Mise à jour de la box

1. Incrémenter la version dans **deux** endroits : `box_version` de `packer/rocky9-devops.pkr.hcl` et `config.vm.box_version` de `vagrant/Vagrantfile`.
2. Modifier les scripts (versions des outils en tête de `02-devops-tools.sh`).
3. `make clean && make build-box`, tester, publier une nouvelle release.
4. Compléter l'annexe F de [`GUIDE-ENVIRONNEMENT.md`](../GUIDE-ENVIRONNEMENT.md) (version, date, changements).

## Caractéristiques de la box

| Élément | Valeur |
|---|---|
| Système | Rocky Linux 9 (x86_64), installation minimale + `@core` |
| Disque / RAM / vCPU (box) | 40 Go · 2 Go · 2 (la VM étudiante passe à **4 Go** via le Vagrantfile) |
| Partitions | `/boot` 1 Go (ext4) · swap 2 Go · `/` ext4 (reste) |
| Utilisateur | `vagrant` (mot de passe `vagrant`, mais **connexion SSH par mot de passe désactivée**), `sudo` sans mot de passe ; `root` verrouillé |
| SSH | `PermitRootLogin no`, `PasswordAuthentication no`, clé publique uniquement (durci au 1ᵉʳ redémarrage) |
| Pare-feu | `firewalld` actif, service `ssh` ouvert |
| SELinux | **Permissive** (persistant) — choix pédagogique, voir `03-hardening.sh` |
| Réseau Vagrant | NAT + réseau privé `192.168.56.10` |
| Dossier partagé | `/vagrant` = **racine du dépôt** (type `virtualbox`, Guest Additions installées par `01-base.sh`) |
| Nom d'hôte / VM | `devops-lab` |

### Outils installés

**Paquets de base** (`01-base.sh`, via `dnf`) : `vim`, `nano`, `git`, `curl`, `wget`, `tmux`, `jq`, `tree`, `bash-completion`, `podman`, `buildah`, `skopeo`, `make`, `gcc`, `python3`, `python3-pip`, `rsync`, `unzip`, `tar`.

**Outils DevOps** (`02-devops-tools.sh`, versions épinglées, installés dans `/usr/local/bin`) :

| Outil | Version | Intégrité |
|---|---|---|
| `kubectl` | v1.30.5 | SHA-256 vérifié |
| `helm` | v3.16.1 | SHA-256 vérifié |
| `trivy` | 0.56.1 | SHA-256 vérifié |
| `syft` | v1.14.0 | SHA-256 vérifié |
| `act` | 0.2.68 | SHA-256 vérifié |
| `shellcheck` | v0.10.0 | HTTPS seulement (pas d'empreinte publiée) |
| `yq` | v4.44.3 | HTTPS seulement |

Le `Vagrantfile` vérifie au `vagrant up` la présence de : `kubectl helm trivy syft act shellcheck podman git yq` (**9 outils**).

## Limites et points d'attention

- **Non testé de bout en bout** : ces fichiers ont été validés statiquement (`bash -n`, `shellcheck`, `ruby -c`). Le premier `make build-box` réel est à faire et à corriger si besoin (menu de démarrage de l'ISO, installation des Guest Additions, URL des binaires).
- **x86_64 uniquement** : les Mac Apple Silicon ne peuvent pas utiliser cette box (voir le chapitre 12 du guide).
- **Réseau privé `192.168.56.10`** : sous Linux/macOS, VirtualBox exige que la plage soit autorisée dans `/etc/vbox/networks.conf` (`* 192.168.56.0/21`).
- Les mots de passe `vagrant` de `ks.cfg` sont **ceux de la convention Vagrant** ; la box finale n'accepte que la connexion SSH par clé publique.
