# Atelier 03 — Diagnostic réseau

> 🐧 *Version Rocky Linux 9 : `nmcli` (NetworkManager) remplace `netplan`/`resolvectl`, `firewalld` remplace `ufw`.*

## 🎯 Objectifs

- Lire la configuration réseau d'une machine (IP, route, DNS).
- Diagnostiquer une panne **couche par couche**.
- Identifier les services à l'écoute et les tester avec `ss`, `nc`, `curl`.
- Provoquer et corriger des pannes DNS et de pare-feu.

## 📋 Prérequis

- Atelier [02](atelier-02-apt-gestion-paquets.md) terminé (nginx n'est pas obligatoire ici, il sera réinstallé si besoin).
- Cours lu : [Réseau, bases](../cours/03-reseaux-base.md).
- Paquets : `bind-utils` (`dig`), `nmap-ncat` (`nc`), `traceroute`, `curl`, `tcpdump` : déjà installés dans la VM du cours.
- Un second terminal **sur votre ordinateur hôte** (pour tester le pare-feu depuis l'extérieur de la VM).

> ⚠️ **Attention** : cet atelier modifie temporairement la résolution DNS et le pare-feu. Prenez un **snapshot** (`vagrant snapshot save avant-reseau`) et gardez la console VirtualBox comme accès de secours. Ne touchez pas à `enp0s3` (NAT, utilisée par `vagrant ssh`) autrement que comme décrit.

## 🧪 Scénario

Un collègue de *Kamer Logistics* appelle : « Le serveur ne répond plus, on n'arrive plus à
télécharger de mises à jour ni à joindre le site ». Vous jouez le technicien : vous commencez par
**établir l'état normal**, puis vous diagnostiquez deux pannes que vous aurez provoquées vous-même.

## Étapes

### Étape 1 — Relever l'état normal (la référence)

```bash
ip -br a
ip route
nmcli device status
nmcli device show enp0s3 | grep -E 'IP4.DNS|IP4.GATEWAY'
grep -v '^#' /etc/resolv.conf
```

Notez dans un fichier :

```bash
mkdir -p ~/reseau && {
  echo "IP et interfaces :"; ip -br a
  echo; echo "Routes :"; ip route
  echo; echo "DNS :"; grep '^nameserver' /etc/resolv.conf
} > ~/reseau/etat-normal.txt
```

> ❓ **Question 1** : Quelle est l'adresse de votre passerelle ? Quelle ligne de `ip route` l'indique ?

### Étape 2 — Tester couche par couche (état sain)

```bash
ping -c 2 127.0.0.1                                  # pile réseau locale
ping -c 2 "$(ip route show default | cut -d' ' -f3)" # passerelle
ping -c 2 1.1.1.1                                    # Internet sans DNS
ping -c 2 rockylinux.org                                 # Internet avec DNS
curl -sI https://rockylinux.org | head -1                # application (HTTP)
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

Cassez le DNS **pour une seule interface**, de façon réversible, en pointant vers un serveur inexistant et en ignorant les DNS reçus par DHCP :

```bash
IF=$(ip route show default | cut -d' ' -f5)
sudo nmcli device modify "$IF" ipv4.dns 203.0.113.1 ipv4.ignore-auto-dns yes
grep '^nameserver' /etc/resolv.conf
ping -c 2 -W 2 1.1.1.1                 # fonctionne
ping -c 2 -W 2 rockylinux.org          # échoue : « Temporary failure in name resolution »
dig +time=2 +tries=1 rockylinux.org | tail -5
```

Diagnostic :

```bash
dig @1.1.1.1 +short rockylinux.org      # un serveur DNS valide répond-il ?
getent hosts rockylinux.org || echo "résolution système KO"
```

> ❓ **Question 4** : Pourquoi `ping 1.1.1.1` réussit-il alors que `ping rockylinux.org` échoue ? Que conclut-on ?

Réparation (la modification de `nmcli device modify` n'est pas écrite dans le profil : on réapplique celui-ci) :

```bash
sudo nmcli device reapply "$IF"
grep '^nameserver' /etc/resolv.conf
ping -c 2 rockylinux.org
```

### Étape 5 — Panne n°2 : le pare-feu

Installez un serveur web de test et observez le pare-feu **avant** de toucher à quoi que ce soit :

```bash
sudo dnf install -y nginx
sudo systemctl enable --now nginx
curl -sI http://localhost | head -1
sudo systemctl enable --now firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
```

La zone `public` n'autorise que `ssh` : le port 80 est donc **déjà filtré** depuis l'extérieur. Vérifiez-le **depuis votre ordinateur hôte** (second terminal, adresse du réseau privé de la VM) :

```bash
# Sur l'HÔTE (pas dans la VM) :
curl -sI --max-time 3 http://192.168.56.10 | head -1 || echo "bloqué par le pare-feu"
```

> ❓ **Question 5** : Pourquoi `curl http://localhost` fonctionne-t-il **dans la VM** alors que la même requête depuis l'hôte est bloquée ? *(Indice : le trafic de l'interface `lo` est toujours accepté ; un test depuis la machine elle-même ne prouve rien sur le pare-feu.)*

Ouvrez le port (d'abord en temporaire), puis retestez depuis l'hôte :

```bash
sudo firewall-cmd --add-service=http --timeout=120      # ouvert 120 s seulement
# Sur l'HÔTE :  curl -sI --max-time 3 http://192.168.56.10 | head -1     → HTTP/1.1 200 OK
sudo firewall-cmd --list-services
```

Rendre l'ouverture permanente, puis la défaire :

```bash
sudo firewall-cmd --permanent --add-service=http && sudo firewall-cmd --reload
sudo firewall-cmd --list-services
sudo firewall-cmd --permanent --remove-service=http && sudo firewall-cmd --reload
```

> ❓ **Question 6** : Quelle différence observe-t-on entre un port **rejeté** (la zone `public` répond tout de suite « No route to host » / `Connection refused`) et un port **abandonné silencieusement** (délai d'attente) ? Testez : depuis l'hôte, `nc -zv -w 3 192.168.56.10 9999` ; puis dans la VM `sudo firewall-cmd --zone=drop --change-interface=enp0s8` et relancez le test (délai) ; enfin `sudo firewall-cmd --zone=public --change-interface=enp0s8` pour revenir.

### Étape 6 — Observer le trafic

```bash
sudo dnf install -y tcpdump
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
tracepath -n rockylinux.org | head
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
sudo firewall-cmd --get-active-zones      # enp0s8 doit être revenue en zone « public »
sudo firewall-cmd --list-services       # seulement ssh (et dhcpv6-client)
sudo systemctl disable --now nginx
sudo dnf remove -y nginx && sudo dnf autoremove -y
```

## ✅ Validation

- [ ] `~/reseau/etat-normal.txt` contient IP, routes et DNS.
- [ ] Vous avez reproduit la panne DNS (`ping IP` OK, `ping nom` KO) puis l'avez réparée.
- [ ] Vous avez constaté le filtrage du port 80 par `firewalld` depuis l'hôte, puis l'avez ouvert (temporaire puis permanent) et refermé.
- [ ] Vous distinguez « port rejeté » (refus immédiat) et « port abandonné » (silence, zone `drop`).
- [ ] `firewalld` est revenu à sa configuration d'origine (zone `public`, service `ssh` seul).
- [ ] `~/reseau/rapport.md` est rempli.

## 💡 Pour aller plus loin

- **Défi 1** : configurez une IP statique sur une interface factice avec `nmcli connection add type dummy …` (voir le cours), puis supprimez-la.
- **Défi 2** : écrivez un script qui teste automatiquement passerelle, IP publique, DNS et HTTP et affiche `OK`/`KO` pour chacun.
- **Défi 3** : interrogez les enregistrements MX et NS d'un domaine avec `dig`.
- **Défi 4** : utilisez `mtr -rw -c 10 rockylinux.org` pour repérer un saut avec perte de paquets.

---

## 🏆 Défi du jour

**Objectif** : Diagnostiquer, couche par couche, un service « injoignable par son nom » dont la panne vient d'une entrée `/etc/hosts` erronée.

**Contexte** : Un collègue affirme que « l'intranet est tombé » : `http://intranet.kamer.test:8088/` ne répond pas. Le service tourne pourtant. À toi de prouver où est la panne.

**Consignes** :
- Lance un petit serveur local : `python3 -m http.server 8088 --bind 127.0.0.1 &`.
- Ajoute **volontairement** la mauvaise entrée `127.0.0.9 intranet.kamer.test` à `/etc/hosts`.
- Constate que `curl --max-time 3 http://intranet.kamer.test:8088/` échoue, puis établis le diagnostic : que renvoie `getent hosts intranet.kamer.test` ? Sur quelle adresse le serveur écoute-t-il (`ss`) ? Que donne `curl http://127.0.0.1:8088/` ?
- Écris dans `~/defi-reseau.txt` : la cause en une phrase, l'IP de ta passerelle par défaut (`ip route`) et le serveur DNS utilisé (`/etc/resolv.conf`).
- Corrige `/etc/hosts` (l'entrée doit pointer vers `127.0.0.1`) et vérifie que `curl` répond `200`.

**Indices** (à consulter seulement si bloqué) :
- `ss -tlnp | grep 8088` montre l'adresse d'écoute : `127.0.0.1:8088`.
- `curl: (7) Failed to connect` (« refused ») = personne n'écoute à cette adresse ; ici 127.0.0.9 ≠ 127.0.0.1.
- `ip route | grep default` donne la passerelle ; `grep -m1 '^nameserver' /etc/resolv.conf` le DNS.

**Critères de réussite** :
- [ ] `curl -s -o /dev/null -w '%{http_code}' http://intranet.kamer.test:8088/` renvoie `200`.
- [ ] `getent hosts intranet.kamer.test` renvoie `127.0.0.1`.
- [ ] `~/defi-reseau.txt` nomme la cause (entrée `/etc/hosts` erronée), la passerelle et le DNS.
- [ ] Le serveur de test est arrêté à la fin (`kill %1`).

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
python3 -m http.server 8088 --bind 127.0.0.1 >/dev/null 2>&1 &
sleep 1
echo "127.0.0.9 intranet.kamer.test" | sudo tee -a /etc/hosts

curl --max-time 3 http://intranet.kamer.test:8088/ ; echo "code=$?"      # échec (7)
getent hosts intranet.kamer.test                                         # 127.0.0.9  ← mauvaise adresse
ss -tlnp | grep 8088                                                      # écoute sur 127.0.0.1:8088
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8088/          # 200 : le service est sain

{
  echo "Cause : /etc/hosts envoie intranet.kamer.test vers 127.0.0.9 alors que le service écoute sur 127.0.0.1."
  echo "Passerelle : $(ip route | grep default | cut -d' ' -f3)"
  echo "DNS : $(grep -m1 '^nameserver' /etc/resolv.conf)"
} > ~/defi-reseau.txt

sudo sed -i 's/^127.0.0.9 intranet.kamer.test/127.0.0.1 intranet.kamer.test/' /etc/hosts
curl -s -o /dev/null -w '%{http_code}\n' http://intranet.kamer.test:8088/   # 200
kill %1
```

Méthode : **nom → adresse → port → application**. Ici la couche DNS/résolution (le fichier `hosts`, consulté avant le DNS) était en cause ; le service, lui, n'a jamais été en panne.

</details>

---

Atelier suivant : [SSH sécurisé](atelier-04-ssh-securise.md).
