# Atelier 03 — Diagnostic réseau

## 🎯 Objectifs

- Lire la configuration réseau d'une machine (IP, route, DNS).
- Diagnostiquer une panne **couche par couche**.
- Identifier les services à l'écoute et les tester avec `ss`, `nc`, `curl`.
- Provoquer et corriger des pannes DNS et de pare-feu.

## 📋 Prérequis

- Atelier [02](atelier-02-apt-gestion-paquets.md) terminé (nginx n'est pas obligatoire ici, il sera réinstallé si besoin).
- Cours lu : [Réseau, bases](../cours/03-reseaux-base.md).
- Paquets : `dnsutils`, `netcat-openbsd`, `traceroute`, `curl` (checklist du module 00).

> ⚠️ **Attention** : cet atelier modifie temporairement la résolution DNS et le pare-feu. Prenez un **snapshot** et travaillez depuis la console de la VM (pas en SSH) pour ne pas vous enfermer dehors.

## 🧪 Scénario

Un collègue de *Kamer Logistics* appelle : « Le serveur ne répond plus, on n'arrive plus à
télécharger de mises à jour ni à joindre le site ». Vous jouez le technicien : vous commencez par
**établir l'état normal**, puis vous diagnostiquez deux pannes que vous aurez provoquées vous-même.

## Étapes

### Étape 1 — Relever l'état normal (la référence)

```bash
ip -br a
ip route
resolvectl status | grep -E "Current DNS|DNS Servers" | head -3
cat /etc/resolv.conf | grep -v '^#'
```

Notez dans un fichier :

```bash
mkdir -p ~/reseau && {
  echo "IP et interfaces :"; ip -br a
  echo; echo "Routes :"; ip route
  echo; echo "DNS :"; resolvectl dns
} > ~/reseau/etat-normal.txt
```

> ❓ **Question 1** : Quelle est l'adresse de votre passerelle ? Quelle ligne de `ip route` l'indique ?

### Étape 2 — Tester couche par couche (état sain)

```bash
ping -c 2 127.0.0.1                                  # pile réseau locale
ping -c 2 "$(ip route show default | cut -d' ' -f3)" # passerelle
ping -c 2 1.1.1.1                                    # Internet sans DNS
ping -c 2 ubuntu.com                                 # Internet avec DNS
curl -sI https://ubuntu.com | head -1                # application (HTTP)
```

> ❓ **Question 2** : Si seul le dernier `ping` échouait, dans quelle couche chercheriez-vous la panne ?

### Étape 3 — Qui écoute sur la machine ?

```bash
sudo ss -tulpn
sudo ss -tlnp | grep -E ":22|:53"
```

Lancez un petit serveur de test :

```bash
python3 -m http.server 8080 --bind 127.0.0.1 &
sleep 1
ss -tlnp | grep 8080
curl -sI http://127.0.0.1:8080 | head -1
```

> ❓ **Question 3** : Quelle différence y a-t-il entre `127.0.0.1:8080` et `0.0.0.0:8080` en termes d'exposition ? Relancez avec `--bind 0.0.0.0` et comparez la sortie de `ss`.

Arrêtez le serveur : `kill %1` (ou `pkill -f "http.server 8080"`).

### Étape 4 — Panne n°1 : le DNS

Cassez le DNS **pour une seule interface** de façon réversible, en pointant vers un serveur inexistant :

```bash
sudo resolvectl dns "$(ip route show default | cut -d' ' -f5)" 203.0.113.1
resolvectl dns
ping -c 2 -W 2 1.1.1.1                 # fonctionne
ping -c 2 -W 2 ubuntu.com              # échoue : « Temporary failure in name resolution »
dig +time=2 +tries=1 ubuntu.com | tail -5
```

Diagnostic :

```bash
dig @1.1.1.1 +short ubuntu.com          # un serveur DNS valide répond-il ?
getent hosts ubuntu.com || echo "résolution système KO"
```

> ❓ **Question 4** : Pourquoi `ping 1.1.1.1` réussit-il alors que `ping ubuntu.com` échoue ? Que conclut-on ?

Réparation :

```bash
sudo resolvectl revert "$(ip route show default | cut -d' ' -f5)"
resolvectl dns
ping -c 2 ubuntu.com
```

### Étape 5 — Panne n°2 : le pare-feu

Installez un serveur web de test et autorisez SSH avant d'activer le pare-feu :

```bash
sudo apt install -y nginx
curl -sI http://localhost | head -1
sudo ufw allow OpenSSH
sudo ufw --force enable
sudo ufw status verbose
```

Bloquez le port 80 et testez **depuis l'extérieur de la machine locale** (via l'IP réelle, pas via `localhost`) :

```bash
IP=$(hostname -I | cut -d' ' -f1)
echo "Mon IP : $IP"
sudo ufw deny 80/tcp
curl -sI --max-time 3 http://$IP | head -1 || echo "bloqué par le pare-feu"
nc -zv -w 2 "$IP" 80
```

> ❓ **Question 5** : Pourquoi `curl http://localhost` peut-il fonctionner alors que `http://$IP` est bloqué ? *(Indice : interface `lo`, règles `ufw` par défaut.)*

Réparation :

```bash
sudo ufw delete deny 80/tcp
sudo ufw allow 80/tcp
curl -sI --max-time 3 http://$IP | head -1
```

> ❓ **Question 6** : Quelle différence observe-t-on entre un port **fermé** (« Connection refused ») et un port **filtré** par un pare-feu (délai d'attente) ? Testez : `nc -zv -w 2 $IP 9999` (fermé) contre un `ufw deny 9999` puis le même test.

### Étape 6 — Observer le trafic

```bash
sudo apt install -y tcpdump
sudo timeout 15 tcpdump -i any -n port 53 -c 6 &
sleep 1
dig +short example.org > /dev/null
wait
```

> ❓ **Question 7** : Que voyez-vous : requête, réponse, protocole (UDP ou TCP), port ?

### Étape 7 — Fichier `/etc/hosts` et ordre de résolution

```bash
grep hosts /etc/nsswitch.conf
echo "127.0.0.1 intranet.kamer.local" | sudo tee -a /etc/hosts
ping -c 1 intranet.kamer.local
getent hosts intranet.kamer.local
dig +short intranet.kamer.local            # que renvoie dig ? pourquoi ?
sudo sed -i '/intranet.kamer.local/d' /etc/hosts
```

> ❓ **Question 8** : `dig` ne voit pas l'entrée de `/etc/hosts`, mais `ping` oui. Pourquoi ?

### Étape 8 — Tracer le chemin

```bash
traceroute -n 1.1.1.1 | head
tracepath -n ubuntu.com | head
```

### Étape 9 — Rédiger le rapport d'incident

```bash
cat > ~/reseau/rapport.md <<'EOF'
# Rapport d'incident réseau

## Symptômes
- ...

## Diagnostic (couche par couche)
- Lien / IP :
- Passerelle :
- DNS :
- Port / pare-feu :

## Cause racine
...

## Correctif appliqué
...
EOF
nano ~/reseau/rapport.md
```

Remplissez-le à partir de ce que vous avez observé dans les étapes 4 et 5.

### Étape 10 — Remise en état

```bash
sudo ufw disable
sudo apt purge -y nginx && sudo apt autoremove -y
```

## ✅ Validation

- [ ] `~/reseau/etat-normal.txt` contient IP, routes et DNS.
- [ ] Vous avez reproduit la panne DNS (`ping IP` OK, `ping nom` KO) puis l'avez réparée.
- [ ] Vous avez reproduit un blocage de pare-feu sur le port 80 puis l'avez levé.
- [ ] Vous distinguez « port fermé » (refus immédiat) et « port filtré » (silence).
- [ ] `ufw` est désactivé ou ne bloque rien d'essentiel en fin d'atelier.
- [ ] `~/reseau/rapport.md` est rempli.

## 💡 Pour aller plus loin

- **Défi 1** : configurez une IP statique avec Netplan (`sudo netplan try`) puis revenez en DHCP.
- **Défi 2** : écrivez un script qui teste automatiquement passerelle, IP publique, DNS et HTTP et affiche `OK`/`KO` pour chacun.
- **Défi 3** : interrogez les enregistrements MX et NS d'un domaine avec `dig`.
- **Défi 4** : utilisez `mtr -rw -c 10 ubuntu.com` pour repérer un saut avec perte de paquets.

Atelier suivant : [SSH sécurisé](atelier-04-ssh-securise.md).
