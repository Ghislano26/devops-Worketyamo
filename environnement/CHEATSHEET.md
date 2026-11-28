# 📋 Cheatsheet de l'environnement (1 page à imprimer)

> Guide complet : [`GUIDE-ENVIRONNEMENT.md`](../GUIDE-ENVIRONNEMENT.md) · Scénarios : [`SCENARIOS.md`](SCENARIOS.md)
> 🖥️ **Hôte** = ton ordinateur · 🐧 **VM** = Rocky Linux 9 (`devops-lab`). Les commandes de cours se tapent **dans la VM**.

## 1. Vagrant (sur l'hôte, dans `environnement/vagrant`)

| Je veux… | Commande |
|---|---|
| Démarrer la VM | `vagrant up` |
| Voir son état | `vagrant status` |
| Me connecter | `vagrant ssh` |
| Quitter la VM | `exit` (ou `Ctrl + D`) |
| Éteindre proprement | `vagrant halt` |
| Mettre en pause / reprendre | `vagrant suspend` / `vagrant resume` |
| Appliquer un changement du Vagrantfile | `vagrant reload` |
| Envoyer un fichier dans la VM | `vagrant upload fichier /home/vagrant/` |
| Exécuter une commande sans me connecter | `vagrant ssh -c 'df -h'` |
| ⚠️ Détruire la VM (données perdues) | `vagrant destroy -f` |
| ⚠️ Tout recréer | `vagrant destroy -f && vagrant up` |

## 2. Snapshots

```bash
vagrant snapshot save <nom>        # créer   (ex. avant-lvm)
vagrant snapshot list              # lister
vagrant snapshot restore <nom>     # restaurer (⚠️ annule ce qui a été fait depuis)
vagrant snapshot delete <nom>      # supprimer
```

**Quand ?** après l'installation (`clean`) · avant LVM, pare-feu, durcissement, `fstab`, `sshd_config`, `sudoers`, `dnf update`.

## 3. Diagnostic (dans la VM)

```bash
hostname && cat /etc/rocky-release     # devops-lab · Rocky Linux release 9.x
systemctl --failed                     # services en échec (0 attendu)
journalctl -p err -b --no-pager | tail # erreurs depuis le démarrage
df -h                                  # disque (alerte > 85 %)
free -h                                # mémoire
uptime                                 # charge
ip -br a                               # réseau
ping -c 2 rockylinux.org               # Internet + DNS
getenforce                             # SELinux
```

## 4. Chemins importants

| Chemin | Signification |
|---|---|
| `/vagrant` | **Dépôt côté hôte**, partagé dans la VM (idéal pour sauvegarder) |
| `/home/vagrant` (`~`) | Ton **home** dans la VM : ton espace de travail |
| `~/ateliers/` | Un sous-dossier par atelier (`m01-a03`…) |
| `/vagrant/mes-travaux/` | Sauvegardes visibles sur l'hôte |
| `~/.vagrant.d/boxes` | Box installées (hôte) |
| `VirtualBox VMs/` | Disques des VM (hôte) |

## 5. Ressources (`Vagrantfile`, puis `vagrant reload`)

```ruby
vb.memory = "4096"   # RAM en Mo (2048 si machine faible)
vb.cpus   = 2        # vCPU
```

## 6. Réflexes

- ✅ **Toujours** travailler **dans la VM** (`hostname` → `devops-lab`).
- ✅ Snapshot **avant** un atelier risqué ; sauvegarde dans `/vagrant/mes-travaux/` **avant** une restauration.
- ✅ `vagrant halt` en fin de journée ; **jamais** de fermeture brutale de VirtualBox.
- ❌ Pas de `dnf update` sans consigne ; pas d'édition du même fichier des deux côtés.
- ⚠️ Atelier sur les permissions / SELinux : travailler dans `~`, **pas** dans `/vagrant`.

## 7. En cas de problème

| Symptôme | Premier réflexe |
|---|---|
| « VT-x is not available » | Activer la virtualisation dans le BIOS/UEFI |
| « Hyper-V must be disabled » / VM lente (Windows) | Voir guide § 10.2 |
| « Box could not be found » | `vagrant box add rocky9-devops rocky9-devops-1.0.0.box` |
| « Permission denied (publickey) » | `vagrant reload` |
| Pas d'Internet dans la VM | `vagrant reload` |
| VM cassée | `vagrant snapshot restore clean` |

## 8. Liens

- Releases (box) : <https://github.com/Ghislano26/devops-Worketyamo/releases>
- Vagrant : <https://developer.hashicorp.com/vagrant/docs> · VirtualBox : <https://www.virtualbox.org/manual/>
- Rocky Linux : <https://docs.rockylinux.org/> · Killercoda : <https://killercoda.com/>
