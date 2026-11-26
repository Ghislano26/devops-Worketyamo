# Mon serveur d'entraînement — Module 02 : Intermédiaire

Dans ce cursus, **chaque cours doit être pratiqué sur un serveur, pas seulement lu**. Ton serveur d'entraînement est la VM **Ubuntu 24.04 LTS** du [module 00](../00-installation-ubuntu-vm/README.md). Cette page rappelle comment t'y connecter, la protéger (snapshots) et la remettre à zéro.

> 💡 **Conseil** : traite cette VM **comme un vrai serveur distant** : tu t'y connectes en SSH, tu n'utilises pas l'interface graphique de l'hyperviseur. C'est exactement ce que tu feras plus tard en entreprise.

## 1. Se connecter en SSH

### Trouver l'adresse de la VM

Dans la console de la VM :

```bash
ip -br a            # repère l'adresse de l'interface (ex. 192.168.xx.xx ou 10.0.2.15)
whoami              # ton nom d'utilisateur (ex. etudiant)
systemctl is-active ssh      # doit répondre « active »
```

Si `ssh` n'est pas actif : `sudo apt install -y openssh-server && sudo systemctl enable --now ssh`.

### Depuis ta machine hôte

| Hyperviseur / réseau | Commande depuis l'hôte |
|---|---|
| **VMware** (NAT) | `ssh etudiant@<adresse IP de la VM>` (visible avec `ip -br a`) |
| **VirtualBox** (NAT + redirection de port 2222 → 22, voir le [guide](../00-installation-ubuntu-vm/guide-installation-virtualbox.md)) | `ssh -p 2222 etudiant@127.0.0.1` |
| **VirtualBox / VMware** (réseau *Host-only* ou *Bridged*) | `ssh etudiant@<adresse IP de la VM>` |
| Windows | PowerShell ou Windows Terminal : la commande `ssh` est intégrée |

```bash
ssh etudiant@192.168.56.10         # exemple : accepte l'empreinte (yes), saisis le mot de passe
exit                               # (ou Ctrl+D) pour se déconnecter
```

Pour t'éviter de retaper l'adresse, ajoute dans `~/.ssh/config` **de ta machine hôte** :

```text
Host luc
    HostName 127.0.0.1
    Port 2222
    User etudiant
```

Ensuite : `ssh luc`. Passe à la **connexion par clé** dès que tu as fait le [cours SSH du module 02](../02-linux-intermediaire/cours/04-ssh-cles.md) (`ssh-keygen -t ed25519`, `ssh-copy-id`).

## 2. Prendre un snapshot avant chaque jour

**Règle : un snapshot avant chaque jour du parcours.** Convention de nommage : `jour-XX-avant` (ex. `jour-04-avant`).

| Hyperviseur | Interface graphique | Ligne de commande (sur l'hôte) |
|---|---|---|
| **VirtualBox** | Machine → Instantanés → **Prendre** | `VBoxManage snapshot "ubuntu-2404-devops" take "jour-04-avant"` |
| **VMware Workstation / Fusion** | VM → Snapshot → **Take Snapshot…** | `vmrun snapshot "/chemin/vers/ubuntu-2404-devops.vmx" "jour-04-avant"` |

> ⚠️ **Attention** : un snapshot n'est **pas une sauvegarde** (il dépend du disque d'origine) et ralentit la VM s'ils s'empilent. Supprime les snapshots des jours validés et garde `00-installation-propre`. **Copie sur ton hôte** (ou dans un dépôt Git) les scripts que tu veux conserver avant toute restauration.

## 3. Réinitialiser la VM en cas de problème

1. **Tu as cassé quelque chose aujourd'hui** → restaure le snapshot `jour-XX-avant` :
   - VirtualBox : Instantanés → sélectionner → **Restaurer** (ou `VBoxManage snapshot "ubuntu-2404-devops" restore "jour-04-avant"` VM éteinte).
   - VMware : Snapshot Manager → **Go To** (ou `vmrun revertToSnapshot "/chemin/vers/ubuntu-2404-devops.vmx" "jour-04-avant"`).
2. **La VM est dans un état inutilisable depuis plusieurs jours** → restaure `00-installation-propre`, puis rejoue la [checklist post-installation](../00-installation-ubuntu-vm/checklist-post-installation.md) si besoin.
3. **Plus d'accès SSH** (erreur de configuration SSH ou de pare-feu) → ouvre la **console de l'hyperviseur** (la VM reste accessible même sans réseau) et corrige : `sudo ufw disable`, ou `sudo rm /etc/ssh/sshd_config.d/00-durcissement.conf && sudo systemctl reload ssh`. À défaut, restaure le snapshot.
4. **Disque plein** → `df -h`, `du -xh / --max-depth=1 | sort -h | tail`, `sudo apt clean`.

## 4. Exécuter des commandes depuis l'hôte

Tu peux piloter la VM sans ouvrir de session interactive — très utile pour automatiser :

```bash
ssh luc 'uptime && df -h /'                    # une commande ponctuelle
ssh luc 'sudo systemctl status ssh --no-pager | head -5'
scp mon-script.sh luc:~/                       # envoyer un fichier vers la VM
scp luc:~/defi-j1.txt .                        # récupérer un fichier de la VM
rsync -avz ./scripts/ luc:~/scripts/           # synchroniser un dossier
ssh -t luc 'sudo apt update'                   # -t : terminal interactif (nécessaire pour sudo avec mot de passe)
ssh -L 8080:localhost:80 luc                   # tunnel : http://localhost:8080 sur l'hôte → port 80 de la VM
```

Sans alias, remplace `luc` par `-p 2222 etudiant@127.0.0.1` (VirtualBox NAT) ou `etudiant@<IP>`.

## 5. Particularités de ce module

Les jours 3 et 4 modifient le pare-feu et SSH : **gardez une seconde session ouverte** et un snapshot, sinon une erreur peut vous enfermer dehors. Pas de Killercoda pour ces deux jours (réseau et SSH se pratiquent sur **votre** serveur ; le réseau est approfondi au [module 06](../06-reseaux-devops/README.md)).

## Rappel

> 📌 **À retenir** : **chaque cours doit être pratiqué sur ce serveur, pas seulement lu.** Un cours lu et jamais tapé s'oublie en une semaine ; une commande tapée, ratée puis corrigée, ne s'oublie plus.

[← Retour au parcours](PARCOURS.md) · [Checklist](CHECKLIST.md) · [README du module](README.md)
