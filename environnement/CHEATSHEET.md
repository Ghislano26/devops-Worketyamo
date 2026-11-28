# 📋 Cheatsheet de l'environnement (1 page à imprimer)

> Guide complet : [`GUIDE-ENVIRONNEMENT.md`](../GUIDE-ENVIRONNEMENT.md) · Scénarios : [`SCENARIOS.md`](SCENARIOS.md) · Journal de bord : [`journaux/`](journaux/README.md)
> 🖥️ **Hôte** = ton ordinateur · 🐧 **VM** = Rocky Linux 9 (`devops-lab`), construite par toi. Les commandes de cours se tapent **dans la VM**.

## 1. `make` (sur l'hôte, dans `environnement/`)

| Commande | Équivalent Vagrant (dans `environnement/vagrant`) | Effet |
|---|---|---|
| `make up` | `vagrant up` | **Construit** (1ʳᵉ fois : 5 à 15 min) ou démarre la VM |
| `make ssh` | `vagrant ssh` | Ouvre un shell dans la VM |
| `make halt` | `vagrant halt` | Éteint proprement la VM |
| `make destroy` | `vagrant destroy -f` | ⚠️ **Supprime** la VM (données de la VM perdues) |
| `make status` | `vagrant status` | État de la VM |

> 🪟 **Windows sans `make`** : Git Bash / WSL, ou `cd vagrant` puis les commandes `vagrant` de la colonne de droite.

## 2. Vagrant (sur l'hôte, dans `environnement/vagrant`)

| Je veux… | Commande |
|---|---|
| Quitter la VM | `exit` (ou `Ctrl + D`) |
| Mettre en pause / reprendre | `vagrant suspend` / `vagrant resume` |
| Appliquer un changement du Vagrantfile | `vagrant reload` |
| **Relancer les scripts** sans détruire la VM | `vagrant provision` |
| Relancer **un seul** script | `vagrant provision --provision-with 02-devops-tools` |
| Envoyer un fichier dans la VM | `vagrant upload fichier /home/vagrant/` |
| Exécuter une commande sans me connecter | `vagrant ssh -c 'df -h'` |
| État de la VM / de **toutes** mes VM | `vagrant status` / `vagrant global-status` |
| Tout recréer | `vagrant destroy -f && make up` |
| Box : installée ? plus récente ? | `vagrant box list` / `vagrant box outdated` |

## 3. Snapshots

```bash
vagrant snapshot save <nom>        # créer   (ex. clean, avant-lvm)
vagrant snapshot list              # lister
vagrant snapshot restore <nom>     # restaurer (⚠️ annule ce qui a été fait depuis)
vagrant snapshot delete <nom>      # supprimer
```

**Quand ?** `clean` : **après `make up` et la validation des 9 outils** · avant LVM, pare-feu, durcissement, `fstab`, `sshd_config`, `sudoers`, `dnf update`.

## 4. Diagnostic (dans la VM)

```bash
hostname && cat /etc/rocky-release     # devops-lab · Rocky Linux release 9.x
systemctl --failed                     # services en échec (0 attendu)
journalctl -p err -b --no-pager | tail # erreurs depuis le démarrage
df -h                                  # disque (alerte > 85 %)
free -h                                # mémoire
uptime                                 # charge
ip -br a                               # réseau
ping -c 2 rockylinux.org               # Internet + DNS
getenforce                             # SELinux (Permissive dans la VM du cours)
```

Les **9 outils** vérifiés par le provisioning : `kubectl helm trivy syft act shellcheck podman git yq`.

## 5. Chemins importants

| Chemin | Signification |
|---|---|
| `/vagrant` | **Dépôt côté hôte**, partagé dans la VM (idéal pour sauvegarder) |
| `/vagrant/mes-travaux/` | Tes sauvegardes, **préservées** même si tu détruis la VM |
| `/home/vagrant` (`~`) | Ton **home** dans la VM (perdu si la VM est détruite) |
| `environnement/journaux/<pseudo>.md` | Ton **journal de bord** (livrable) |
| `~/.vagrant.d/boxes` | Box en cache (hôte) |
| `VirtualBox VMs/` | Disques des VM (hôte) |

## 6. Ressources (`Vagrantfile`, puis `vagrant reload`)

```ruby
vb.memory = "4096"   # RAM en Mo (2048 si machine faible)
vb.cpus   = 2        # vCPU
```

## 7. Réflexes

- ✅ **Toujours** travailler **dans la VM** (`hostname` → `devops-lab`).
- ✅ Snapshot **avant** un atelier risqué ; travailler (ou sauvegarder) dans `/vagrant/mes-travaux/`.
- ✅ `make halt` en fin de journée ; **jamais** de fermeture brutale de VirtualBox.
- ✅ Tenir son **journal de bord** à jour (problèmes + solutions).
- ❌ Pas de `dnf update` sans consigne ; pas d'édition du même fichier des deux côtés.
- ⚠️ Atelier sur les permissions / SELinux / ACL : travailler dans `~`, **pas** dans `/vagrant`.

## 8. En cas de problème

| Symptôme | Premier réflexe |
|---|---|
| « VT-x is not available » | Activer la virtualisation dans le BIOS/UEFI |
| « Hyper-V must be disabled » / VM lente (Windows) | Voir guide § 10.2 |
| Box introuvable / téléchargement interrompu | Relancer `make up` ; `vagrant box add rockylinux/9 --provider virtualbox` |
| Erreur pendant le provisioning | `vagrant provision` ; sinon `make destroy && make up` (scénario 9) |
| « Permission denied (publickey) » | `vagrant reload` |
| Pas d'Internet dans la VM | `vagrant reload` |
| VM cassée | `vagrant snapshot restore clean` |
| `/vagrant` vide | `vagrant plugin install vagrant-vbguest` puis `vagrant reload --provision` |

## 9. Liens

- Box : <https://app.vagrantup.com/rockylinux/boxes/9> · Vagrant : <https://developer.hashicorp.com/vagrant/docs>
- VirtualBox : <https://www.virtualbox.org/manual/> · Rocky Linux : <https://docs.rockylinux.org/> · Killercoda : <https://killercoda.com/>
