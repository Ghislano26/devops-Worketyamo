# Mon serveur d'entraînement — Module 04 : Expert

Dans ce cursus, **chaque cours doit être pratiqué sur un serveur, pas seulement lu**. Ton serveur d'entraînement est la VM **Rocky Linux 9** (`devops-lab`), construite par chaque étudiant avec Vagrant (`make up`) : voir le [Guide de l'environnement](../GUIDE-ENVIRONNEMENT.md). Cette page rappelle comment t'y connecter, la protéger (snapshots) et la remettre à zéro. Si tu dois recréer une VM **à la main** (sans Vagrant), la procédure est au [module 00](../00-installation-ubuntu-vm/README.md).

> 💡 **Conseil** : traite cette VM **comme un vrai serveur distant** : tu t'y connectes en SSH, tu n'utilises pas l'interface graphique de l'hyperviseur. C'est exactement ce que tu feras plus tard en entreprise.

## 1. Se connecter en SSH

### Démarrer et entrer dans la VM

Depuis ton ordinateur (hôte), dans le dossier du dépôt :

```bash
cd devops-Worketyamo/environnement/vagrant
vagrant up                 # démarre la VM (ne fait rien si elle tourne déjà)
vagrant ssh                # ouvre un shell dans la VM
```

Dans la VM, vérifie où tu es :

```bash
hostname                   # devops-lab
cat /etc/rocky-release     # Rocky Linux release 9.x
whoami                     # vagrant
ip -br a                   # interface NAT (10.0.2.15) et interface du réseau privé (192.168.56.10)
                           # leurs noms varient selon la box : eth0/eth1, enp0s3/enp0s8, ens33/ens34…
systemctl is-active sshd   # doit répondre « active »
```

Si `sshd` n'est pas actif : `sudo systemctl enable --now sshd` (le service s'appelle **`sshd`** sous Rocky/RHEL, `ssh` sous Ubuntu).

### Autres façons de se connecter

| Méthode | Commande depuis l'hôte |
|---|---|
| **Vagrant** (recommandé) | `vagrant ssh` |
| SSH direct par la redirection de port (NAT) | `ssh -p 2222 -i .vagrant/machines/default/virtualbox/private_key vagrant@127.0.0.1` (depuis `environnement/vagrant`) |
| SSH par le réseau privé | `ssh -i .vagrant/machines/default/virtualbox/private_key vagrant@192.168.56.10` |
| VM recréée à la main (VMware / VirtualBox, module 00) | `ssh <utilisateur>@<adresse IP de la VM>` (visible avec `ip -br a`) |
| Windows | PowerShell ou Windows Terminal : la commande `ssh` est intégrée |

La connexion par **mot de passe** est désactivée dans la box (durcissement) : on se connecte par **clé**, gérée par Vagrant. `vagrant ssh-config` affiche tous les paramètres (hôte, port, clé).

Pour t'éviter de retaper tout cela, ajoute dans `~/.ssh/config` **de ta machine hôte** (le port et le chemin viennent de `vagrant ssh-config`) :

```text
Host luc
    HostName 127.0.0.1
    Port 2222
    User vagrant
    IdentityFile /chemin/vers/devops-Worketyamo/environnement/vagrant/.vagrant/machines/default/virtualbox/private_key
    StrictHostKeyChecking no
```

Ensuite : `ssh luc`. Pour tes **propres** clés, fais le [cours SSH du module 02](../02-linux-intermediaire/cours/04-ssh-cles.md) (`ssh-keygen -t ed25519`, `ssh-copy-id`).

## 2. Prendre un snapshot avant chaque jour

**Règle : un snapshot avant chaque jour du parcours.** Convention de nommage : `jour-XX-avant` (ex. `jour-12-avant`).

| Outil | Commande (sur l'hôte, dans `environnement/vagrant`) |
|---|---|
| **Vagrant** (recommandé) | `vagrant snapshot save "jour-12-avant"` ; `vagrant snapshot list` |
| **VirtualBox (graphique)** | Machine → Instantanés → **Prendre** |
| **VirtualBox (ligne de commande)** | `VBoxManage snapshot "devops-lab" take "jour-12-avant"` |

> ⚠️ **Attention** : un snapshot n'est **pas une sauvegarde** (il dépend du disque d'origine) et ralentit la VM s'ils s'empilent. Supprime les snapshots des jours validés (`vagrant snapshot delete <nom>`) et garde `clean`. **Copie sur ton hôte** (dans `/vagrant/mes-travaux/`, ou dans un dépôt Git) les scripts que tu veux conserver avant toute restauration.

## 3. Réinitialiser la VM en cas de problème

1. **Tu as cassé quelque chose aujourd'hui** → restaure le snapshot `jour-XX-avant` :
   - `vagrant snapshot restore "jour-12-avant"`
   - ou VirtualBox : Instantanés → sélectionner → **Restaurer**.
2. **La VM est dans un état inutilisable depuis plusieurs jours** → `vagrant snapshot restore clean` (le snapshot pris après l'installation), puis rejoue la [checklist post-installation](../00-installation-ubuntu-vm/checklist-post-installation.md) si besoin.
3. **Plus d'accès SSH** (erreur de configuration SSH ou de pare-feu) → ouvre la **console de la VM** dans VirtualBox (connexion `vagrant` / mot de passe `vagrant`, la VM reste accessible sans réseau) et corrige : `sudo systemctl stop firewalld`, ou `sudo rm /etc/ssh/sshd_config.d/00-durcissement.conf && sudo systemctl reload sshd`. À défaut, restaure le snapshot.
4. **Disque plein** → `df -h`, `sudo du -xh / --max-depth=1 | sort -h | tail`, `sudo dnf clean all`.
5. **Dernier recours** → `vagrant destroy -f && vagrant up` (⚠️ perte des données de la VM).

## 4. Exécuter des commandes depuis l'hôte

Tu peux piloter la VM sans ouvrir de session interactive — très utile pour automatiser :

```bash
vagrant ssh -c 'uptime && df -h /'                       # une commande ponctuelle
vagrant ssh -c 'sudo systemctl status sshd --no-pager | head -5'
vagrant upload mon-script.sh /home/vagrant/              # envoyer un fichier vers la VM
ssh luc 'cat ~/defi-j1.txt' > defi-j1.txt                # récupérer un fichier de la VM (avec l'alias « luc »)
rsync -avz -e ssh ./scripts/ luc:~/scripts/              # synchroniser un dossier (ou simplement via /vagrant)
vagrant ssh -- -L 8080:localhost:80                      # tunnel : http://localhost:8080 sur l'hôte → port 80 de la VM
```

Le dossier **`/vagrant`** de la VM est la **racine du dépôt** côté hôte (si `ls /vagrant` est vide, installe `vagrant-vbguest` : voir le guide, § 5.1) : le plus simple pour échanger des fichiers (voir le [guide, chapitre 5](../GUIDE-ENVIRONNEMENT.md#5-partager-des-fichiers-entre-lhôte-et-la-vm)).

## 5. Particularités de ce module

Ce module sature volontairement la VM (CPU, mémoire, disque) et manipule réseau et cgroups : **snapshot avant chaque jour**, et ne le faites jamais sur une machine de production. Les jours 1 et 3 ne sont pas proposés sur Killercoda (mesures de performance et services système : à pratiquer sur **votre** serveur).

## Rappel

> 📌 **À retenir** : **chaque cours doit être pratiqué sur ce serveur, pas seulement lu.** Un cours lu et jamais tapé s'oublie en une semaine ; une commande tapée, ratée puis corrigée, ne s'oublie plus.

[← Retour au parcours](PARCOURS.md) · [Checklist](CHECKLIST.md) · [README du module](README.md)
