# Conteneurs : namespaces et cgroups

> 🐧 **Note Red Hat**
> Ce cours utilise les commandes **Rocky Linux 9** (binaire-compatible RHEL 9). Si tu croises une documentation Ubuntu (`apt`, `ufw`, AppArmor), sache que l'équivalent Red Hat est `dnf`, `firewalld`, SELinux. Les concepts sont identiques, seule la commande change.

## Pourquoi ce cours ?

Docker, Podman, Kubernetes : tous reposent sur **deux fonctions du noyau Linux**, bien plus anciennes que
Docker lui-même. Un conteneur n'est **pas une machine virtuelle** : c'est un processus Linux ordinaire,
auquel on a donné une *vue* restreinte du système (namespaces) et des *limites* de ressources (cgroups).
Comprendre cela change tout : diagnostic, sécurité, performance. Ce cours démystifie les conteneurs.

> 📌 **À retenir** : **conteneur = processus + namespaces (ce qu'il voit) + cgroups (ce qu'il consomme) + système de fichiers isolé + restrictions de sécurité (capabilities, seccomp, AppArmor)**.

## 1. Machine virtuelle vs conteneur

```text
 Machine virtuelle                         Conteneur
┌─────────┐ ┌─────────┐                ┌─────────┐ ┌─────────┐
│ App A   │ │ App B   │                │ App A   │ │ App B   │
│ Libs    │ │ Libs    │                │ Libs    │ │ Libs    │
│ OS inv. │ │ OS inv. │                └────┬────┘ └────┬────┘
├─────────┴─┴─────────┤                     │ (namespaces + cgroups)
│  Hyperviseur        │                ┌────┴───────────┴────┐
├─────────────────────┤                │  Moteur (Docker)    │
│  Noyau hôte         │                ├─────────────────────┤
└─────────────────────┘                │  UN SEUL noyau hôte │
                                       └─────────────────────┘
```

| | VM | Conteneur |
|---|---|---|
| Noyau | Un par VM | **Partagé** avec l'hôte |
| Démarrage | Dizaines de secondes | Millisecondes |
| Poids | Gigaoctets | Mégaoctets |
| Isolation | Forte (matérielle) | Plus faible (logicielle) |

> ⚠️ **Attention** : le noyau étant **partagé**, une faille du noyau compromet tous les conteneurs. Un conteneur n'est pas une frontière de sécurité aussi solide qu'une VM.

## 2. Les namespaces : isoler la **vue**

Un **namespace** donne à un groupe de processus une vue privée d'une ressource globale.

| Namespace | Option `unshare` | Isole |
|---|---|---|
| **PID** | `--pid` | Numérotation des processus (le premier est le PID 1) |
| **NET** | `--net` | Interfaces, routes, ports, pare-feu |
| **MNT** | `--mount` | Points de montage |
| **UTS** | `--uts` | Nom d'hôte et domaine |
| **IPC** | `--ipc` | Mémoire partagée, files de messages |
| **USER** | `--user` | UID/GID (root dans le conteneur ≠ root hôte) |
| **CGROUP** | `--cgroup` | Vue de la hiérarchie des cgroups |
| **TIME** | `--time` | Horloges monotone/boot (noyau ≥ 5.6) |

### Observer les namespaces

Chaque processus appartient à un namespace de chaque type, visible dans `/proc/<PID>/ns/` :

```bash
ls -l /proc/$$/ns/
lsns                       # liste tous les namespaces du système
lsns -t net
```

```text
lrwxrwxrwx ... net -> 'net:[4026531840]'     ← identifiant du namespace
```

Deux processus avec le **même identifiant** partagent le namespace.

### Créer des namespaces à la main : `unshare`

```bash
# Un shell avec ses propres PID, montages et nom d'hôte (nécessite root)
sudo unshare --pid --fork --mount-proc --uts bash
hostname isole ; hostname        # le changement reste invisible de l'hôte
ps aux                           # seulement les processus du namespace ; bash a le PID 1
exit

# Namespace utilisateur : « root » sans privilèges réels
unshare --user --map-root-user bash
id                               # uid=0(root) ... mais seulement dans ce namespace
exit
```

> 💡 **Conseil** : `--mount-proc` remonte `/proc` dans le nouveau namespace ; sans cela, `ps` afficherait encore les processus de l'hôte (il lit `/proc`).

### Entrer dans le namespace d'un processus : `nsenter`

```bash
sudo nsenter --target <PID> --net --pid ip a      # exécute des commandes dans ses namespaces
```

C'est ce que fait `docker exec` : un processus supplémentaire placé dans les namespaces du conteneur.

### Le namespace réseau en détail

```bash
sudo ip netns add rouge
sudo ip netns exec rouge ip a              # seulement « lo », DOWN
sudo ip link add veth-h type veth peer name veth-r    # câble virtuel (paire veth)
sudo ip link set veth-r netns rouge
sudo ip addr add 10.10.0.1/24 dev veth-h && sudo ip link set veth-h up
sudo ip netns exec rouge ip addr add 10.10.0.2/24 dev veth-r
sudo ip netns exec rouge ip link set veth-r up
sudo ip netns exec rouge ip link set lo up
ping -c 2 10.10.0.2
```

```text
 Hôte                          Namespace « rouge »
┌──────────┐   paire veth    ┌──────────┐
│ veth-h   │◄───────────────►│ veth-r   │
│ 10.10.0.1│                 │ 10.10.0.2│
└──────────┘                 └──────────┘
```

Docker fait exactement la même chose : un pont `docker0` et une paire `veth` par conteneur.

## 3. Les cgroups : limiter la **consommation**

Les **control groups** organisent les processus en hiérarchie et leur appliquent des **limites**, une **comptabilité** et des **priorités**.

Rocky Linux 9 (comme Ubuntu 24.04) utilise **cgroup v2** (hiérarchie unifiée) montée dans `/sys/fs/cgroup` :

```bash
mount | grep cgroup2
stat -fc %T /sys/fs/cgroup          # cgroup2fs
ls /sys/fs/cgroup | head
cat /sys/fs/cgroup/cgroup.controllers      # contrôleurs : cpu memory io pids...
cat /proc/$$/cgroup                        # cgroup de mon shell
```

| Contrôleur | Fichiers principaux | Rôle |
|---|---|---|
| `cpu` | `cpu.max`, `cpu.weight` | Quota (ex. `50000 100000` = 50 % d'un CPU) et poids |
| `memory` | `memory.max`, `memory.high`, `memory.current` | Limite dure, seuil de ralentissement, usage |
| `io` | `io.max`, `io.weight` | Débit / IOPS par périphérique |
| `pids` | `pids.max` | Nombre maximal de processus (anti « fork bomb ») |

### Manipuler un cgroup à la main

```bash
sudo mkdir /sys/fs/cgroup/atelier
echo "+cpu +memory +pids" | sudo tee /sys/fs/cgroup/cgroup.subtree_control
echo "100M"       | sudo tee /sys/fs/cgroup/atelier/memory.max
echo "20000 100000" | sudo tee /sys/fs/cgroup/atelier/cpu.max    # 20 % d'un CPU
echo "50"         | sudo tee /sys/fs/cgroup/atelier/pids.max
echo $$           | sudo tee /sys/fs/cgroup/atelier/cgroup.procs  # place le shell courant dedans
cat /sys/fs/cgroup/atelier/memory.current
```

> ⚠️ **Attention** : sous systemd, c'est **systemd** qui gère l'arborescence des cgroups. Les manipulations manuelles sont pédagogiques ; en pratique, utilisez `systemd-run` ou les directives d'unités.

### Avec systemd

```bash
systemd-run --scope -p MemoryMax=100M -p CPUQuota=20% ./commande     # limites ponctuelles
systemd-run --unit=test --property=MemoryMax=50M sleep 300
systemctl status test
systemd-cgls                  # arborescence des cgroups
systemd-cgtop                 # consommation par cgroup, en direct
```

Dans une unité : `MemoryMax=`, `CPUQuota=`, `TasksMax=`, `IOWeight=`.

### Que se passe-t-il en cas de dépassement ?

- **Mémoire** : au-delà de `memory.max`, l'OOM killer tue un processus **du cgroup** (et non un processus au hasard sur l'hôte). Voir `memory.events`.
- **CPU** : le groupe est **ralenti** (*throttling*), jamais tué (`cpu.stat` : `nr_throttled`).
- **PIDs** : `fork` échoue avec `Resource temporarily unavailable`.

## 4. Le système de fichiers du conteneur

Un conteneur voit une racine différente, construite à partir d'une **image**. Deux mécanismes :

- **`chroot` / `pivot_root`** : change la racine d'un processus.
- **OverlayFS** : empile des couches en lecture seule (image) et une couche d'écriture (conteneur).

```text
 Vue du conteneur (merged)
      ▲
 ┌────┴──────────────┐  ← couche écriture (upperdir) : propre au conteneur
 │ couche 3 : app    │  ┐
 │ couche 2 : libs   │  ├─ lowerdir : images en lecture seule, partagées
 │ couche 1 : rocky  │  ┘
 └───────────────────┘
```

```bash
mkdir -p /tmp/ov/{lower,upper,work,merged}
echo "fichier de la couche basse" > /tmp/ov/lower/a.txt
sudo mount -t overlay overlay -o lowerdir=/tmp/ov/lower,upperdir=/tmp/ov/upper,workdir=/tmp/ov/work /tmp/ov/merged
echo "modifié" | sudo tee /tmp/ov/merged/a.txt
cat /tmp/ov/lower/a.txt ; cat /tmp/ov/upper/a.txt     # l'original est intact (copy-on-write)
sudo umount /tmp/ov/merged
```

### Créer un mini-conteneur « à la main »

```bash
# Racine minimale construite avec dnf (sous Ubuntu : debootstrap)
sudo dnf install --installroot=/srv/rootfs-rocky --releasever=9 --setopt=install_weak_deps=False -y bash coreutils procps-ng
sudo unshare --pid --fork --mount --uts --ipc --net \
     chroot /srv/rootfs-rocky /bin/bash -c 'mount -t proc proc /proc && exec /bin/bash'
```

(Inutile de le refaire à chaque fois : c'est ce que construit, de façon industrialisée, `runc`.)

## 5. Sécurité des conteneurs

Un processus conteneurisé est restreint par plusieurs couches :

| Mécanisme | Rôle |
|---|---|
| **Capabilities** | Découpe les pouvoirs de root en ~40 droits (`CAP_NET_ADMIN`, `CAP_SYS_ADMIN`…). Docker en retire la plupart. |
| **seccomp** | Filtre les appels système autorisés (liste blanche/noire) |
| **SELinux** (Rocky/RHEL) / AppArmor (Ubuntu) | Contrôle d'accès obligatoire (fichiers, réseau) — voir la [section SELinux du cours de durcissement](../../03-linux-avance/cours/04-securite-durcissement.md#8-selinux--contrôle-daccès-obligatoire) |
| **User namespace** | root conteneur ≠ root hôte (mode *rootless*) |
| **Lecture seule** | `--read-only` pour la racine du conteneur |

```bash
capsh --print | head                         # capabilities du shell (paquet libcap2-bin)
grep Cap /proc/$$/status                     # masques de capabilities
getpcaps $$
```

> ⚠️ **Attention** : `docker run --privileged` désactive la plupart de ces protections ; ne l'utilisez que si indispensable. Ne montez jamais `/var/run/docker.sock` dans un conteneur non fiable : cela équivaut à donner **root sur l'hôte**.

## 6. Les couches d'un moteur de conteneurs

```text
docker CLI ─► dockerd ─► containerd ─► runc ─► (namespaces + cgroups + clone/exec) ─► processus
                                        └ standard OCI (Open Container Initiative)
```

`runc` est le composant qui appelle `clone()`, configure namespaces et cgroups, puis `exec` le programme. Podman suit le même modèle sans démon central.

## 7. Diagnostic : « où est mon conteneur ? »

Un conteneur Docker est visible côté hôte comme un processus ordinaire :

```bash
docker run -d --name test --memory 100m --cpus 0.5 nginx
PID=$(docker inspect -f '{{.State.Pid}}' test)
ps -fp "$PID"                              # c'est un processus de l'hôte !
sudo ls -l /proc/$PID/ns                   # ses namespaces
cat /proc/$PID/cgroup                      # son cgroup
cat /sys/fs/cgroup/system.slice/docker-*.scope/memory.max 2>/dev/null   # limite appliquée
sudo nsenter -t "$PID" -n ip a             # sa vue réseau
```

*(Ces commandes de diagnostic prennent tout leur sens après le [cours Docker](../../05-devops-outils/cours/02-docker-fondamentaux.md).)*

## Résumé

- Un conteneur est un **processus Linux** isolé ; le noyau est **partagé** avec l'hôte.
- **Namespaces** (PID, NET, MNT, UTS, IPC, USER, CGROUP, TIME) : limitent ce que le processus **voit**.
- **cgroups v2** : limitent ce qu'il **consomme** (`cpu.max`, `memory.max`, `pids.max`).
- **OverlayFS** : système de fichiers en couches, avec copy-on-write.
- Sécurité : capabilities, seccomp, SELinux (AppArmor sous Ubuntu), user namespaces.
- Outils : `lsns`, `unshare`, `nsenter`, `ip netns`, `systemd-run`, `systemd-cgls`.

## Pour aller plus loin

- `man 7 namespaces`, `man 7 cgroups`, `man unshare`, `man nsenter`, `man 7 capabilities`.
- Spécification **OCI**, `runc`, `containerd`, **Podman** rootless, **gVisor** et **Kata Containers**.
- Série d'articles « Namespaces in operation » sur LWN.net.
- Atelier associé : [Namespaces et cgroups](../ateliers/atelier-02-namespaces-cgroups.md).
- Le mécanisme sous-jacent : [Appels système et transitions user/kernel](04-syscalls-user-kernel.md) (pourquoi un conteneur est une frontière de sécurité, mais pas totale ; `clone`, `unshare`, `setns`, seccomp, capabilities).
- Cours suivant : [Observabilité et logs](03-observabilite-logs.md).
