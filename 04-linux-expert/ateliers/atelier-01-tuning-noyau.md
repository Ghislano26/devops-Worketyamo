# Atelier 01 — Diagnostic de performance et tuning du noyau

## 🎯 Objectifs

- Appliquer la méthode **USE** pour identifier un goulot (CPU, mémoire, disque).
- Utiliser `vmstat`, `iostat`, `pidstat`, `free`, `/proc/pressure`.
- Provoquer et observer une pression mémoire et l'**OOM killer** dans un cadre contrôlé.
- Modifier des paramètres `sysctl` (temporaire puis persistant) et mesurer l'effet.

## 📋 Prérequis

- Modules 01 à 03 terminés.
- Cours lu : [Noyau Linux et performance](../cours/01-noyau-performance.md).
- Paquets : `sudo apt install -y sysstat stress-ng iotop`.
- Snapshot de la VM pris. Terminal **double** (deux fenêtres) recommandé.

> ⚠️ **Attention** : cet atelier sature volontairement la VM. Ne le faites **jamais** sur une machine de production.

## 🧪 Scénario

Le serveur d'application de *Kamer Logistics* « ramait » la nuit dernière. Les équipes soupçonnent tour à tour le
CPU, la mémoire et le disque. Vous allez **reproduire trois pannes** distinctes, apprendre à reconnaître leur signature
dans les outils, puis ajuster le noyau pour une charge de type serveur.

## Étapes

### Étape 1 — La ligne de base (système au repos)

```bash
mkdir -p ~/perf && cd ~/perf
{
  echo "== uptime =="; uptime
  echo "== nproc =="; nproc
  echo "== free -h =="; free -h
  echo "== vmstat =="; vmstat 1 3
  echo "== iostat =="; iostat -xz 1 2
  echo "== PSI =="; grep . /proc/pressure/*
} > base.txt 2>&1
cat base.txt
```

> ❓ **Question 1** : Pourquoi enregistre-t-on l'état « normal » avant de provoquer des pannes ?

### Étape 2 — Panne n°1 : saturation CPU

Terminal A :

```bash
stress-ng --cpu $(nproc) --timeout 40s &
```

Terminal B (pendant les 40 secondes) :

```bash
uptime
vmstat 2 5
mpstat -P ALL 2 2
pidstat -u 2 2 | head -15
cat /proc/pressure/cpu
```

Relevez : `r` (file d'exécution), `us` (user), `id` (idle), la colonne `%CPU` des processus, et la ligne `some avg10` de la pression CPU.

> ❓ **Question 2** : Comment distinguer « le CPU est très utilisé mais tout va bien » de « le CPU est **saturé** » ? Quelle colonne de `vmstat` le montre ?

Attendez la fin du test (`wait`).

### Étape 3 — Panne n°2 : saturation du disque

Terminal A :

```bash
stress-ng --hdd 2 --hdd-bytes 256M --timeout 40s &
```

Terminal B :

```bash
vmstat 2 5                    # observez b, bo, wa
iostat -xz 2 3                # %util, w_await, aqu-sz
sudo iotop -oPb -n 3 2>/dev/null | head -12
cat /proc/pressure/io
uptime                        # load élevé alors que le CPU n'est pas saturé ?
```

> ❓ **Question 3** : Pourquoi le `load average` peut-il être élevé alors que `%idle` est important ? *(Indice : état `D`.)*

```bash
wait
```

### Étape 4 — Panne n°3 : pression mémoire et swap

Observez d'abord la mémoire disponible :

```bash
free -m
swapon --show
sysctl vm.swappiness
```

Provoquez une pression modérée (environ 80 % de la RAM) :

```bash
stress-ng --vm 1 --vm-bytes 80% --timeout 40s &
```

Terminal B :

```bash
watch -n 2 free -m          # Ctrl+C pour quitter
vmstat 2 5                  # si/so : activité de swap
cat /proc/pressure/memory
```

> ❓ **Question 4** : Dans `free`, quelle colonne indique la mémoire réellement disponible pour une nouvelle application ? Pourquoi « libre » est-il trompeur ?

```bash
wait
```

### Étape 5 — Déclencher l'OOM killer dans un cadre contrôlé

On ne sature pas la VM entière : on limite un **cgroup** pour que seul son processus soit tué.

```bash
sudo systemd-run --scope -p MemoryMax=100M --unit=oom-test \
  stress-ng --vm 1 --vm-bytes 300M --vm-keep --timeout 20s
echo "code retour : $?"
journalctl -k --since "2 minutes ago" | grep -iE "oom|killed process|memory cgroup" | tail -5
```

> ❓ **Question 5** : Quel processus a été tué ? Pourquoi l'OOM killer n'a-t-il pas touché au reste du système ?

### Étape 6 — Tuning `sysctl` : lecture et modification temporaire

```bash
sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio
sysctl net.core.somaxconn fs.file-max
sudo sysctl -w vm.swappiness=10
sysctl vm.swappiness
cat /proc/sys/vm/swappiness
```

> ❓ **Question 6** : Que veut dire `vm.swappiness=10` ? Pourquoi est-ce plus adapté à un serveur de base de données qu'une valeur de 60 ?

### Étape 7 — Rendre le réglage persistant

```bash
sudo tee /etc/sysctl.d/60-perf-atelier.conf > /dev/null <<'EOF'
vm.swappiness = 10
net.core.somaxconn = 4096
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
EOF
sudo sysctl --system | grep -E "60-perf|swappiness"
sysctl vm.swappiness net.core.somaxconn
```

> ❓ **Question 7** : Quelle est la différence entre `sysctl -w` et l'écriture dans `/etc/sysctl.d/` ?

### Étape 8 — Les limites de fichiers ouverts

```bash
ulimit -n
cat /proc/$$/limits | grep "open files"
cat > ~/perf/ouvre.sh <<'EOF'
#!/usr/bin/env bash
# ouvre N descripteurs de fichiers pour tester la limite
n=${1:-2000}
for ((i=3; i<n; i++)); do eval "exec $i</dev/null" 2>/dev/null || { echo "Échec au descripteur $i"; exit 1; }; done
echo "$n descripteurs ouverts"
EOF
chmod +x ~/perf/ouvre.sh
~/perf/ouvre.sh 500            # fonctionne
~/perf/ouvre.sh 2000           # échoue avec la limite de 1024
( ulimit -n 4096; ~/perf/ouvre.sh 2000 )
```

> ❓ **Question 8** : Pourquoi un serveur web très sollicité peut-il afficher « Too many open files » ? Où configurer la limite pour un service systemd ? *(Indice : `LimitNOFILE=`.)*

### Étape 9 — Tracer les appels système

```bash
strace -c ls /etc > /dev/null 2> strace-ls.txt; head -12 strace-ls.txt
strace -e trace=openat ls /etc 2>&1 | head -5
```

### Étape 10 — Rédiger le diagnostic

Complétez le tableau suivant dans `~/perf/diagnostic.md` à partir de vos observations :

| Panne | Indicateurs clés | Outil qui l'a révélée | Correctif possible |
|---|---|---|---|
| CPU saturé | `vmstat r` > nproc, `id` ≈ 0 | `vmstat`, `pidstat` | Optimiser / ajouter des CPU / limiter via cgroup |
| Disque saturé | `iostat %util`, `wa` élevé | `iostat`, `iotop` | ... |
| Mémoire | `si/so` > 0, `available` bas | `free`, `vmstat` | ... |

## ✅ Validation

- [ ] `base.txt` contient les mesures de référence.
- [ ] Vous avez observé `r` > `nproc` pendant le test CPU.
- [ ] Vous avez observé `wa` et `%util` élevés pendant le test disque.
- [ ] Le test cgroup a produit une ligne `Killed process` dans `journalctl -k`.
- [ ] `sysctl vm.swappiness` renvoie `10`, y compris après `sudo sysctl --system`.
- [ ] `~/perf/diagnostic.md` est complété.

## 💡 Pour aller plus loin

- **Défi 1** : identifiez, avec `perf top` ou `strace`, ce que fait `stress-ng` pendant qu'il tourne.
- **Défi 2** : testez `tcp_congestion_control=bbr` (`sysctl net.ipv4.tcp_available_congestion_control`).
- **Défi 3** : utilisez `bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[comm] = count(); }'` pendant 10 s.
- **Défi 4** : ajoutez `MemoryHigh=` à l'unité d'un service et observez le ralentissement (*throttling*) avant l'OOM.

Nettoyage : `sudo rm /etc/sysctl.d/60-perf-atelier.conf && sudo sysctl --system`.

---

## 🏆 Défi du jour

**Objectif** : Appliquer la méthode du « diagnostic en 60 secondes » pendant une surcharge CPU et nommer **le coupable**.

**Contexte** : À 3 h du matin, l'astreinte t'appelle : « le serveur rame ». Tu n'as qu'une minute avant l'escalade. Tu dois documenter l'état du système et désigner le processus responsable.

**Consignes** :
- Lance une charge : `stress-ng --cpu 2 --timeout 60s &` (paquet `stress-ng`).
- Pendant qu'elle tourne, produis `~/defi-perf.txt` avec, dans cet ordre : `uptime`, `nproc`, `vmstat 1 3`, `ps aux --sort=-%cpu | head -n 4`, `cat /proc/pressure/cpu`.
- Ajoute une dernière ligne `CONCLUSION : …` qui nomme le processus le plus gourmand et dit si le CPU est **saturé** (file d'exécution `r` supérieure au nombre de CPU, ou `id` proche de 0).
- Attends la fin de la charge et vérifie que la machine est revenue au calme (`uptime`, `pgrep stress-ng`).

**Indices** (à consulter seulement si bloqué) :
- `{ cmd1; cmd2; … } > fichier 2>&1` regroupe les sorties.
- Dans `vmstat`, la colonne `r` (processus prêts) et `id` (CPU inactif) permettent de conclure.
- Le champ `some avg10` de `/proc/pressure/cpu` mesure le temps d'attente du CPU.

**Critères de réussite** :
- [ ] `~/defi-perf.txt` contient la sortie de `uptime`, `vmstat`, la liste de processus et la pression CPU.
- [ ] Le fichier mentionne `stress-ng` parmi les processus les plus gourmands.
- [ ] La ligne `CONCLUSION` nomme `stress-ng` et justifie la saturation par une valeur observée.
- [ ] `pgrep stress-ng` ne renvoie plus rien après 60 s.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
sudo apt install -y stress-ng sysstat
stress-ng --cpu 2 --timeout 60s &
sleep 5
{
  echo "== uptime ==";   uptime
  echo "== nproc ==";    nproc
  echo "== vmstat ==";   vmstat 1 3
  echo "== top CPU ==";  ps aux --sort=-%cpu | head -n 4
  echo "== pression CPU =="; cat /proc/pressure/cpu
} > ~/defi-perf.txt 2>&1
echo "CONCLUSION : stress-ng consomme tout le CPU ; la file d'exécution (colonne r de vmstat) dépasse nproc, le CPU est saturé." >> ~/defi-perf.txt
cat ~/defi-perf.txt
wait
uptime ; pgrep stress-ng || echo "plus de charge"
```

Méthode **USE** (Utilisation, Saturation, Erreurs) : `r` > nombre de CPU = saturation ; `ps --sort=-%cpu` désigne le coupable ; la pression PSI confirme que des tâches attendent le CPU.

</details>

---

Atelier suivant : [Namespaces et cgroups](atelier-02-namespaces-cgroups.md).
