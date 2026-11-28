# Atelier 02 — Construire un conteneur à la main : namespaces et cgroups

## 🎯 Objectifs

- Observer les namespaces d'un processus et utiliser `unshare` / `nsenter`.
- Isoler le réseau avec un namespace NET et une paire `veth`.
- Limiter CPU, mémoire et nombre de processus avec les **cgroups v2**.
- Assembler le tout en un « conteneur » minimal, sans Docker.

## 📋 Prérequis

- Atelier [01 — Tuning du noyau](atelier-01-tuning-noyau.md) terminé.
- Cours lu : [Conteneurs : namespaces et cgroups](../cours/02-conteneurs-namespaces.md).
- Paquets : `stress-ng` (EPEL), `iproute`, `util-linux`, `iptables-nft` : déjà installés dans la VM du cours ; sinon `sudo dnf install -y epel-release stress-ng iproute util-linux iptables-nft`.
- Snapshot de la VM pris. Droits `sudo`.

## 🧪 Scénario

L'équipe de *Kamer Logistics* migre vers les conteneurs et vous demande : « C'est de la magie, Docker ? » Vous allez
démontrer que non : en une heure, vous construisez un conteneur avec les seules fonctions du noyau Linux, puis vous
prouvez qu'il est limité en ressources et isolé du reste du système.

## Étapes

### Partie A — Observer les namespaces

```bash
ls -l /proc/$$/ns/
lsns | head
readlink /proc/$$/ns/pid /proc/1/ns/pid
```

> ❓ **Question 1** : Les deux `readlink` renvoient-ils le même identifiant ? Que cela signifie-t-il ?

### Partie B — Namespaces PID, UTS et MNT avec `unshare`

```bash
sudo unshare --pid --fork --mount-proc --uts bash
```

Dans ce nouveau shell, exécutez :

```bash
echo "PID de mon shell : $$"
hostname
hostname prison
hostname
ps aux
ls -l /proc/$$/ns/pid
exit
```

De retour sur l'hôte :

```bash
hostname        # inchangé
```

> ❓ **Question 2** : Pourquoi le shell a-t-il le PID 1 dans le namespace ? Pourquoi `ps aux` ne montre-t-il que quelques processus ?
> ❓ **Question 3** : Que se passe-t-il si on omet `--mount-proc` ? Testez et comparez la sortie de `ps aux`.

### Partie C — Vu depuis l'hôte, c'est un processus comme un autre

Terminal A :

```bash
sudo unshare --pid --fork --mount-proc --uts sleep 600 &
```

Terminal B :

```bash
pgrep -a sleep
PID=$(pgrep -f "sleep 600" | tail -1); echo "PID côté hôte = $PID"
sudo ls -l /proc/$PID/ns/pid /proc/$$/ns/pid
sudo cat /proc/$PID/status | grep -E "NSpid|Name"
```

La ligne `NSpid` montre **deux** PID : celui de l'hôte et celui dans le namespace.

> ❓ **Question 4** : Quelle ligne prouve que le « conteneur » est un processus ordinaire de l'hôte ?

Nettoyage : `sudo pkill -f "sleep 600"`.

### Partie D — Namespace utilisateur : « root » sans pouvoirs

```bash
id
unshare --user --map-root-user bash -c 'id; cat /proc/self/uid_map; touch /etc/test-ns 2>&1 | tail -1'
```

> ❓ **Question 5** : Dans le namespace, `id` affiche `uid=0`. Pourquoi ne peut-on pourtant pas écrire dans `/etc` ?

### Partie E — Namespace réseau et paire `veth`

```bash
sudo ip netns add prison
sudo ip netns exec prison ip a                 # seulement « lo », DOWN
sudo ip netns exec prison ping -c1 8.8.8.8     # échoue : réseau isolé
```

Reliez l'hôte et le namespace par un « câble » virtuel :

```bash
sudo ip link add veth-hote type veth peer name veth-prison
sudo ip link set veth-prison netns prison
sudo ip addr add 10.20.0.1/24 dev veth-hote
sudo ip link set veth-hote up
sudo ip netns exec prison ip addr add 10.20.0.2/24 dev veth-prison
sudo ip netns exec prison ip link set veth-prison up
sudo ip netns exec prison ip link set lo up
ping -c 2 10.20.0.2                            # hôte → prison
sudo ip netns exec prison ping -c 2 10.20.0.1  # prison → hôte
```

> ❓ **Question 6** : Pourquoi faut-il activer `lo` dans le namespace ? Quel équivalent Docker retrouvez-vous (`docker0`, `vethXXXX`) ?

Donnez l'accès Internet (NAT) :

```bash
sudo sysctl -w net.ipv4.ip_forward=1
IFACE=$(ip route show default | cut -d' ' -f5)
sudo iptables -t nat -A POSTROUTING -s 10.20.0.0/24 -o "$IFACE" -j MASQUERADE
sudo iptables -A FORWARD -i veth-hote -j ACCEPT
sudo iptables -A FORWARD -o veth-hote -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo ip netns exec prison ip route add default via 10.20.0.1
sudo ip netns exec prison ping -c 2 1.1.1.1
```

> ❓ **Question 7** : À quoi sert `MASQUERADE` ? Que ferait la VM si `ip_forward` valait 0 ?

> 💡 **Conseil** : `firewalld` (actif sur Rocky) bloque probablement le transfert entre interfaces : `sudo systemctl stop firewalld` le temps de l'atelier, puis `sudo systemctl start firewalld` à la fin. Les commandes `iptables` viennent ici du paquet `iptables-nft` (traduction vers nftables).

### Partie F — cgroups v2 : poser des limites

```bash
stat -fc %T /sys/fs/cgroup                              # cgroup2fs attendu
cat /sys/fs/cgroup/cgroup.controllers
sudo mkdir /sys/fs/cgroup/prison
echo "+cpu +memory +pids" | sudo tee /sys/fs/cgroup/cgroup.subtree_control > /dev/null
ls /sys/fs/cgroup/prison | head -20
```

Fixez les limites :

```bash
echo "100M"          | sudo tee /sys/fs/cgroup/prison/memory.max
echo "20000 100000"  | sudo tee /sys/fs/cgroup/prison/cpu.max      # 20 % d'un CPU
echo "20"            | sudo tee /sys/fs/cgroup/prison/pids.max
```

> ❓ **Question 8** : Que signifie `20000 100000` dans `cpu.max` ?

Test CPU (le processus lancé est placé dans le cgroup) :

```bash
sudo bash -c 'echo $$ > /sys/fs/cgroup/prison/cgroup.procs; exec stress-ng --cpu 1 --timeout 15s' &
sleep 5
top -b -n 1 | grep stress-ng | head -2          # ≈ 20 % attendu
cat /sys/fs/cgroup/prison/cpu.stat | grep -E "nr_throttled|throttled_usec"
wait
```

Test mémoire :

```bash
sudo bash -c 'echo $$ > /sys/fs/cgroup/prison/cgroup.procs; exec stress-ng --vm 1 --vm-bytes 300M --vm-keep --timeout 10s'
cat /sys/fs/cgroup/prison/memory.events
journalctl -k --since "1 minute ago" | grep -i "oom" | tail -3
```

Test « fork bomb » inoffensive grâce à `pids.max` :

```bash
sudo bash -c 'echo $$ > /sys/fs/cgroup/prison/cgroup.procs; for i in $(seq 1 40); do sleep 30 & done 2>&1 | tail -2'
cat /sys/fs/cgroup/prison/pids.events
sudo pkill sleep
```

> ❓ **Question 9** : Pour chaque ressource (CPU, mémoire, PIDs), que fait le noyau lorsque la limite est atteinte ? *(Ralentit, tue, refuse…)*

### Partie G — Assembler un « conteneur » complet

Créez un système de fichiers racine minimal (quelques minutes, ~250 Mo) :

```bash
sudo dnf install --installroot=/srv/rootfs-prison --releasever=9 --setopt=install_weak_deps=False -y bash coreutils procps-ng iproute iputils
ls /srv/rootfs-prison
# (Sous Ubuntu, on utiliserait debootstrap ; sous Rocky, dnf --installroot construit la racine.)
```

Lancez le « conteneur » avec ses namespaces, dans le namespace réseau `prison` et le cgroup limité :

```bash
sudo bash -c '
echo $$ > /sys/fs/cgroup/prison/cgroup.procs
exec ip netns exec prison unshare --pid --fork --mount --uts --ipc \
    chroot /srv/rootfs-prison /bin/bash -c "mount -t proc proc /proc; hostname conteneur; exec /bin/bash"
'
```

À l'intérieur du conteneur :

```bash
cat /etc/os-release | head -2       # Rocky Linux 9 (fichiers du chroot)
hostname
ps aux
ip a
ping -c 1 10.20.0.1
cat /proc/self/cgroup
exit
```

> ❓ **Question 10** : Listez, pour ce conteneur, **quel mécanisme** assure : (a) la racine différente, (b) l'isolation des PID, (c) l'isolation réseau, (d) la limite mémoire.

### Partie H — Comparer avec un vrai conteneur (facultatif)

Avec **Podman** (installé dans la VM ; la syntaxe est identique à celle de Docker) :

```bash
sudo podman run -d --name cmp --memory 100m --cpus 0.2 docker.io/library/rockylinux:9 sleep 600
PID=$(sudo podman inspect -f '{{.State.Pid}}' cmp)
sudo ls -l /proc/$PID/ns
cat /proc/$PID/cgroup
sudo podman rm -f cmp
```

### Nettoyage

```bash
sudo pkill sleep 2>/dev/null
sudo rmdir /sys/fs/cgroup/prison 2>/dev/null
sudo ip netns del prison
sudo ip link del veth-hote 2>/dev/null
sudo iptables -t nat -D POSTROUTING -s 10.20.0.0/24 -o "$(ip route show default | cut -d' ' -f5)" -j MASQUERADE
sudo iptables -D FORWARD -i veth-hote -j ACCEPT 2>/dev/null
sudo iptables -D FORWARD -o veth-hote -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null
sudo sysctl -w net.ipv4.ip_forward=0
sudo rm -rf /srv/rootfs-prison
```

> ⚠️ **Attention** : si `rmdir` du cgroup échoue (« Device or resource busy »), des processus y résident encore : tuez-les d'abord.

## ✅ Validation

- [ ] Vous avez prouvé qu'un shell sous `unshare --pid` possède le PID 1 tout en étant un processus ordinaire de l'hôte (`NSpid`).
- [ ] `ping` hôte ↔ namespace `prison` fonctionne via la paire `veth`.
- [ ] Le test CPU montre environ 20 % et un compteur `nr_throttled` > 0.
- [ ] `memory.events` montre un évènement `oom_kill` après le dépassement des 100 Mo.
- [ ] Le conteneur `chroot` affiche son propre hostname, ses propres processus et son propre réseau.
- [ ] Vous savez répondre à la question 10 sans relire le cours.

## 💡 Pour aller plus loin

- **Défi 1** : montez une couche **OverlayFS** par-dessus `/srv/rootfs-prison` pour que les modifications du conteneur n'altèrent pas l'image.
- **Défi 2** : retirez des *capabilities* avec `capsh --drop=cap_sys_admin,cap_net_raw --` et constatez ce qui ne fonctionne plus (`ping`, `mount`).
- **Défi 3** : écrivez un script `mini-docker.sh run <rootfs> <commande>` qui automatise toutes ces étapes.
- **Défi 4** : utilisez `systemd-nspawn` (paquet `systemd-container`) pour obtenir le même résultat en une commande.

---

## 🏆 Défi du jour

**Objectif** : Construire une **mini-prison** : un service web qui tourne dans son propre namespace réseau, avec un cgroup qui plafonne sa mémoire.

**Contexte** : Tu dois démontrer à ton équipe qu'un « conteneur » n'est qu'un processus Linux avec des isolations. Pas de Docker : uniquement `ip netns`, `veth` et les cgroups v2.

**Consignes** :
- Crée le namespace réseau `cage` et une paire `veth` : `v-hote` (10.77.0.1/24, côté hôte) et `v-cage` (10.77.0.2/24, dans `cage`). Active les interfaces.
- Lance `python3 -m http.server 8077 --bind 10.77.0.2` **dans** le namespace (`ip netns exec cage …`) et interroge-le depuis l'hôte avec `curl`.
- Prouve l'isolation : compare `readlink /proc/$$/ns/net` (hôte) avec celui du processus serveur.
- Crée le cgroup `/sys/fs/cgroup/defi` avec `memory.max` = 50 Mo et `pids.max` = 20, et vérifie les valeurs relues.
- Nettoie tout (processus, namespace, cgroup).

**Indices** (à consulter seulement si bloqué) :
- `ip link add v-hote type veth peer name v-cage` puis `ip link set v-cage netns cage`.
- Il faut aussi activer `lo` et `v-cage` **dans** le namespace (`ip netns exec cage ip link set … up`).
- `echo "+memory +pids" | sudo tee /sys/fs/cgroup/cgroup.subtree_control` active les contrôleurs avant d'écrire dans le sous-groupe.

**Critères de réussite** :
- [ ] `curl -s -o /dev/null -w '%{http_code}' http://10.77.0.2:8077/` renvoie `200`.
- [ ] Les identifiants `net:[…]` de l'hôte et du serveur sont **différents**.
- [ ] `cat /sys/fs/cgroup/defi/memory.max` affiche `52428800` et `pids.max` affiche `20`.
- [ ] Après nettoyage, `ip netns list` est vide et `/sys/fs/cgroup/defi` n'existe plus.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
sudo ip netns add cage
sudo ip link add v-hote type veth peer name v-cage
sudo ip link set v-cage netns cage
sudo ip addr add 10.77.0.1/24 dev v-hote && sudo ip link set v-hote up
sudo ip netns exec cage ip addr add 10.77.0.2/24 dev v-cage
sudo ip netns exec cage ip link set v-cage up
sudo ip netns exec cage ip link set lo up

sudo ip netns exec cage python3 -m http.server 8077 --bind 10.77.0.2 >/dev/null 2>&1 &
sleep 1
curl -s -o /dev/null -w '%{http_code}\n' http://10.77.0.2:8077/          # 200

PID=$(pgrep -f "http.server 8077" | head -n 1)
readlink /proc/$$/ns/net ; sudo readlink /proc/$PID/ns/net                  # deux identifiants différents

echo "+memory +pids" | sudo tee /sys/fs/cgroup/cgroup.subtree_control
sudo mkdir /sys/fs/cgroup/defi
echo 50M | sudo tee /sys/fs/cgroup/defi/memory.max
echo 20  | sudo tee /sys/fs/cgroup/defi/pids.max
cat /sys/fs/cgroup/defi/memory.max /sys/fs/cgroup/defi/pids.max             # 52428800 et 20

# Nettoyage
sudo pkill -f "http.server 8077"
sudo ip netns del cage
sudo rmdir /sys/fs/cgroup/defi
```

Le serveur n'est qu'un **processus de l'hôte** : seul son namespace réseau diffère (voir `readlink`). La limite mémoire est un simple fichier du cgroup v2 : c'est ce que fait Docker sous le capot.

</details>

---

Atelier suivant : [Journalisation centralisée](atelier-03-journalisation-centralisee.md).
