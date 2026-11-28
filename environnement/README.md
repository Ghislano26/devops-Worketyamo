# environnement/ — construis ta propre VM Rocky Linux 9

> 👋 **Ce dossier fournit les fichiers nécessaires pour que TOI tu construises ta propre VM Rocky Linux 9.** Personne ne te distribue de machine toute faite : tu lances une commande, et ta VM se construit toute seule.
> Le guide complet (installation, usage quotidien, dépannage, migration, FAQ) est à la racine : [**GUIDE-ENVIRONNEMENT.md**](../GUIDE-ENVIRONNEMENT.md).

## Philosophie : la « divergence contrôlée »

Une VM unique et identique pour tous n'est plus garantie. À la place, chacun construit sa VM avec **les mêmes ingrédients** :

- une **box publique officielle** `rockylinux/9`, épinglée à une version mineure (`~> 9.4`) ;
- un **provisioning shell idempotent** qui installe toujours les **mêmes outils**, en **versions épinglées** (kubectl, helm, trivy, syft, act, shellcheck, yq) ;
- un **journal de bord** où chacun documente son installation (voir plus bas).

Rocky Linux 9 est **binaire-compatible avec RHEL 9** : tu apprends les commandes, chemins et outils (`dnf`, `systemd`, `firewalld`, SELinux) des serveurs d'entreprise.

## Prérequis (étudiants)

| Outil | Version | Rôle |
|---|---|---|
| **VirtualBox** | 7.x | Fait tourner la VM |
| **Vagrant** | 2.4 ou plus | Construit et pilote la VM |
| Matériel | virtualisation (VT-x / AMD-V) activée, 8 Go de RAM, ≈ 30 Go de disque libre | |
| Connexion Internet | oui (box ≈ 800 Mo + outils) | |

C'est tout : **ni Packer, ni formateur, ni fichier à télécharger à la main.** Les Mac Apple Silicon ne conviennent pas (box x86_64) : voir le chapitre 12 du guide.

## Procédure

```bash
git clone https://github.com/Ghislano26/devops-Worketyamo.git
cd devops-Worketyamo/environnement
make up          # construit la VM (5 à 15 min la première fois)
make ssh         # se connecte à la VM
```

> 🪟 **Windows** : `make` n'est pas installé par défaut. Utilise **Git Bash** ou **WSL**, ou lance directement les commandes équivalentes dans PowerShell :
> `cd vagrant` puis `vagrant up` (et `vagrant ssh`).

| Commande | Équivalent Vagrant | Effet |
|---|---|---|
| `make up` | `cd vagrant && vagrant up` | Construit (la 1ʳᵉ fois) ou démarre la VM |
| `make ssh` | `cd vagrant && vagrant ssh` | Ouvre un shell dans la VM |
| `make halt` | `cd vagrant && vagrant halt` | Éteint proprement la VM |
| `make destroy` | `cd vagrant && vagrant destroy -f` | **Supprime** la VM (⚠️ données de la VM perdues) |
| `make status` | `cd vagrant && vagrant status` | État de la VM |

### Ce qui se passe pendant le `vagrant up`

1. **Téléchargement de la box publique** `rockylinux/9` (≈ 800 Mo, une seule fois ; ensuite elle est en cache).
2. **Création de la VM** dans VirtualBox : 4 Go de RAM, 2 vCPU, réseau NAT + réseau privé `192.168.56.10`, dossier partagé `/vagrant` = **racine du dépôt**.
3. **Exécution automatique des 3 scripts de provisioning** (5 à 15 minutes selon ta connexion) :
   - [`scripts/01-base.sh`](scripts/01-base.sh) : dépôt EPEL, paquets de base (`vim`, `git`, `tmux`, `podman`, `man-db`, `bind-utils`, `sysstat`, `htop`…), prompt, `git` ;
   - [`scripts/02-devops-tools.sh`](scripts/02-devops-tools.sh) : `kubectl`, `helm`, `trivy`, `syft`, `act`, `shellcheck`, `yq` en versions épinglées (empreintes SHA-256 vérifiées quand elles sont publiées) ;
   - [`scripts/03-hardening.sh`](scripts/03-hardening.sh) : `firewalld` (SSH seul), SSH par clé uniquement, SELinux en mode permissif (choix pédagogique).
4. **Vérification finale** : la présence des **9 outils** `kubectl helm trivy syft act shellcheck podman git yq` est contrôlée ; le message `Environnement prêt.` s'affiche.

Les scripts sont **idempotents** : `vagrant provision` les relance sans détruire la VM (et `vagrant provision --provision-with 02-devops-tools` n'en relance qu'un).

## Journal de bord

Chaque étudiant **documente son installation** : copie [`journaux/TEMPLATE.md`](journaux/TEMPLATE.md) vers `journaux/<pseudo>.md` et remplis-le (système, étapes, problèmes rencontrés et solutions). C'est un **livrable du cours**. Détails : [`journaux/README.md`](journaux/README.md).

## Contenu du dossier

```text
environnement/
├── README.md               ce fichier
├── Makefile                make up · ssh · halt · destroy · status
├── CHEATSHEET.md           aide-mémoire imprimable
├── SCENARIOS.md            situations concrètes et leurs solutions
├── vagrant/Vagrantfile     définition de la VM (box rockylinux/9 + provisioning)
├── scripts/                01-base.sh · 02-devops-tools.sh · 03-hardening.sh
├── journaux/               TEMPLATE.md + README.md (+ ton journal)
└── packer-avance/          OPTION AVANCÉE : construire une box custom avec Packer
```

## Outils installés (versions épinglées)

| Outil | Version | | Outil | Version |
|---|---|---|---|---|
| `kubectl` | v1.30.5 | | `act` | 0.2.68 |
| `helm` | v3.16.1 | | `shellcheck` | v0.10.0 |
| `trivy` | 0.56.1 | | `yq` | v4.44.3 |
| `syft` | v1.14.0 | | `podman`, `git` | version du dépôt Rocky |

Les **paquets système** (`dnf`) sont ceux du jour : c'est la part de « divergence contrôlée » : deux étudiants construisant leur VM à des dates différentes peuvent avoir des versions de paquets légèrement différentes, mais les outils DevOps ci-dessus sont identiques.

## Option avancée : Packer

Packer (construire une **box custom** déjà provisionnée) est **optionnel**, relégué dans [`packer-avance/`](packer-avance/README.md). **Tu n'en as pas besoin** pour suivre le cours.

## Limites et points d'attention

- **Non testé de bout en bout** : ces fichiers ont été validés statiquement (`bash -n`, `shellcheck`, `ruby -c`, `make -n`). Le premier `vagrant up` réel est à observer et à corriger si besoin.
- **La box publique est mise à jour par Rocky** : `~> 9.4` accepte toute version `≥ 9.4` et `< 10`. Note la version utilisée (`vagrant box list`) dans ton journal.
- **Réseau privé `192.168.56.10`** : sous Linux/macOS, VirtualBox exige que la plage soit autorisée dans `/etc/vbox/networks.conf` (`* 192.168.56.0/21`).
