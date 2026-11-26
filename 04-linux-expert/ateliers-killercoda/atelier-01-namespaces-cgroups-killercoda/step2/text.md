# Étape 2 : limiter les ressources avec un cgroup

Les **cgroups** limitent ce qu'un groupe de processus **consomme**. Ubuntu 24.04 utilise **cgroup v2** (hiérarchie unique dans `/sys/fs/cgroup`) :

```bash
stat -fc %T /sys/fs/cgroup           # cgroup2fs
cat /sys/fs/cgroup/cgroup.controllers
cat /proc/$$/cgroup
```{{exec}}

## À vous de jouer

Créez le cgroup **`luc`** avec : **mémoire maximale 50 Mo**, **20 processus maximum**, **20 % d'un CPU**.

```bash
echo "+cpu +memory +pids" > /sys/fs/cgroup/cgroup.subtree_control
mkdir -p /sys/fs/cgroup/luc
echo 50M         > /sys/fs/cgroup/luc/memory.max
echo 20          > /sys/fs/cgroup/luc/pids.max
echo "20000 100000" > /sys/fs/cgroup/luc/cpu.max
```{{exec}}

Relisez les valeurs (la mémoire est convertie en octets) :

```bash
cat /sys/fs/cgroup/luc/memory.max /sys/fs/cgroup/luc/pids.max /sys/fs/cgroup/luc/cpu.max
```{{exec}}

Placez un processus dans ce groupe et constatez qu'il en dépend :

```bash
sleep 300 &
echo $! > /sys/fs/cgroup/luc/cgroup.procs
cat /proc/$!/cgroup
cat /sys/fs/cgroup/luc/cgroup.procs
```{{exec}}

> `cpu.max` = `quota période` en microsecondes : `20000 100000` = 20 ms toutes les 100 ms = **20 % d'un cœur**. Dépasser `memory.max` déclenche l'**OOM killer** *dans ce groupe*, sans toucher au reste du système.

Cliquez sur **Vérifier**.
