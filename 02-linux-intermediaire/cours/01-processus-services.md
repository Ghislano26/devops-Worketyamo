# Processus, signaux et services systemd

## Pourquoi ce cours ?

Un serveur sert à **faire tourner des services** (web, base de données, SSH). Quand un service
ne répond plus, un administrateur doit savoir : quels processus tournent ? lequel consomme la
mémoire ? comment l'arrêter proprement ? pourquoi n'a-t-il pas redémarré ? Ce cours vous donne
le modèle mental des processus et la maîtrise de **systemd**, le gestionnaire de services d'Ubuntu.

## 1. Qu'est-ce qu'un processus ?

Un **programme** est un fichier inerte sur le disque. Un **processus** est ce programme **en cours d'exécution**,
avec sa mémoire, ses fichiers ouverts et son identité.

| Attribut | Signification |
|---|---|
| **PID** | Identifiant unique du processus |
| **PPID** | PID du processus parent |
| **UID/GID** | Utilisateur/groupe qui l'exécute |
| **État** | R (running), S (sleeping), D (attente E/S ininterruptible), T (stoppé), Z (zombie) |
| **Priorité / nice** | Poids vis-à-vis de l'ordonnanceur |

### Naissance d'un processus : `fork` et `exec`

Sous Linux, tout processus est créé par un autre : le parent se **duplique** (`fork`), puis le
clone **remplace son programme** (`exec`). L'ancêtre de tous est le PID 1 : **systemd**.

```text
systemd (PID 1)
 └─ sshd (PID 812)
     └─ sshd: etudiant (PID 2201)
         └─ bash (PID 2210)
             └─ ls (PID 2305)      ← fork() puis exec("/bin/ls")
```

```bash
pstree -p | head -20      # arbre des processus
ps -o pid,ppid,cmd -p $$  # $$ = PID du shell courant
```

> 📌 **À retenir** : un **zombie** (état `Z`) est un processus terminé dont le parent n'a pas encore lu le code de retour. Il ne consomme plus de CPU, seulement une entrée dans la table des processus. On ne « tue » pas un zombie : on corrige ou on arrête son parent.

## 2. Observer les processus

```bash
ps aux                       # tous les processus (style BSD)
ps -ef                       # tous les processus (style System V, avec PPID)
ps aux --sort=-%mem | head   # les plus gourmands en mémoire
ps -o pid,user,%cpu,%mem,cmd -u etudiant   # colonnes choisies
pgrep -a ssh                 # recherche par nom
top                          # moniteur interactif (q pour quitter)
htop                         # version améliorée (F9 pour tuer, F6 pour trier)
```

Lecture de `top` : la ligne `load average` donne la charge moyenne sur 1, 5 et 15 minutes. Une charge supérieure au nombre de vCPU (`nproc`) indique une saturation.

```bash
uptime
nproc
```

## 3. Les signaux

Un **signal** est un message court envoyé à un processus par le noyau ou un autre processus.

| Signal | N° | Effet | Interceptable ? |
|---|---|---|---|
| `SIGTERM` | 15 | Demande **poliment** l'arrêt (nettoyage possible) | Oui |
| `SIGKILL` | 9 | Arrêt **immédiat** forcé par le noyau | **Non** |
| `SIGHUP` | 1 | Souvent : recharger la configuration | Oui |
| `SIGINT` | 2 | Interruption (`Ctrl+C`) | Oui |
| `SIGSTOP` / `SIGCONT` | 19 / 18 | Suspendre / reprendre | STOP : non |

```bash
kill 2305            # envoie SIGTERM (par défaut)
kill -9 2305         # SIGKILL : en dernier recours
kill -HUP 812        # recharge la configuration d'un démon compatible
killall firefox      # par nom
pkill -f "script.sh" # par motif dans la ligne de commande
kill -l              # liste des signaux
```

> ⚠️ **Attention** : `kill -9` ne laisse aucune chance au processus de fermer ses fichiers ou de libérer ses ressources (fichiers temporaires, verrous, transactions). Essayez toujours `SIGTERM` d'abord et attendez quelques secondes.

## 4. Avant-plan, arrière-plan et tâches

```bash
sleep 300                # bloque le terminal
# Ctrl+Z                 # suspend la tâche
bg                       # la relance en arrière-plan
jobs                     # liste les tâches du shell
fg %1                    # ramène la tâche 1 au premier plan
sleep 300 &              # lance directement en arrière-plan
nohup ./script.sh > sortie.log 2>&1 &    # survit à la fermeture du terminal
```

## 5. Priorités : `nice` et `renice`

La valeur **nice** va de −20 (prioritaire) à +19 (très conciliant). Un utilisateur ordinaire ne peut qu'**augmenter** sa valeur.

```bash
nice -n 10 ./traitement-lourd.sh     # lance avec faible priorité
renice -n 5 -p 2305                  # modifie un processus existant
sudo renice -n -5 -p 2305            # augmenter la priorité : root requis
```

## 6. Aperçu de `/proc`

Chaque processus a un dossier `/proc/<PID>/` généré par le noyau :

```bash
ls /proc/$$                         # $$ = PID du shell
cat /proc/$$/status | head -10      # état, mémoire, UID
ls -l /proc/$$/fd                   # descripteurs de fichiers ouverts (0,1,2 = stdin, stdout, stderr)
cat /proc/$$/cmdline | tr '\0' ' '  # ligne de commande
lsof -p $$ | head                   # (paquet lsof) fichiers ouverts
```

## 7. systemd : le gestionnaire de services

**systemd** est le premier processus lancé par le noyau (PID 1). Il démarre les services dans le
bon ordre, en parallèle, les surveille et les redémarre au besoin. Il gère aussi les journaux (`journald`), les minuteurs, les points de montage…

Il manipule des **unités** (*units*), décrites par des fichiers :

| Type d'unité | Extension | Rôle |
|---|---|---|
| Service | `.service` | Un démon ou un programme (`ssh.service`) |
| Socket | `.socket` | Activation à la demande par une connexion |
| Timer | `.timer` | Planification (remplace avantageusement `cron`) |
| Mount | `.mount` | Point de montage |
| Target | `.target` | Groupe d'unités / état du système (`multi-user.target`) |

### Commandes essentielles : `systemctl`

```bash
systemctl status ssh                  # état, PID, derniers logs
sudo systemctl start nginx            # démarrer maintenant
sudo systemctl stop nginx             # arrêter maintenant
sudo systemctl restart nginx          # arrêt + démarrage
sudo systemctl reload nginx           # recharger la config sans coupure (si supporté)
sudo systemctl enable nginx           # démarrer au boot
sudo systemctl disable nginx
sudo systemctl enable --now nginx     # enable + start
systemctl is-active ssh               # active / inactive
systemctl is-enabled ssh
systemctl list-units --type=service --state=running
systemctl list-unit-files --state=enabled
systemctl --failed                    # unités en échec
```

> 📌 **À retenir** : `start/stop` agissent **maintenant**. `enable/disable` agissent **au prochain démarrage**. Les deux sont indépendants.

### Anatomie d'un fichier d'unité

Les unités fournies par les paquets sont dans `/usr/lib/systemd/system/`. Vos unités et surcharges vont dans `/etc/systemd/system/` (prioritaire).

```bash
systemctl cat ssh        # affiche le fichier d'unité effectif
```

Exemple d'unité personnalisée `/etc/systemd/system/monapp.service` :

```ini
[Unit]
Description=Mon application de démonstration
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=etudiant
WorkingDirectory=/home/etudiant/monapp
ExecStart=/usr/bin/python3 -m http.server 8000
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

| Section | Directives importantes |
|---|---|
| `[Unit]` | `Description`, `After=` (ordre), `Requires=`/`Wants=` (dépendances) |
| `[Service]` | `ExecStart` (commande), `Type`, `User`, `Restart`, `Environment` |
| `[Install]` | `WantedBy=` : à quelle cible l'attacher lors d'un `enable` |

Après création ou modification d'un fichier d'unité :

```bash
sudo systemctl daemon-reload          # relit les fichiers d'unité
sudo systemctl enable --now monapp
systemctl status monapp
```

Pour modifier une unité du système sans toucher au fichier d'origine : `sudo systemctl edit ssh` (crée un *drop-in* dans `/etc/systemd/system/ssh.service.d/override.conf`).

### Durcir un service

systemd propose des options de sécurité dans `[Service]` :

```ini
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
```

Évaluez la surface d'exposition d'un service avec `systemd-analyze security monapp`.

### Timers : planifier des tâches

```bash
systemctl list-timers --all
```

Un `.timer` déclenche un `.service` homonyme (ex. `apt-daily.timer` → `apt-daily.service`). Alternative classique : `crontab -e` avec la syntaxe `min heure jour mois jour_semaine commande`.

## 8. Journaux : `journalctl`

Les services écrivent dans le **journal** de systemd, binaire et indexé.

```bash
journalctl -u ssh                     # journaux d'une unité
journalctl -u ssh -f                  # suivi en direct
journalctl -u ssh --since "1 hour ago"
journalctl -p err -b                  # erreurs depuis le dernier boot
journalctl -b -1                      # boot précédent
journalctl --disk-usage
```

> 💡 **Conseil** : en cas de service en échec, lisez d'abord `systemctl status <unité>` (cinq dernières lignes de log), puis `journalctl -xeu <unité>` pour le détail.

## 9. Démarrage du système en bref

```text
Firmware (UEFI) → GRUB → noyau + initramfs → systemd (PID 1) → default.target
```

```bash
systemctl get-default                 # cible par défaut : multi-user.target (serveur) / graphical.target
systemd-analyze                       # durée du démarrage
systemd-analyze blame | head          # services les plus lents
```

## Résumé

- Un **processus** = programme en exécution, identifié par un PID, créé par `fork`+`exec`, ancêtre : **systemd (PID 1)**.
- Observer : `ps`, `top`/`htop`, `pstree`, `/proc`.
- Signaux : `SIGTERM` (15) d'abord, `SIGKILL` (9) en dernier recours, `SIGHUP` pour recharger.
- Tâches : `&`, `Ctrl+Z`, `bg`, `fg`, `nohup`.
- **systemd** gère des unités : `systemctl start|stop|restart|enable|status`.
- Une unité personnalisée : fichier dans `/etc/systemd/system/`, puis `daemon-reload`.
- Les logs se lisent avec `journalctl -u <unité>`.

## Pour aller plus loin

- `man systemd.service`, `man systemd.unit`, `man journalctl`, `man 7 signal`.
- Les **cgroups** de systemd (approfondis dans le [module expert](../../04-linux-expert/cours/02-conteneurs-namespaces.md)).
- Atelier associé : [Processus et systemd](../ateliers/atelier-01-processus-systemd.md).
- Cours suivant : [Gestion des paquets](02-gestion-paquets.md).
