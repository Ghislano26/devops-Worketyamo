# Atelier 02 — Ports, sockets et états TCP

## 🎯 Objectifs

- Lancer des serveurs et clients avec `nc` et observer les sockets avec `ss` et `lsof`.
- Identifier le 5-uplet d'une connexion et suivre les **états TCP** réels.
- Reproduire **TIME_WAIT** et **CLOSE_WAIT** et expliquer leur différence.
- Mesurer l'impact du **bind** (`127.0.0.1` vs `0.0.0.0`) sur l'exposition d'un service.

## 📋 Prérequis

- Atelier [01 — DNS](atelier-01-dns-resolution.md) terminé (non obligatoire, mais conseillé).
- Cours lu : [Ports, sockets et états TCP](../cours/02-ports-et-sockets.md).
- Paquets : `sudo apt install -y netcat-openbsd lsof iproute2 python3`.
- **Deux terminaux** ouverts sur la VM (A et B).

## 🧪 Scénario

Le support de *Kamer Logistics* reçoit deux tickets : (1) « le serveur de rapports est joignable depuis tout
le réseau alors qu'il devrait être local » ; (2) « un service accumule des milliers de connexions
fantômes ». Vous allez reproduire ces deux situations pour savoir **les reconnaître** et **les corriger**.

## Étapes

### Étape 1 — Inventaire des ports en écoute

```bash
mkdir -p ~/ports && cd ~/ports
sudo ss -tulpn
sudo ss -tlnp | grep -E ":22 "
sudo lsof -iTCP -sTCP:LISTEN -nP | head
sysctl net.ipv4.ip_local_port_range
```

> ❓ **Question 1** : Quelle est la plage des ports **éphémères** de votre VM ? Combien de connexions simultanées vers **un même** serveur:port peut-elle ouvrir au maximum ?
> ❓ **Question 2** : Repérez une ligne avec `127.0.0.53%lo:53` et une avec `0.0.0.0:22` (ou `*:22`). Laquelle est joignable depuis une autre machine ?

### Étape 2 — Premier serveur avec `nc`

Terminal A :

```bash
nc -l 9000
```

Terminal B :

```bash
ss -tlnp | grep 9000
nc -zv 127.0.0.1 9000          # sonde : le port est ouvert (cela consomme la connexion unique de nc -l)
```

Redémarrez le serveur dans A (`nc -l 9000`) puis, dans B, établissez une vraie connexion :

```bash
nc 127.0.0.1 9000
# Tapez « bonjour » dans B ; le texte apparaît dans A. Répondez depuis A.
```

Pendant que la conversation est ouverte, dans un **troisième terminal** (ou après `Ctrl+Z` puis `bg`) :

```bash
ss -tanp | grep 9000
```

Vous devez voir **deux** lignes `ESTABLISHED` (le point de vue du serveur et celui du client) :

```text
ESTAB 0 0 127.0.0.1:9000       127.0.0.1:51234   users:(("nc",pid=…))   ← serveur
ESTAB 0 0 127.0.0.1:51234      127.0.0.1:9000    users:(("nc",pid=…))   ← client
```

> ❓ **Question 3** : Écrivez le **5-uplet** de la connexion (protocole, IP source, port source, IP destination, port destination). Quel port est **éphémère**, et qui l'a choisi ?

### Étape 3 — Suivre les états lors de la fermeture

Reprenez la conversation. Dans le terminal du **client** (B), fermez avec `Ctrl+C`. Aussitôt :

```bash
ss -tan | grep 9000
```

Selon le côté qui a fermé en premier, vous observez `TIME_WAIT` (côté fermeture active).

> ❓ **Question 4** : Quel côté se retrouve en `TIME_WAIT` : celui qui a fermé en premier ou l'autre ? Pendant combien de temps ? *(Surveillez : `watch -n1 "ss -tan | grep 9000"`.)*

### Étape 4 — Reproduire `TIME_WAIT` en masse

Un petit serveur HTTP et un client qui ouvre/ferme des connexions en rafale :

```bash
cd ~/ports
python3 -m http.server 8000 --bind 127.0.0.1 >/dev/null 2>&1 &
sleep 1
cat > rafale.py <<'EOF'
#!/usr/bin/env python3
"""Ouvre puis ferme N connexions TCP vers un serveur (le CLIENT ferme en premier)."""
import socket, sys
n = int(sys.argv[1]) if len(sys.argv) > 1 else 200
for _ in range(n):
    s = socket.create_connection(("127.0.0.1", 8000))
    s.sendall(b"GET / HTTP/1.0\r\n\r\n")
    s.recv(4096)
    s.close()
print(f"{n} connexions ouvertes puis fermées")
EOF
python3 rafale.py 300
ss -tan state time-wait | grep -c ":8000"
ss -tan | awk 'NR>1 {c[$1]++} END {for (e in c) print c[e], e}' | sort -nr
```

> ❓ **Question 5** : Combien de `TIME_WAIT` observez-vous ? Sont-ils du côté client (port source éphémère) ou serveur (port 8000) ? Pourquoi est-ce **normal** ?
> ❓ **Question 6** : Quel risque pose un très grand nombre de `TIME_WAIT` vers un **même** serveur:port ? *(Indice : ports éphémères.)* Quelle bonne pratique le réduit ? *(keep-alive / pool de connexions.)*

Attendez ~60 secondes et recomptez : les entrées disparaissent.

```bash
sleep 65; ss -tan state time-wait | grep -c ":8000"
```

### Étape 5 — Reproduire `CLOSE_WAIT` (un bug applicatif)

Ce serveur « oublie » de fermer ses sockets :

```bash
cat > fuite.py <<'EOF'
#!/usr/bin/env python3
"""Serveur FAUTIF : accepte les connexions mais ne ferme jamais ses sockets (fuite)."""
import socket
srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", 9100)); srv.listen(128)
gardes = []                       # on conserve les sockets : jamais fermés
while True:
    conn, _ = srv.accept()
    gardes.append(conn)
EOF
python3 fuite.py &
sleep 1
for i in $(seq 1 5); do (echo "salut" | nc -q1 127.0.0.1 9100); done
sleep 1
ss -tanp | grep 9100 | awk '{print $1, $4, $5}'
```

Vous voyez des lignes `CLOSE-WAIT` côté serveur (le client a fermé, le serveur n'a **pas** fermé son socket) :

```bash
ss -tan state close-wait | grep -c 9100
sudo ls -l /proc/$(pgrep -f fuite.py)/fd | grep -c socket
```

> ❓ **Question 7** : Pourquoi `CLOSE_WAIT` désigne-t-il toujours un bug de l'**application** et jamais un problème réseau ? Que faut-il corriger (et que pourrait tenter un exploitant en attendant le correctif) ?

Corrigez et nettoyez :

```bash
pkill -f fuite.py
sleep 1; ss -tan state close-wait | grep -c 9100
```

### Étape 6 — Le bind : `127.0.0.1` vs `0.0.0.0`

```bash
IP=$(hostname -I | cut -d' ' -f1); echo "IP de la VM : $IP"
pkill -f "http.server 8000" 2>/dev/null

# Serveur A : local seulement
python3 -m http.server 8081 --bind 127.0.0.1 >/dev/null 2>&1 &
# Serveur B : toutes les interfaces
python3 -m http.server 8082 --bind 0.0.0.0 >/dev/null 2>&1 &
sleep 1
ss -tlnp | grep -E "8081|8082"

echo "--- via 127.0.0.1 ---"
curl -s -o /dev/null -w "8081 -> %{http_code}\n" --max-time 3 http://127.0.0.1:8081/
curl -s -o /dev/null -w "8082 -> %{http_code}\n" --max-time 3 http://127.0.0.1:8082/
echo "--- via l'IP réelle $IP ---"
curl -s -o /dev/null -w "8081 -> %{http_code}\n" --max-time 3 http://$IP:8081/ || echo "8081 : refusé"
curl -s -o /dev/null -w "8082 -> %{http_code}\n" --max-time 3 http://$IP:8082/
```

> ❓ **Question 8** : Quel serveur est inaccessible via l'IP réelle ? Quel message d'erreur `curl` obtenez-vous (code 7, « Connection refused ») ? Pourquoi *refused* et pas *timeout* ?

Mesurez l'exposition depuis un autre point de vue (la machine hôte, ou une seconde VM), si possible :

```bash
# Depuis l'hôte (adapter l'IP, nécessite un réseau joignable : Host-only / Bridge) :
# nc -zv <IP-VM> 8082
```

### Étape 7 — Refus vs filtrage

```bash
nc -zv -w2 127.0.0.1 9999 ; echo "code = $?"          # personne n'écoute : REFUSED
sudo apt install -y ufw >/dev/null
sudo ufw allow OpenSSH >/dev/null && sudo ufw --force enable >/dev/null
sudo ufw deny 8082/tcp >/dev/null
nc -zv -w3 "$IP" 8082 ; echo "code = $?"              # filtré : TIMEOUT (le paquet est jeté)
sudo ufw delete deny 8082/tcp >/dev/null
sudo ufw disable
```

> ❓ **Question 9** : Quelle différence de comportement entre un port **fermé** (rien n'écoute) et un port **filtré** ? Que répond la machine dans chaque cas (RST ou silence) ? Comment un diagnostic s'en sert-il ?

### Étape 8 — Trouver et arrêter celui qui occupe un port

```bash
sudo lsof -i :8081
sudo ss -tlnp | grep 8081
python3 -m http.server 8081 --bind 127.0.0.1 2>&1 | tail -1      # « Address already in use »
sudo fuser -k 8081/tcp
sleep 1; ss -tlnp | grep 8081 || echo "port libéré"
```

### Étape 9 — Ports privilégiés

```bash
python3 -m http.server 80 --bind 127.0.0.1 2>&1 | tail -1       # « Permission denied »
sudo python3 -m http.server 80 --bind 127.0.0.1 &
sleep 1; ss -tlnp | grep ":80 "; sudo pkill -f "http.server 80"
```

> ❓ **Question 10** : Pourquoi l'accès aux ports < 1024 est-il réservé ? Quelle alternative plus sûre que root existe pour un service ordinaire ? *(Indice : `CAP_NET_BIND_SERVICE`, ou écouter sur 8080 derrière un proxy.)*

### Étape 10 — Nettoyage

```bash
pkill -f "http.server" 2>/dev/null; pkill -f fuite.py 2>/dev/null; pkill -x nc 2>/dev/null
ss -tlnp | grep -E "800|808|9000|9100" || echo "plus rien en écoute"
```

## ✅ Validation

- [ ] Vous avez écrit le **5-uplet** d'une connexion établie observée avec `ss`.
- [ ] Vous avez vu des `TIME_WAIT` après la rafale de connexions et constaté leur disparition au bout de ~60 s.
- [ ] Vous avez produit des `CLOSE_WAIT` avec `fuite.py` et expliqué pourquoi c'est un bug applicatif.
- [ ] `curl` via l'IP réelle échoue sur le port lié à `127.0.0.1` et réussit sur celui lié à `0.0.0.0`.
- [ ] Vous distinguez « refused » (RST immédiat) et « timeout » (paquet jeté).
- [ ] Tous les serveurs de test sont arrêtés.

## 💡 Pour aller plus loin

- **Défi 1** : surveillez en direct la répartition des états : `watch -n1 "ss -tan | awk 'NR>1{c[\$1]++} END{for(e in c) print c[e], e}'"` pendant que vous relancez `rafale.py`.
- **Défi 2** : testez `SO_REUSEADDR` : relancez un serveur immédiatement après l'avoir tué en présence de `TIME_WAIT`, avec et sans cette option.
- **Défi 3** : écrivez un script qui alerte si plus de 100 sockets `CLOSE_WAIT` apparaissent pour un processus donné.
- **Défi 4** : dans Kubernetes de test, créez un `Service` dont le `targetPort` est faux et reconnaissez-le avec `kubectl get endpoints` et `nc -zv` depuis un pod.

Atelier suivant : [Routage et NAT](atelier-03-routage-nat.md).
