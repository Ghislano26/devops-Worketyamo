# Noyau Linux et performance

> 🐧 **Note Red Hat**
> Ce cours utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.

## Pourquoi ce cours ?

Quand une application « rame », la cause se trouve rarement dans l'application seule : saturation CPU,
mémoire qui swappe, disque lent, file d'attente réseau pleine. Un expert sait **mesurer avant d'optimiser**
et connaît les mécanismes du noyau (ordonnanceur, mémoire virtuelle, cache de pages, I/O) qui expliquent ce
qu'il observe. Ce cours donne une méthode et les outils pour diagnostiquer, puis ajuster le noyau avec `sysctl`.

> 📌 **À retenir** : *« L'optimisation prématurée est la racine de tous les maux. »* Mesurez, formulez une hypothèse, changez **une seule chose**, mesurez à nouveau.

## 1. Rôle du noyau

Le noyau s'exécute en **mode privilégié** (*kernel space*) ; vos programmes en **mode utilisateur** (*user space*).
Ils communiquent par des **appels système** (*syscalls*) : `open`, `read`, `write`, `fork`, `mmap`…

```text
  Processus utilisateur              ┌──────────────────────────────┐
  ──── appel système ───────────────►│ Noyau                         │
  (read, write, fork...)             │  Ordonnanceur  Mémoire (VM)   │
                                     │  Système de fichiers  Réseau  │
  ◄──────────── résultat ────────────│  Pilotes (drivers, modules)   │
                                     └──────────────────────────────┘
```

```bash
uname -r                     # version du noyau
lsmod | head                 # modules chargés
modinfo ext4 | head -5       # informations sur un module
sudo modprobe dummy          # charger un module
sudo modprobe -r dummy       # le décharger
dmesg --ctime | tail         # messages du noyau (sudo si dmesg_restrict)
cat /proc/cmdline            # paramètres de démarrage du noyau
strace -c ls /etc > /dev/null   # compte les appels système (paquet strace)
```

## 2. Méthode USE de Brendan Gregg

Pour chaque ressource (CPU, mémoire, disque, réseau), vérifiez :

| Lettre | Question | Exemple pour le CPU |
|---|---|---|
| **U**tilisation | Quel pourcentage est occupé ? | `%CPU` global |
| **S**aturation | Y a-t-il une file d'attente ? | `load average`, *run queue* |
| **E**rreurs | Y a-t-il des erreurs ? | erreurs matérielles, `dmesg` |

## 3. CPU et ordonnancement

Le **CFS** (*Completely Fair Scheduler*, remplacé par **EEVDF** dans les noyaux récents) répartit le temps CPU entre
les processus prêts à s'exécuter.

```bash
uptime                         # load average sur 1, 5, 15 min
nproc                          # nombre de CPU logiques
vmstat 1 5                     # r = file d'exécution ; us/sy/id/wa = user/system/idle/iowait
mpstat -P ALL 1 3              # par cœur (paquet sysstat)
pidstat 1 3                    # par processus
top -H -p <PID>                # par thread
perf top                       # profilage (paquet perf)
```

Interprétation de `vmstat` :

| Colonne | Signification | Alerte |
|---|---|---|
| `r` | Processus prêts à tourner | > nombre de CPU : saturation |
| `b` | Processus bloqués sur E/S | > 0 durable |
| `si`/`so` | Swap in / out | > 0 durable : manque de RAM |
| `wa` | % CPU en attente d'E/S disque | élevé : goulot disque |
| `st` | Temps volé par l'hyperviseur | élevé : VM surchargée |

> 💡 **Conseil** : le *load average* compte aussi les processus bloqués sur E/S disque (état `D`). Un load élevé avec un CPU inactif signale presque toujours un problème de **disque**.

## 4. Mémoire

### Mémoire virtuelle

Chaque processus voit un espace d'adressage **privé et continu**, traduit par le noyau et le matériel (MMU) en mémoire physique par **pages** de 4 Ko.

```text
 Processus A: adresse virtuelle 0x1000 ─┐
                                        ├─ table des pages ─► RAM (page physique)
 Processus B: adresse virtuelle 0x1000 ─┘                      ou swap (disque)
```

```bash
free -h
```

```text
               total   utilisé    libre  partagé  tamp/cache  disponible
Mem:           3,8Gi     900Mi    1,2Gi     12Mi       1,7Gi       2,7Gi
Swap:          2,0Gi        0B    2,0Gi
```

> 📌 **À retenir** : la mémoire « libre » est faible **par conception** : le noyau utilise la RAM restante comme **cache de fichiers** (*page cache*), libérée à la demande. Regardez la colonne **disponible**, pas « libre ».

```bash
cat /proc/meminfo | head -20
vmstat -s | head
ps aux --sort=-%mem | head
smem -tk 2>/dev/null | tail -5       # mémoire proportionnelle (PSS) si smem est installé
cat /proc/<PID>/smaps_rollup         # RSS, PSS d'un processus
sudo slabtop -o | head               # caches du noyau
```

| Mesure | Signification |
|---|---|
| **VSZ** | Mémoire virtuelle réservée (souvent sans signification pratique) |
| **RSS** | Mémoire résidente réellement en RAM |
| **PSS** | RSS avec partage proratisé : la plus juste |

### Swap et `vm.swappiness`

```bash
swapon --show
sysctl vm.swappiness                  # 60 par défaut : tendance à swapper
sudo sysctl vm.swappiness=10          # préfère garder les applications en RAM (serveur)
```

### OOM Killer

Quand la mémoire est épuisée, le noyau déclenche l'**OOM killer**, qui tue le processus jugé le plus « coupable » (`oom_score`).

```bash
dmesg | grep -i "killed process"
journalctl -k | grep -i oom
cat /proc/<PID>/oom_score
echo -1000 | sudo tee /proc/<PID>/oom_score_adj    # protéger un processus critique
```

### Surallocation et `vm.overcommit_memory`

Par défaut (0), Linux accepte d'allouer plus que la mémoire disponible en pariant que tout ne sera pas utilisé.

### Hugepages et NUMA (aperçu)

Les **hugepages** (2 Mo ou 1 Go) réduisent la pression sur la table des pages (bases de données). `cat /proc/meminfo | grep Huge`. Le **NUMA** concerne les serveurs multi-sockets : `numactl --hardware`.

## 5. Disque et entrées/sorties

```bash
iostat -xz 1 3                 # (sysstat) latences et utilisation par disque
pidstat -d 1 3                 # E/S par processus (sysstat) ; alternative : iotop (sudo dnf install iotop, si le dépôt le propose)
sudo blktrace -d /dev/sda      # trace avancée
cat /sys/block/sda/queue/scheduler    # ordonnanceur d'E/S : [mq-deadline] none
df -h ; df -i
```

Colonnes clés d'`iostat -x` :

| Colonne | Signification |
|---|---|
| `r/s`, `w/s` | Lectures/écritures par seconde (IOPS) |
| `rkB/s`, `wkB/s` | Débit |
| `await` / `r_await` / `w_await` | Latence moyenne (ms) : > 10-20 ms sur SSD = suspect |
| `aqu-sz` | Taille moyenne de la file d'attente |
| `%util` | Occupation du périphérique (proche de 100 % : saturé) |

### Cache de pages et écritures différées

Les écritures sont d'abord stockées en mémoire (« pages sales » / *dirty pages*), puis écrites sur disque en arrière-plan.

```bash
grep -E "Dirty|Writeback" /proc/meminfo
sync                                           # force l'écriture
sysctl vm.dirty_ratio vm.dirty_background_ratio
echo 3 | sudo tee /proc/sys/vm/drop_caches     # vide le cache (TESTS UNIQUEMENT)
```

> ⚠️ **Attention** : `drop_caches` n'améliore rien en production : vous détruisez un cache utile. C'est un outil de **benchmark** pour mesurer des lectures « à froid ».

## 6. Réseau

```bash
ss -s                           # statistiques de sockets
ss -tin                         # détails TCP (rtt, cwnd, retrans)
sar -n DEV 1 3                  # débit par interface (sysstat)
ip -s link                      # erreurs/paquets perdus par interface
nstat -az | grep -i retrans     # retransmissions TCP
sysctl net.core.somaxconn       # taille max de la file d'accept()
sysctl net.ipv4.ip_local_port_range
sysctl net.ipv4.tcp_congestion_control   # algorithme (cubic, bbr)
```

## 7. Ajuster le noyau : `sysctl`

Paramètres modifiables à chaud, exposés dans `/proc/sys/`.

```bash
sysctl -a | wc -l                 # nombre total de paramètres
sysctl vm.swappiness              # lecture
sudo sysctl -w vm.swappiness=10   # écriture temporaire
```

Pour **persister** :

```bash
echo "vm.swappiness = 10" | sudo tee /etc/sysctl.d/60-perf.conf
sudo sysctl --system
```

Quelques paramètres courants pour un serveur :

| Paramètre | Effet | Valeur type |
|---|---|---|
| `vm.swappiness` | Propension au swap | 10 (serveur) |
| `vm.dirty_ratio` | % mémoire « sale » avant écriture forcée | 10–20 |
| `net.core.somaxconn` | File d'attente des connexions entrantes | 1024–4096 |
| `net.ipv4.tcp_max_syn_backlog` | File SYN | 2048+ |
| `fs.file-max` | Nombre max de fichiers ouverts (global) | 1 000 000 |
| `net.ipv4.tcp_tw_reuse` | Réutilisation de sockets TIME_WAIT | 1 |

### Limites par processus : `ulimit` et `limits.conf`

```bash
ulimit -a               # limites de la session
ulimit -n               # fichiers ouverts max (1024 par défaut)
cat /proc/<PID>/limits
```

Persistance pour un utilisateur : `/etc/security/limits.d/`. Pour un service systemd : `LimitNOFILE=65535` dans `[Service]`.

## 8. Observation avancée : `/proc`, `perf`, `eBPF`

```bash
cat /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io   # PSI : « pression » ressenti
sudo perf stat -a sleep 2
sudo perf record -F 99 -a -g -- sleep 10 && sudo perf report
sudo dnf install -y bpftrace bcc-tools     # outils eBPF (bcc-tools installe /usr/share/bcc/tools/)
sudo /usr/share/bcc/tools/opensnoop      # fichiers ouverts, en temps réel (Ubuntu : opensnoop-bpfcc)
sudo /usr/share/bcc/tools/execsnoop      # processus lancés (Ubuntu : execsnoop-bpfcc)
```

Les **PSI** (*Pressure Stall Information*) indiquent le temps passé par des tâches à attendre une ressource : métrique très fiable de saturation.

## 9. Une méthode en 60 secondes

```bash
uptime                      # 1. charge globale
dmesg | tail                # 2. erreurs récentes (OOM, disque)
vmstat 1 5                  # 3. CPU, mémoire, swap, E/S
mpstat -P ALL 1 3           # 4. déséquilibre entre cœurs
pidstat 1 3                 # 5. qui consomme ?
iostat -xz 1 3              # 6. disque
free -h                     # 7. mémoire
sar -n DEV 1 3              # 8. réseau
ss -s ; top                 # 9. connexions, vue d'ensemble
```

## 10. Cycle de vie du démarrage et du noyau (aperçu)

```text
UEFI → GRUB → noyau + initramfs → systemd
```

```bash
cat /etc/default/grub                 # options du noyau (GRUB_CMDLINE_LINUX)
sudo grub2-mkconfig -o /boot/grub2/grub.cfg   # régénère la configuration (Ubuntu : update-grub)
sudo grubby --info=ALL | head -n 8             # options des noyaux (grubby modifie aussi : --update-kernel=ALL --args=...)
ls /boot                              # noyaux installés
systemd-analyze blame | head
```

> ⚠️ **Attention** : une erreur dans GRUB peut empêcher le démarrage. Conservez toujours un snapshot de la VM avant de modifier les options du noyau.

## Résumé

- Le noyau arbitre CPU, mémoire, E/S et réseau ; les programmes lui parlent par **appels système**.
- Méthode **USE** : Utilisation, Saturation, Erreurs pour chaque ressource.
- CPU : `vmstat`, `mpstat`, `pidstat` ; mémoire : regardez « disponible », pas « libre » ; disque : `iostat -x` (`await`, `%util`).
- Réglages : `sysctl` (temporaire avec `-w`, permanent dans `/etc/sysctl.d/`), `ulimit`/`LimitNOFILE`.
- Mesurez avant et après **chaque** changement.

## Pour aller plus loin

- Livres et sites : *Systems Performance* (Brendan Gregg), brendangregg.com/linuxperf.html.
- `man proc`, `man sysctl`, `man vmstat`, documentation du noyau (`kernel.org/doc`).
- eBPF, `perf`, flamegraphs, `ftrace`.
- Atelier associé : [Tuning du noyau](../ateliers/atelier-01-tuning-noyau.md).
- Cours suivant : [Conteneurs : namespaces et cgroups](02-conteneurs-namespaces.md).
