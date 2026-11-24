# Cheatsheet — Commandes Linux (Ubuntu 24.04)

Aide-mémoire à garder sous la main. Pour comprendre le *pourquoi*, voir les [cours](../../README.md).

## Aide et système

| Commande | Rôle |
|---|---|
| `man cmd` / `cmd --help` / `help cd` | Aide |
| `apropos mot` | Cherche une commande par mot-clé |
| `type cmd` / `which cmd` | Où est la commande ? |
| `uname -a` / `uname -r` | Noyau |
| `lsb_release -a` / `cat /etc/os-release` | Version d'Ubuntu |
| `hostnamectl` | Nom d'hôte, OS, virtualisation |
| `uptime` | Durée de fonctionnement, charge |
| `date` / `timedatectl` | Date, fuseau, NTP |
| `whoami` / `id` / `groups` | Identité |
| `history` / `Ctrl+R` | Historique / recherche |
| `clear` / `Ctrl+L` | Efface l'écran |
| `sudo !!` | Rejoue la dernière commande avec sudo |
| `reboot` / `poweroff` | Redémarrer / éteindre (`sudo`) |

## Navigation

| Commande | Rôle |
|---|---|
| `pwd` | Répertoire courant |
| `cd dossier` / `cd ..` / `cd ~` / `cd -` | Se déplacer |
| `ls -lah` | Liste détaillée, cachés inclus, tailles lisibles |
| `ls -lt` / `ls -lS` | Tri par date / par taille |
| `tree -L 2` | Arborescence sur 2 niveaux |
| `stat fichier` | Métadonnées (inode, dates) |
| `file fichier` | Type réel du contenu |

## Fichiers et dossiers

| Commande | Rôle |
|---|---|
| `mkdir -p a/b/c` | Crée les dossiers |
| `touch f` | Crée un fichier vide / met à jour la date |
| `cp -a src dst` | Copie en conservant droits et dates |
| `mv a b` | Déplace / renomme |
| `rm -i f` / `rm -r dossier` | Supprime (**sans corbeille**) |
| `ln -s cible lien` / `ln cible lien` | Lien symbolique / physique |
| `cat` `less` `head -n 5` `tail -n 5` `tail -f` | Lire |
| `wc -l` | Compter les lignes |
| `diff a b` | Comparer |
| `tar czf a.tar.gz dossier/` | Archiver et compresser |
| `tar xzf a.tar.gz -C /dest` | Extraire |
| `tar tzf a.tar.gz` | Lister |
| `zip -r a.zip dossier` / `unzip a.zip` | Zip |
| `rsync -avz src/ dst/` | Synchroniser (aussi via SSH) |
| `du -sh *` / `ncdu` | Taille des dossiers |

## Recherche et texte

| Commande | Rôle |
|---|---|
| `find / -name "*.conf" 2>/dev/null` | Trouver par nom |
| `find . -type f -size +10M` | Fichiers > 10 Mo |
| `find . -mtime -1` | Modifiés depuis moins d'un jour |
| `find . -name "*.tmp" -delete` | Trouver puis supprimer |
| `grep -rin "motif" dossier/` | Chercher dans les fichiers |
| `grep -E "a\|b"` / `-v` / `-c` / `-o` | Regex étendue / inverse / compte / partie trouvée |
| `sed 's/a/b/g' f` | Substituer (`-i.bak` pour modifier) |
| `awk '{print $1}' f` | Extraire une colonne |
| `cut -d: -f1 f` | Découper par séparateur |
| `sort` / `sort -n` / `sort -u` | Trier |
| `uniq -c` | Compter les doublons (après `sort`) |
| `tr 'a-z' 'A-Z'` | Convertir |
| `xargs` | Entrée → arguments |
| `tee fichier` | Écrire et laisser passer |

## Redirections et chaînage

| Syntaxe | Effet |
|---|---|
| `cmd > f` / `cmd >> f` | Écrase / ajoute (stdout) |
| `cmd 2> f` | stderr vers un fichier |
| `cmd > f 2>&1` / `cmd &> f` | stdout + stderr |
| `cmd < f` | Entrée depuis un fichier |
| `cmd1 \| cmd2` | Tube |
| `cmd1 && cmd2` | Si succès |
| `cmd1 \|\| cmd2` | Si échec |
| `cmd1 ; cmd2` | Séquence |
| `cmd &` | Arrière-plan |
| `$?` | Code de retour du dernier |
| `$(cmd)` | Substitution de commande |

## Permissions et utilisateurs

| Commande | Rôle |
|---|---|
| `chmod 644 f` / `755` / `600` / `700` | Droits en octal |
| `chmod u+x f` / `g-w f` / `o= f` | Droits symboliques |
| `chmod 2775 d` / `chmod +t d` | setgid / sticky |
| `chown user:groupe f` / `-R` | Propriétaire |
| `umask` | Masque de création |
| `sudo adduser nom` | Crée un utilisateur |
| `sudo usermod -aG groupe user` | Ajoute à un groupe (**-a** !) |
| `sudo passwd user` / `sudo chage -l user` | Mot de passe / expiration |
| `sudo userdel -r user` | Supprime |
| `sudo visudo` / `visudo -f /etc/sudoers.d/x` | Éditer sudoers |
| `getfacl` / `setfacl -m u:alice:rw f` | ACL |
| `su - user` / `sudo -u user cmd` | Changer d'utilisateur |

Octal : `r=4 w=2 x=1` — `7=rwx`, `6=rw-`, `5=r-x`, `4=r--`.

## Processus

| Commande | Rôle |
|---|---|
| `ps aux` / `ps -ef` | Liste |
| `ps aux --sort=-%mem \| head` | Les plus gourmands |
| `top` / `htop` | Moniteur |
| `pstree -p` | Arbre |
| `pgrep -a nom` | Cherche par nom |
| `kill PID` / `kill -9 PID` / `kill -HUP PID` | Signaux (TERM / KILL / recharger) |
| `pkill nom` / `killall nom` | Par nom |
| `jobs` `bg` `fg` `Ctrl+Z` | Tâches du shell |
| `nohup cmd &` | Survit à la déconnexion |
| `nice -n 10 cmd` / `renice -n 5 -p PID` | Priorité |
| `lsof -i :80` / `lsof -p PID` | Fichiers/ports ouverts |

## Mémoire, disque, performance

| Commande | Rôle |
|---|---|
| `free -h` | Mémoire (regardez *disponible*) |
| `vmstat 1 5` | CPU, mémoire, E/S |
| `iostat -xz 1` / `mpstat -P ALL 1` / `pidstat 1` | (paquet `sysstat`) |
| `df -h` / `df -i` | Espace / inodes |
| `lsblk -f` / `blkid` | Disques, UUID |
| `findmnt` / `mount` | Montages |
| `sudo fdisk -l` | Partitions |
| `sudo lsof +L1` | Fichiers supprimés mais ouverts |
| `sysctl -a` / `sysctl -w k=v` | Paramètres du noyau |
| `dmesg --ctime \| tail` | Messages du noyau |

## Réseau

| Commande | Rôle |
|---|---|
| `ip -br a` | Adresses |
| `ip route` / `ip route get 8.8.8.8` | Routes |
| `ip neigh` | Table ARP |
| `ping -c 4 hôte` | Connectivité |
| `traceroute hôte` / `mtr -rw hôte` | Chemin |
| `ss -tulpn` | Ports en écoute |
| `ss -tn state established` | Connexions établies |
| `dig +short A nom` / `resolvectl status` | DNS |
| `curl -I url` / `curl -s -o /dev/null -w "%{http_code}" url` | HTTP |
| `wget url` | Télécharger |
| `nc -zv hôte port` | Tester un port |
| `sudo tcpdump -i any -n port 53` | Capturer |
| `sudo ufw status verbose` | Pare-feu |
| `sudo ufw allow OpenSSH` / `sudo ufw enable` | Autoriser SSH, activer |
| `sudo netplan try` / `netplan apply` | Appliquer la config réseau |
| `ssh user@hôte` / `ssh-keygen -t ed25519` / `ssh-copy-id` | SSH |
| `scp f hôte:/chemin` | Copier via SSH |

## systemd et journaux

| Commande | Rôle |
|---|---|
| `systemctl status svc` | État |
| `sudo systemctl start\|stop\|restart\|reload svc` | Contrôle immédiat |
| `sudo systemctl enable --now svc` | Au démarrage + maintenant |
| `systemctl is-active svc` / `is-enabled svc` | Interrogations |
| `systemctl --failed` | Unités en échec |
| `systemctl list-units --type=service` | Services |
| `systemctl cat svc` / `sudo systemctl edit svc` | Voir / surcharger |
| `sudo systemctl daemon-reload` | Après modification d'une unité |
| `systemctl list-timers` | Minuteurs |
| `systemd-analyze blame` | Démarrage lent |
| `journalctl -u svc -f` | Journaux d'une unité en direct |
| `journalctl -p err -b` | Erreurs depuis le boot |
| `journalctl --since "1 hour ago"` | Période |
| `logger -t etiquette "message"` | Écrire dans le journal |

## Paquets (APT)

| Commande | Rôle |
|---|---|
| `sudo apt update` | Rafraîchir l'index |
| `sudo apt upgrade` / `full-upgrade` | Mettre à jour |
| `sudo apt install -y pkg` | Installer |
| `sudo apt remove pkg` / `purge pkg` | Supprimer (garde / efface la config) |
| `sudo apt autoremove` / `clean` | Nettoyer |
| `apt search mot` / `apt show pkg` / `apt policy pkg` | Rechercher / infos |
| `apt list --installed` / `--upgradable` | Listes |
| `dpkg -L pkg` / `dpkg -S /chemin` | Fichiers d'un paquet / paquet d'un fichier |
| `sudo apt-mark hold pkg` | Geler |
| `sudo apt install ./fichier.deb` | Installer un .deb local |
| `snap list` / `sudo snap install nom` | Snap |

## Stockage LVM

| Commande | Rôle |
|---|---|
| `pvcreate /dev/sdb` / `vgcreate vg /dev/sdb` | PV et VG |
| `lvcreate -n lv -L 5G vg` | Volume logique |
| `mkfs.ext4 /dev/vg/lv` | Formater |
| `lvextend -r -L +2G /dev/vg/lv` | Agrandir (et le FS) |
| `pvs` `vgs` `lvs` | Résumés |
| `mount -a` | Tester `/etc/fstab` |

## Conteneurs et diagnostic avancé

| Commande | Rôle |
|---|---|
| `lsns` / `ls -l /proc/PID/ns` | Namespaces |
| `unshare --pid --fork --mount-proc bash` | Nouveau namespace PID |
| `nsenter -t PID -n ip a` | Entrer dans un namespace |
| `systemd-run -p MemoryMax=100M cmd` | Limiter via cgroup |
| `systemd-cgls` / `systemd-cgtop` | Cgroups |
| `strace -c cmd` | Compter les appels système |
| `docker ps` `logs` `exec -it` `stop` `rm` | Docker |

## Raccourcis du terminal

| Touche | Effet |
|---|---|
| `Tab` | Complétion |
| `Ctrl+C` / `Ctrl+D` / `Ctrl+Z` | Interrompre / fin / suspendre |
| `Ctrl+A` / `Ctrl+E` | Début / fin de ligne |
| `Ctrl+U` / `Ctrl+K` / `Ctrl+W` | Efface avant / après / mot |
| `Ctrl+R` | Recherche dans l'historique |
| `Alt+.` | Dernier argument de la commande précédente |
| `!!` / `!$` | Dernière commande / dernier argument |

> ⚠️ **Attention** : relisez toute commande contenant `rm -r`, `dd`, `mkfs`, `chmod -R` ou `chown -R` avant de valider.

Voir aussi : [Vim](vim.md), [Scripting Bash](bash-scripting.md), [Liens utiles](../liens-utiles.md).
