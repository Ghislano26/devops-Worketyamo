# Atelier 01 — Résolution DNS : dig, resolvectl, dnsmasq et TTL

## 🎯 Objectifs

- Suivre une résolution complète avec `dig +trace` et lire une réponse annotée.
- Distinguer ce que voit `dig` de ce que voient les applications (`getent`, `/etc/hosts`).
- Comprendre `/etc/resolv.conf` sous Ubuntu 24.04 et modifier le resolver proprement avec `resolvectl`.
- Créer une **zone locale** avec `dnsmasq` (A, CNAME, MX, TXT, SRV).
- Observer le **TTL** décroître dans un cache.

## 📋 Prérequis

- Modules 00 à 02 terminés ; snapshot de la VM pris.
- Cours lu : [DNS : les fondamentaux](../cours/01-dns-fondamentaux.md).
- Paquets : `sudo apt install -y dnsutils dnsmasq`. L'installation de `dnsmasq` peut échouer à démarrer (le port 53 est déjà pris par `systemd-resolved`) : c'est normal, on le reconfigure à l'étape 5.

## 🧪 Scénario

*Kamer Logistics* migre son application vers un nouveau serveur. Avant de toucher au DNS de production, on vous demande
de **comprendre** la résolution et de **répéter** la procédure sur une zone de test locale `kamer.test`, y compris le comportement des caches.

## Étapes

### Étape 1 — Suivre la résolution depuis la racine

```bash
mkdir -p ~/dns && cd ~/dns
dig +trace www.ubuntu.com | tee trace.txt | grep -E "^[^;].*(NS|A|CNAME)" | head -20
grep "Received" trace.txt
```

> ❓ **Question 1** : Combien d'étapes (blocs « Received ») comptez-vous ? Quels serveurs ont été interrogés successivement (racine, TLD `.com`, autoritaire) ?
> ❓ **Question 2** : Pourquoi la **question** reste-t-elle identique à chaque étape alors que le **serveur interrogé** change ?

### Étape 2 — Lire une réponse classique

```bash
dig ubuntu.com
```

Repérez : `status:` (NOERROR / NXDOMAIN), les **flags** (`qr rd ra`, et `aa` s'il est présent), la section ANSWER, le **TTL**, le serveur qui a répondu (`SERVER:`), le temps (`Query time`).

```bash
dig +short A ubuntu.com
dig +short AAAA ubuntu.com
dig +short MX gmail.com
dig +short TXT gmail.com | head -3
dig +short NS ubuntu.com
dig SOA ubuntu.com +noall +answer
dig -x 1.1.1.1 +short
dig nexistepas-kamer-12345.ubuntu.com | grep -E "status|AUTHORITY" -A1
```

> ❓ **Question 3** : Quel `status` obtenez-vous pour le nom inexistant ? Quel enregistrement apparaît en section AUTHORITY et à quoi sert son dernier champ (TTL négatif) ?

### Étape 3 — Interroger différents serveurs

```bash
dig @1.1.1.1 +short ubuntu.com
dig @8.8.8.8 +short ubuntu.com
NS=$(dig +short NS ubuntu.com | head -1); echo "autoritaire : $NS"
dig @"$NS" ubuntu.com +noall +comments +answer | head -8
```

> ❓ **Question 4** : Sur la requête envoyée directement à l'autoritaire, le flag `aa` apparaît-il ? Que signifie-t-il ?

### Étape 4 — Ce que voient `dig` et les applications

```bash
resolvectl status | head -15
ls -l /etc/resolv.conf
cat /etc/resolv.conf | grep -v '^#'
echo "10.99.99.99 intranet.kamer.test" | sudo tee -a /etc/hosts
dig +short intranet.kamer.test            # rien : dig n'utilise pas /etc/hosts
getent hosts intranet.kamer.test          # trouvé : les applications passent par nsswitch
ping -c1 intranet.kamer.test 2>&1 | head -1
grep ^hosts /etc/nsswitch.conf
sudo sed -i '/intranet.kamer.test/d' /etc/hosts
```

> ❓ **Question 5** : Sur Ubuntu 24.04, `/etc/resolv.conf` contient `nameserver 127.0.0.53`. Qui écoute à cette adresse ? Pourquoi cela change-t-il la façon de modifier le resolver ?
> ❓ **Question 6** : Pourquoi `dig` ne trouve-t-il pas l'entrée alors que `getent` la trouve ?

### Étape 5 — Créer une zone locale avec dnsmasq

`dnsmasq` écoutera sur une adresse **dédiée** `127.0.0.2` pour ne pas entrer en conflit avec `systemd-resolved` (127.0.0.53).

```bash
sudo systemctl stop dnsmasq 2>/dev/null
sudo tee /etc/dnsmasq.d/kamer-test.conf > /dev/null <<'EOF'
# Écoute uniquement sur 127.0.0.2:53
listen-address=127.0.0.2
bind-interfaces
no-resolv
no-hosts
# Ne relaie pas les noms de la zone locale vers Internet
local=/kamer.test/
# TTL des enregistrements locaux
local-ttl=60

# Enregistrements A et AAAA
address=/app.kamer.test/10.10.10.10
host-record=api.kamer.test,10.10.10.20,fd00::20
# Alias
cname=www.kamer.test,app.kamer.test
# Messagerie, texte (SPF), service (SRV)
mx-host=kamer.test,mail.kamer.test,10
host-record=mail.kamer.test,10.10.10.30
txt-record=kamer.test,"v=spf1 mx -all"
srv-host=_sip._tcp.kamer.test,sip1.kamer.test,5060,10,60
host-record=sip1.kamer.test,10.10.10.40

# Pour tout le reste : relayer vers un resolver public (cache inclus)
server=1.1.1.1
EOF
sudo dnsmasq --test
sudo systemctl restart dnsmasq
systemctl is-active dnsmasq
sudo ss -ulnp | grep ":53 "
```

> 💡 **Conseil** : si `dnsmasq` refuse de démarrer, lisez `journalctl -u dnsmasq -n 20`. Une erreur « address already in use » indique un conflit sur le port 53 : vérifiez `listen-address` et `bind-interfaces`.

Interrogez la zone :

```bash
dig @127.0.0.2 +short app.kamer.test
dig @127.0.0.2 +short www.kamer.test            # CNAME puis A
dig @127.0.0.2 +short AAAA api.kamer.test
dig @127.0.0.2 +short MX kamer.test
dig @127.0.0.2 +short TXT kamer.test
dig @127.0.0.2 +short SRV _sip._tcp.kamer.test
dig @127.0.0.2 inexistant.kamer.test | grep status
dig @127.0.0.2 +short ubuntu.com                # relayé vers 1.1.1.1
```

> ❓ **Question 7** : Dans la réponse à `www.kamer.test`, que voyez-vous (deux lignes) ? Pourquoi un CNAME ne peut-il pas coexister avec d'autres enregistrements sur le même nom ?
> ❓ **Question 8** : Quels sont les 4 champs d'un enregistrement SRV renvoyés ? Quel rôle joue chacun ?

### Étape 6 — Brancher la zone sur le système (routage par domaine)

Plutôt que d'éditer `/etc/resolv.conf` (un lien géré par `systemd-resolved`), on dit à `resolved` d'envoyer **uniquement** le domaine `kamer.test` à `127.0.0.2` :

```bash
IFACE=$(ip route show default | cut -d' ' -f5); echo "interface : $IFACE"
sudo resolvectl dns "$IFACE" 127.0.0.2 1.1.1.1
sudo resolvectl domain "$IFACE" '~kamer.test'
resolvectl status "$IFACE" | head -12
getent hosts app.kamer.test                      # résolu par les applications !
ping -c1 www.kamer.test 2>&1 | head -1
resolvectl query app.kamer.test
resolvectl query ubuntu.com | head -3             # le reste passe par 1.1.1.1
```

Vérifiez le comportement si dnsmasq tombe :

```bash
sudo systemctl stop dnsmasq
getent hosts app.kamer.test || echo "échec attendu"
sudo systemctl start dnsmasq
```

> ❓ **Question 9** : Que signifie le `~` devant `kamer.test` dans `resolvectl domain` ? En quoi est-ce différent d'un simple domaine de recherche (*search domain*) ?

### Étape 7 — Modifier `/etc/resolv.conf` à la main (démonstration contrôlée)

> ⚠️ **Attention** : à ne faire que dans la VM, en suivant le retour arrière ci-dessous.

```bash
sudo cp -P /etc/resolv.conf ~/dns/resolv.conf.sauvegarde        # -P : conserve le lien symbolique
readlink /etc/resolv.conf
sudo rm /etc/resolv.conf
echo "nameserver 127.0.0.2" | sudo tee /etc/resolv.conf
dig +short app.kamer.test                                        # dig suit /etc/resolv.conf directement
dig +short ubuntu.com                                            # relayé par dnsmasq vers 1.1.1.1

# Retour arrière
sudo rm /etc/resolv.conf
sudo ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
ls -l /etc/resolv.conf
dig +short ubuntu.com
```

> ❓ **Question 10** : Pourquoi une modification directe de `/etc/resolv.conf` est-elle fragile sous Ubuntu moderne ? Quel mécanisme la remplacerait ?

### Étape 8 — Observer le TTL et le cache

`dnsmasq` met en cache les réponses relayées vers `1.1.1.1`.

```bash
for i in 1 2 3 4; do dig @127.0.0.2 ubuntu.com +noall +answer | head -1; sleep 5; done
```

Le TTL de la **première** ligne devrait **diminuer** d'environ 5 secondes à chaque essai (si le cache est utilisé), puis remonter après expiration.

```bash
# Affichez uniquement les TTL
for i in 1 2 3 4; do dig @127.0.0.2 ubuntu.com +noall +answer | awk '{print "TTL =", $2}' | head -1; sleep 5; done

# Comparez avec un enregistrement LOCAL (TTL fixe fixé par local-ttl=60)
for i in 1 2 3; do dig @127.0.0.2 app.kamer.test +noall +answer | awk '{print "TTL =", $2}'; sleep 3; done

# Forcer l'expiration : vider les caches
sudo systemctl restart dnsmasq
resolvectl flush-caches
resolvectl statistics | grep -iE "cache|hit|miss"
```

> ❓ **Question 11** : Pourquoi le TTL de l'enregistrement local reste-t-il à 60 alors que celui de `ubuntu.com` décroît ? Quel rôle joue le cache de `dnsmasq` ?

### Étape 9 — Simuler une migration avec un TTL bas

```bash
# Avant : app.kamer.test → 10.10.10.10
dig @127.0.0.2 +short app.kamer.test
# On « migre » : nouvelle IP
sudo sed -i 's#address=/app.kamer.test/10.10.10.10#address=/app.kamer.test/10.10.10.99#' /etc/dnsmasq.d/kamer-test.conf
sudo systemctl restart dnsmasq
dig @127.0.0.2 +short app.kamer.test
```

> ❓ **Question 12** : Dans un vrai DNS public avec TTL de 86400, quand tous les clients verraient-ils la nouvelle IP ? Quelle séquence (J-2, J, J+1) auriez-vous suivie ?

### Étape 10 — Nettoyage

```bash
IFACE=$(ip route show default | cut -d' ' -f5)
sudo resolvectl revert "$IFACE"
sudo systemctl disable --now dnsmasq
sudo rm /etc/dnsmasq.d/kamer-test.conf
ls -l /etc/resolv.conf
dig +short ubuntu.com
```

## ✅ Validation

- [ ] Vous avez compté les étapes de `dig +trace` et nommé les serveurs de chaque niveau.
- [ ] Vous avez montré que `dig` ignore `/etc/hosts` mais pas `getent`.
- [ ] `dig @127.0.0.2` renvoie A, CNAME, MX, TXT et SRV pour `kamer.test`.
- [ ] `getent hosts app.kamer.test` fonctionne grâce à `resolvectl` (routage par domaine `~kamer.test`).
- [ ] Vous avez observé un TTL qui **décroît** dans le cache.
- [ ] `/etc/resolv.conf` est de nouveau le lien vers `stub-resolv.conf` et la résolution Internet fonctionne.
- [ ] Vous savez expliquer pourquoi il n'y a pas de « propagation DNS » mais des caches qui expirent.

## 💡 Pour aller plus loin

- **Défi 1** : ajoutez un deuxième serveur autoritaire fictif et comparez `dig +trace` sur votre zone locale.
- **Défi 2** : configurez deux vues (*split-horizon*) avec deux instances `dnsmasq` répondant des IP différentes.
- **Défi 3** : décodez un SPF réel (`dig +short TXT gmail.com`) et expliquez chaque mécanisme.
- **Défi 4** : dans un cluster Kubernetes de test (kind, minikube), lisez le `Corefile` et mesurez l'effet de `ndots:5` avec `tcpdump`.

Atelier suivant : [Ports et services](atelier-02-ports-et-services.md).
