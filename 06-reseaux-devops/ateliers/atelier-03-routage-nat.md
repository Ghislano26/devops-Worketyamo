# Atelier 03 — Routage et NAT : deux namespaces, un pont et iptables

## 🎯 Objectifs

- Construire à la main un mini-réseau de « conteneurs » : **deux namespaces**, des **paires veth** et un **pont** `br0`.
- Configurer l'**IP forwarding**, la **route par défaut** et le **NAT** (`MASQUERADE`).
- **Publier** un service d'un namespace vers l'hôte avec **DNAT**.
- Expliquer **chaque règle** et vérifier son effet avec les compteurs et `tcpdump`.

## 📋 Prérequis

- Atelier [02 — Ports et services](atelier-02-ports-et-services.md) terminé.
- Cours lu : [Routage, NAT et réseaux de conteneurs](../cours/03-routage-et-nat.md) (en particulier la section 8, schéma du chemin d'un paquet).
- Cours liés : [namespaces](../../04-linux-expert/cours/02-conteneurs-namespaces.md) du module 04.
- VM avec accès Internet, `sudo`, snapshot pris.
- Paquets : `sudo apt install -y iproute2 iptables tcpdump conntrack traceroute curl netcat-openbsd`.

> ⚠️ **Attention** : cet atelier modifie le pare-feu et active le routage. Désactivez `ufw` pendant l'atelier (`sudo ufw disable`) et gardez une session de secours. Si **Docker** est installé, il pose sa propre politique `FORWARD DROP` : l'étape 3 ajoute explicitement les règles nécessaires, et le nettoyage les retire.

## 🧪 Scénario

L'équipe plateforme de *Kamer Logistics* veut comprendre ce que fait Docker « sous le capot » avant de choisir un
CNI Kubernetes. Votre mission : reconstruire le réseau d'un mini-hôte à conteneurs **sans Docker** : deux « conteneurs »
(`ns1`, `ns2`) qui se parlent, sortent sur Internet et dont un service est publié sur l'hôte.

```text
                    ┌────────────────────── Hôte ──────────────────────┐
  ns1 10.30.0.11 ───┤ veth1-h ┐                                         │
                    │         ├── br0 (10.30.0.1/24) ── routage ── NAT ─┼── enp0s3 ── Internet
  ns2 10.30.0.12 ───┤ veth2-h ┘                                         │
                    └───────────────────────────────────────────────────┘
```

## Étapes

### Étape 1 — État initial

```bash
mkdir -p ~/nat && cd ~/nat
sudo ufw disable 2>/dev/null
IFACE=$(ip route show default | cut -d' ' -f5); echo "Interface de sortie : $IFACE"
ip -br a
ip route
sysctl net.ipv4.ip_forward
sudo iptables -t nat -S | head
sudo iptables -S FORWARD | head -3
ip netns list
```

> ❓ **Question 1** : `ip_forward` vaut-il 0 ou 1 ? Que fait par défaut Linux d'un paquet qui n'est pas destiné à la machine ?

### Étape 2 — Créer les namespaces, les veth et le pont

```bash
# Deux « conteneurs »
sudo ip netns add ns1
sudo ip netns add ns2

# Le pont (switch virtuel L2) avec l'adresse de la passerelle
sudo ip link add br0 type bridge
sudo ip addr add 10.30.0.1/24 dev br0
sudo ip link set br0 up

# Câble 1 : ns1 <-> pont
sudo ip link add veth1-h type veth peer name veth1-c
sudo ip link set veth1-c netns ns1
sudo ip link set veth1-h master br0
sudo ip link set veth1-h up

# Câble 2 : ns2 <-> pont
sudo ip link add veth2-h type veth peer name veth2-c
sudo ip link set veth2-c netns ns2
sudo ip link set veth2-h master br0
sudo ip link set veth2-h up

# Configuration à l'intérieur de chaque namespace
sudo ip netns exec ns1 ip link set lo up
sudo ip netns exec ns1 ip link set veth1-c name eth0
sudo ip netns exec ns1 ip addr add 10.30.0.11/24 dev eth0
sudo ip netns exec ns1 ip link set eth0 up

sudo ip netns exec ns2 ip link set lo up
sudo ip netns exec ns2 ip link set veth2-c name eth0
sudo ip netns exec ns2 ip addr add 10.30.0.12/24 dev eth0
sudo ip netns exec ns2 ip link set eth0 up

bridge link
sudo ip netns exec ns1 ip -br a
sudo ip netns exec ns2 ip -br a
```

> ❓ **Question 2** : Pourquoi chaque veth est-il une **paire** ? Quelle extrémité est dans le namespace, laquelle sur le pont ? À quoi sert la commande `bridge link` ?

### Étape 3 — Communication interne (couche 2) et ses limites

```bash
sudo ip netns exec ns1 ping -c 2 10.30.0.12          # ns1 -> ns2 : même réseau, le pont commute
sudo ip netns exec ns1 ping -c 2 10.30.0.1           # ns1 -> passerelle (br0)
sudo ip netns exec ns1 ip neigh                      # table ARP
bridge fdb show br br0 | grep -v permanent | head    # adresses MAC apprises par le pont
sudo ip netns exec ns1 ping -c 2 -W 2 1.1.1.1 || echo "Internet : inaccessible (attendu)"
sudo ip netns exec ns1 ip route
```

> ❓ **Question 3** : Pourquoi `ns1 → ns2` fonctionne-t-il **sans** route ni NAT ? Pourquoi `ns1 → 1.1.1.1` échoue-t-il pour l'instant (observez `ip route` dans ns1) ?

### Étape 4 — Route par défaut et IP forwarding

```bash
sudo ip netns exec ns1 ip route add default via 10.30.0.1
sudo ip netns exec ns2 ip route add default via 10.30.0.1
sudo ip netns exec ns1 ip route get 1.1.1.1
sudo sysctl -w net.ipv4.ip_forward=1
```

Testez : le paquet **part**, mais la réponse ne revient pas (adresse source privée) :

```bash
sudo ip netns exec ns1 ping -c 2 -W 2 1.1.1.1 || echo "pas de réponse : source privée non routable"
```

Observez le paquet **sortir** de l'hôte avec sa source `10.30.0.11` (Ctrl+C pour arrêter la capture) :

```bash
sudo tcpdump -ni "$IFACE" icmp -c 4 &
sleep 1
sudo ip netns exec ns1 ping -c 2 -W 2 1.1.1.1 >/dev/null 2>&1
wait
```

> ❓ **Question 4** : Quelle adresse **source** voyez-vous sur l'interface de sortie ? Pourquoi Internet ne peut-il pas répondre à `10.30.0.11` ? *(RFC 1918, non routable.)*

### Étape 5 — Le NAT : `MASQUERADE`

```bash
# 1. SNAT dynamique pour tout ce qui vient du réseau 10.30.0.0/24 et sort par l'interface externe
sudo iptables -t nat -A POSTROUTING -s 10.30.0.0/24 ! -o br0 -j MASQUERADE

# 2. Autoriser le transit : br0 -> externe (nouvelles connexions et suite)
sudo iptables -I FORWARD 1 -i br0 ! -o br0 -j ACCEPT
# 3. Autoriser les RÉPONSES seulement : externe -> br0 pour les connexions déjà établies
sudo iptables -I FORWARD 2 -o br0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

sudo iptables -t nat -L POSTROUTING -n -v --line-numbers
sudo iptables -L FORWARD -n -v --line-numbers | head -6
```

Test :

```bash
sudo ip netns exec ns1 ping -c 3 1.1.1.1
sudo ip netns exec ns2 curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 8 https://ubuntu.com
sudo iptables -t nat -L POSTROUTING -n -v          # les compteurs ont augmenté
sudo conntrack -L 2>/dev/null | grep 10.30.0 | head -3
sudo tcpdump -ni "$IFACE" icmp -c 4 &
sleep 1; sudo ip netns exec ns1 ping -c 2 1.1.1.1 >/dev/null 2>&1; wait
```

**Explication ligne par ligne** (à compléter dans vos notes) :

| Règle | Rôle |
|---|---|
| `-t nat -A POSTROUTING -s 10.30.0.0/24 ! -o br0 -j MASQUERADE` | Après le routage, pour les paquets issus du réseau 10.30.0.0/24 qui **ne** repartent **pas** par `br0`, remplace l'IP source par celle de l'interface de sortie. |
| `-I FORWARD 1 -i br0 ! -o br0 -j ACCEPT` | Laisse **sortir** le trafic des conteneurs. |
| `-I FORWARD 2 -o br0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT` | Laisse **rentrer** uniquement les réponses à des connexions déjà initiées de l'intérieur : un inconnu d'Internet ne peut pas ouvrir de connexion vers `10.30.0.x`. |

> ❓ **Question 5** : Quelle est maintenant l'adresse source vue sur l'interface externe ? Comment le noyau sait-il, à l'arrivée de la réponse, qu'elle est destinée à `10.30.0.11` ? *(Indice : `conntrack`.)*
> ❓ **Question 6** : Pourquoi utiliser `MASQUERADE` plutôt que `SNAT --to-source 10.0.2.15` ? Dans quel cas `SNAT` serait-il préférable ?
> ❓ **Question 7** : Que se passerait-il si on supprimait la règle n°2 de `FORWARD` (réponses) ?

### Étape 6 — Un service dans `ns2`, joignable depuis `ns1`

```bash
sudo ip netns exec ns2 python3 -m http.server 8080 --bind 0.0.0.0 >/dev/null 2>&1 &
sleep 1
sudo ip netns exec ns2 ss -tlnp | grep 8080
sudo ip netns exec ns1 curl -s -o /dev/null -w "ns1 -> ns2 : HTTP %{http_code}\n" http://10.30.0.12:8080/
curl -s -o /dev/null -w "hôte -> ns2 : HTTP %{http_code}\n" --max-time 3 http://10.30.0.12:8080/
```

> ❓ **Question 8** : L'hôte joint `10.30.0.12` directement : pourquoi sans règle supplémentaire ? *(Indice : `br0` porte `10.30.0.1/24`, réseau « directement connecté ».)*

### Étape 7 — Publier le service : `DNAT`

On veut que `http://<IP-de-l'hôte>:9090` atteigne le service de `ns2` (comme `docker run -p 9090:8080`).

```bash
HOSTIP=$(hostname -I | cut -d' ' -f1); echo "IP hôte : $HOSTIP"

# Depuis une connexion venant de l'EXTÉRIEUR (PREROUTING)
sudo iptables -t nat -A PREROUTING -p tcp --dport 9090 -j DNAT --to-destination 10.30.0.12:8080
# Pour les connexions locales à l'hôte (OUTPUT), nécessaire pour tester depuis l'hôte lui-même
sudo iptables -t nat -A OUTPUT -p tcp -d "$HOSTIP" --dport 9090 -j DNAT --to-destination 10.30.0.12:8080
# Autoriser le transit vers ns2
sudo iptables -I FORWARD 1 -p tcp -d 10.30.0.12 --dport 8080 -j ACCEPT

curl -s -o /dev/null -w "via DNAT : HTTP %{http_code}\n" --max-time 5 http://$HOSTIP:9090/
sudo iptables -t nat -L PREROUTING -n -v
sudo conntrack -L 2>/dev/null | grep 9090 | head -2
```

Observez la traduction avec `tcpdump` sur `br0` (la destination est **réécrite**) :

```bash
sudo tcpdump -ni br0 tcp port 8080 -c 6 &
sleep 1; curl -s -o /dev/null http://$HOSTIP:9090/; wait
```

> ❓ **Question 9** : Sur `br0`, quelle destination voyez-vous (`10.30.0.12:8080`) alors que le client a visé `:9090` ? Dans quelle **chaîne** s'est faite la traduction, et pourquoi **avant** la décision de routage ?
> ❓ **Question 10** : Pourquoi une règle `OUTPUT` en plus de `PREROUTING` ? *(Les paquets émis par l'hôte lui-même ne traversent pas PREROUTING.)*

### Étape 8 — Isoler : montrer le rôle du pare-feu entre conteneurs

```bash
# Interdire ns1 -> ns2 sur le port 8080, au niveau du pont (filtrage L3 via br_netfilter)
sudo modprobe br_netfilter
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo iptables -I FORWARD 1 -s 10.30.0.11 -d 10.30.0.12 -p tcp --dport 8080 -j DROP
sudo ip netns exec ns1 curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 3 http://10.30.0.12:8080/ || echo "bloqué (timeout)"
sudo ip netns exec ns2 curl -s -o /dev/null -w "ns2 -> ns2 : HTTP %{http_code}\n" --max-time 3 http://10.30.0.12:8080/
sudo iptables -L FORWARD -n -v --line-numbers | head -4
sudo iptables -D FORWARD -s 10.30.0.11 -d 10.30.0.12 -p tcp --dport 8080 -j DROP
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0
```

> ❓ **Question 11** : Sans `br_netfilter`, les paquets commutés par un pont **contournent** iptables. Pourquoi est-ce important pour une `NetworkPolicy` Kubernetes ou une règle Docker entre conteneurs d'un même pont ?

### Étape 9 — Diagnostiquer avec les outils

```bash
sudo ip netns exec ns1 ip route get 1.1.1.1
sudo ip netns exec ns1 traceroute -n -m 5 1.1.1.1
sudo ip netns exec ns1 traceroute -n -T -p 443 -m 5 1.1.1.1
sudo ip rule
sudo iptables-save | grep -E "br0|10.30.0" 
sudo nft list ruleset 2>/dev/null | grep -c "table"
```

> ❓ **Question 12** : Dans `traceroute`, quel est le premier saut ? Pourquoi est-ce `10.30.0.1` ? À partir de quel saut l'adresse devient-elle « publique » ?

### Étape 10 — Rendre l'ensemble reproductible

Regroupez le tout dans un script, en vous appuyant sur ce que vous avez fait :

```bash
cat > ~/nat/reseau-conteneurs.sh <<'EOF'
#!/usr/bin/env bash
# reseau-conteneurs.sh up|down — mini réseau de « conteneurs » (ns1, ns2) avec pont, NAT et DNAT
set -euo pipefail
IFACE=$(ip route show default | cut -d' ' -f5)
case "${1:-}" in
  up)
    ip netns add ns1; ip netns add ns2
    ip link add br0 type bridge; ip addr add 10.30.0.1/24 dev br0; ip link set br0 up
    for n in 1 2; do
      ip link add "veth$n-h" type veth peer name "veth$n-c"
      ip link set "veth$n-c" netns "ns$n"; ip link set "veth$n-h" master br0; ip link set "veth$n-h" up
      ip netns exec "ns$n" ip link set lo up
      ip netns exec "ns$n" ip link set "veth$n-c" name eth0
      ip netns exec "ns$n" ip addr add "10.30.0.1$n/24" dev eth0
      ip netns exec "ns$n" ip link set eth0 up
      ip netns exec "ns$n" ip route add default via 10.30.0.1
    done
    sysctl -qw net.ipv4.ip_forward=1
    iptables -t nat -A POSTROUTING -s 10.30.0.0/24 ! -o br0 -j MASQUERADE
    iptables -I FORWARD 1 -i br0 ! -o br0 -j ACCEPT
    iptables -I FORWARD 2 -o br0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    echo "Réseau prêt (sortie via $IFACE)" ;;
  down)
    iptables -t nat -D POSTROUTING -s 10.30.0.0/24 ! -o br0 -j MASQUERADE 2>/dev/null || true
    iptables -D FORWARD -i br0 ! -o br0 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -o br0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    ip netns del ns1 2>/dev/null || true; ip netns del ns2 2>/dev/null || true
    ip link del br0 2>/dev/null || true
    echo "Réseau supprimé" ;;
  *) echo "Usage : sudo $0 up|down" >&2; exit 2 ;;
esac
EOF
chmod +x ~/nat/reseau-conteneurs.sh
```

### Étape 11 — Nettoyage de l'atelier

```bash
sudo pkill -f "http.server 8080" 2>/dev/null
sudo iptables -t nat -D PREROUTING -p tcp --dport 9090 -j DNAT --to-destination 10.30.0.12:8080
sudo iptables -t nat -D OUTPUT -p tcp -d "$(hostname -I | cut -d' ' -f1)" --dport 9090 -j DNAT --to-destination 10.30.0.12:8080
sudo iptables -D FORWARD -p tcp -d 10.30.0.12 --dport 8080 -j ACCEPT
sudo ~/nat/reseau-conteneurs.sh down
sudo sysctl -w net.ipv4.ip_forward=0
ip netns list; ip link show br0 2>&1 | head -1
sudo iptables -t nat -S | grep 10.30 || echo "règles NAT supprimées"
```

> ⚠️ **Attention** : si Docker est présent, ne remettez pas `ip_forward` à 0 (il en a besoin). Vérifiez avec `sudo sysctl net.ipv4.ip_forward` avant l'atelier et restaurez **cette** valeur.

## ✅ Validation

- [ ] `ns1` et `ns2` se joignent par ping (couche 2, via `br0`).
- [ ] `ns1` accède à Internet (`ping 1.1.1.1`, `curl`) grâce à `MASQUERADE` ; la capture montre l'IP de l'hôte comme source.
- [ ] Le service de `ns2` est joignable via `http://<IP-hôte>:9090` grâce au **DNAT**.
- [ ] Les compteurs de `iptables -t nat -L -n -v` ont augmenté pendant vos tests.
- [ ] Vous avez expliqué chaque règle (tableau de l'étape 5) et la différence PREROUTING / POSTROUTING.
- [ ] Après nettoyage, `ip netns list` est vide et aucune règle `10.30.0.x` ne subsiste.

## 💡 Pour aller plus loin

- **Défi 1** : ajoutez un `ns3` et une règle qui l'empêche de sortir sur Internet tout en pouvant parler à `ns1` et `ns2`.
- **Défi 2** : reproduisez l'atelier avec `nft` à la place d'`iptables` (`table ip nat`, chaînes `prerouting`/`postrouting`).
- **Défi 3** : comparez avec Docker : `docker network create`, puis `bridge link`, `iptables -t nat -S | grep -i docker`, `ip netns` (`/var/run/docker/netns`).
- **Défi 4** : simulez un overlay : créez deux hôtes (deux namespaces racines) reliés par un tunnel `vxlan` et pingez entre deux conteneurs de chaque côté.

Atelier suivant : [Diagnostic complet](atelier-04-diagnostic-complet.md).
