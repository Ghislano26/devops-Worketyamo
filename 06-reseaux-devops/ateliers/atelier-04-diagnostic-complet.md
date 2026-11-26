# Atelier 04 — Diagnostic complet : DNS, port et certificat

## 🎯 Objectifs

- Mener un diagnostic **méthodique** : DNS → TCP → TLS → HTTP → application.
- Identifier **trois pannes cumulées** : mauvais DNS, port fermé, certificat expiré.
- Corriger chaque panne, **prouver** la correction et rédiger un rapport d'incident.

## 📋 Prérequis

- Ateliers [01](atelier-01-dns-resolution.md) à [03](atelier-03-routage-nat.md) terminés.
- Cours lus : [DNS](../cours/01-dns-fondamentaux.md), [ports](../cours/02-ports-et-sockets.md), [TLS](../cours/04-tls-et-https.md) et surtout [diagnostic](../cours/05-diagnostic-reseau-devops.md) (arbre de décision).
- Paquets : `sudo apt install -y openssl curl netcat-openbsd dnsutils faketime iproute2`.
- Snapshot de la VM pris.

> 💡 **Conseil** : n'ouvrez la section **« Corrigé »** qu'après avoir tenté le diagnostic vous-même. Notez dans un fichier chaque commande lancée et ce que vous en concluez.

## 🧪 Scénario

Vous êtes d'astreinte chez *Kamer Logistics*. Le chef de projet écrit : **« L'application de suivi
`https://app.kamer.test:8443/` ne répond plus depuis ce matin. Rien n'a été déployé, mais l'équipe infra a
touché au serveur hier soir. »** Vous disposez d'un accès à la machine. Votre mission : retrouver **toutes** les
causes et rétablir le service, sans « tout désactiver pour voir ».

## Étape 0 — Mise en place de la panne (script fourni)

Ce script crée l'application, la casse de **trois façons** et vous laisse en situation d'incident. **Résistez à la tentation de
le lire en détail** : il contient la réponse, et un vrai incident ne vous livre pas son code source. Lancez-le simplement.

```bash
mkdir -p ~/diag && cd ~/diag
cat > panne.sh <<'EOF'
#!/usr/bin/env bash
# panne.sh — crée l'environnement de l'atelier (application HTTPS + 3 défauts)
set -euo pipefail
cd "$(dirname "$0")"
pkill -f "s_server -accept" 2>/dev/null || true
sudo sed -i '/app.kamer.test/d' /etc/hosts

# Certificat de l'application, valable 1 jour... mais émis il y a 10 jours : donc EXPIRÉ
faketime '10 days ago' openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -keyout app.key -out app.crt -subj "/CN=app.kamer.test" \
  -addext "subjectAltName=DNS:app.kamer.test" 2>/dev/null

# Défaut n°1 (DNS) : le nom pointe vers une mauvaise adresse
echo "127.0.0.9 app.kamer.test" | sudo tee -a /etc/hosts >/dev/null

# Défaut n°2 (port) : l'application écoute sur 9443 au lieu de 8443, sur l'interface locale
nohup openssl s_server -accept 127.0.0.1:9443 -cert app.crt -key app.key -www \
  >/tmp/app-diag.log 2>&1 &
sleep 1
echo "Environnement prêt. L'application « de production » devrait répondre sur https://app.kamer.test:8443/"
EOF
chmod +x panne.sh
./panne.sh
```

Constat du support : « `curl https://app.kamer.test:8443/` ne marche pas ».

```bash
curl -sS --max-time 5 https://app.kamer.test:8443/ ; echo "code = $?"
```

## Étapes (à mener vous-même)

### Étape 1 — Cadrer le problème

Avant toute commande, répondez par écrit :

- Quel est le **symptôme exact** (message d'erreur, code de retour) ?
- Qu'est-ce qui est **censé** se passer (nom, port, protocole, certificat) ?
- Qu'est-ce qui a **changé** ? *(L'équipe infra a « touché au serveur ».)*

### Étape 2 — Couche DNS

```bash
HOST=app.kamer.test
dig +short $HOST
getent hosts $HOST
grep kamer /etc/hosts
```

> ❓ **Question 1** : `dig` et `getent` donnent-ils le même résultat ? Si non, que cela suggère-t-il ? Vers quelle adresse le nom pointe-t-il, et est-ce la bonne (l'application tourne sur la machine locale, `127.0.0.1`) ?

Corrigez la panne **n°1**, puis **prouvez** la correction :

```bash
# (à vous d'écrire la commande de correction, puis :)
getent hosts $HOST
```

### Étape 3 — Couche transport (TCP)

```bash
nc -zv -w3 $HOST 8443 ; echo "code = $?"
```

> ❓ **Question 2** : Le résultat est-il « refused » ou « timeout » ? Qu'en déduisez-vous (rien n'écoute vs paquets jetés) ?

Cherchez **où** l'application écoute réellement :

```bash
sudo ss -tlnp | grep -E "openssl|s_server"
sudo lsof -iTCP -sTCP:LISTEN -nP | grep -i openssl
cat /tmp/app-diag.log | head
```

> ❓ **Question 3** : Sur quel port et sur quelle adresse l'application écoute-t-elle ? Que faut-il changer : le port du **client** ou celui du **serveur** ? *(Qui a raison : l'énoncé annonce 8443.)*

Corrigez la panne **n°2** (redémarrez l'application sur le bon port) :

```bash
pkill -f "s_server -accept"
# (à vous : relancez openssl s_server sur 127.0.0.1:8443 avec ~/diag/app.crt et app.key, en arrière-plan)
sleep 1
nc -zv -w3 $HOST 8443 ; echo "code = $?"
```

### Étape 4 — Couche TLS

```bash
openssl s_client -connect $HOST:8443 -servername $HOST </dev/null 2>&1 | grep -E "Verify return code|subject=|issuer=|notAfter|Protocol|Cipher"
openssl x509 -in ~/diag/app.crt -noout -subject -dates -ext subjectAltName
openssl x509 -checkend 0 -noout -in ~/diag/app.crt && echo "valide" || echo "EXPIRÉ"
date
```

> ❓ **Question 4** : Quel `Verify return code` obtenez-vous ? Quelles sont les dates `notBefore` / `notAfter` comparées à la date du jour ? Le **nom** du certificat (SAN) est-il correct ?
> ❓ **Question 5** : Ce certificat est **auto-signé** : même sans l'expiration, le client le refuserait. Pourquoi ? Comment contourner ce point **pour le test uniquement** (`--cacert`) ?

Confirmez que c'est bien le certificat qui bloque (sans « réparer » avec `-k`) :

```bash
curl -sS --max-time 5 https://$HOST:8443/ 2>&1 | head -3
curl -sS --max-time 5 --cacert ~/diag/app.crt https://$HOST:8443/ 2>&1 | head -3     # on fait confiance à CE certificat : reste l'expiration
curl -ks --max-time 5 -o /dev/null -w "avec -k : HTTP %{http_code}\n" https://$HOST:8443/    # DIAGNOSTIC seulement
```

> ⚠️ **Attention** : `curl -k` prouve que « le reste fonctionne », mais **ne corrige rien**. Ne le laissez jamais dans un script ni une configuration.

Corrigez la panne **n°3** : générez un nouveau certificat **valide** (30 jours, SAN correct) puis relancez le serveur :

```bash
cd ~/diag
# (à vous : openssl req -x509 ... -days 30 ... -addext "subjectAltName=DNS:app.kamer.test")
# (à vous : redémarrer s_server avec le nouveau certificat)
openssl x509 -in app.crt -noout -dates
```

### Étape 5 — Couche HTTP et application

```bash
curl -sS --cacert ~/diag/app.crt --max-time 5 -o /dev/null \
  -w "dns=%{time_namelookup}s tcp=%{time_connect}s tls=%{time_appconnect}s total=%{time_total}s HTTP %{http_code}\n" \
  https://$HOST:8443/
curl -sS --cacert ~/diag/app.crt --max-time 5 -I https://$HOST:8443/ | head -3
```

> ❓ **Question 6** : Quel code HTTP obtenez-vous ? Si le TLS passait mais que vous aviez un `404` ou `502`, dans quelle couche chercheriez-vous la cause ?

### Étape 6 — Preuve de bon fonctionnement

Écrivez un script `verif.sh` qui rejoue la checklist et affiche `OK`/`KO` pour chaque étape, puis exécutez-le. Inspirez-vous du script de diagnostic du [cours 05](../cours/05-diagnostic-reseau-devops.md) en y ajoutant `--cacert ~/diag/app.crt` et la vérification de l'expiration à 7 jours :

```bash
cat > ~/diag/verif.sh <<'EOF'
#!/usr/bin/env bash
set -u
HOST=app.kamer.test; PORT=8443; CA=~/diag/app.crt
ok(){ printf '  OK  %s\n' "$1"; }; ko(){ printf '  KO  %s\n' "$1"; RES=1; }
RES=0
[[ -n "$(getent hosts $HOST | cut -d' ' -f1 | grep -E '^127\.0\.0\.1$')" ]] && ok "DNS : $HOST → 127.0.0.1" || ko "DNS"
nc -z -w3 $HOST $PORT && ok "TCP $PORT" || ko "TCP $PORT"
openssl x509 -checkend $((7*86400)) -noout -in "$CA" >/dev/null && ok "certificat valide > 7 jours" || ko "certificat expire dans < 7 jours"
code=$(curl -s --cacert "$CA" --max-time 5 -o /dev/null -w '%{http_code}' https://$HOST:$PORT/)
[[ "$code" == 200 ]] && ok "HTTP $code" || ko "HTTP $code"
exit $RES
EOF
chmod +x ~/diag/verif.sh
~/diag/verif.sh ; echo "bilan = $?"
```

### Étape 7 — Rapport d'incident

Rédigez `~/diag/rapport.md` avec cette trame :

```text
# Rapport d'incident — app.kamer.test
## Résumé
## Chronologie (commande → constat → conclusion)
## Causes racines (une par panne : DNS, port, certificat)
## Correctifs appliqués
## Comment l'éviter / détecter plus tôt (alertes, tests synthétiques, supervision d'expiration)
```

## 🔍 Corrigé (à ouvrir **après** votre diagnostic)

<details>
<summary>Voir la solution détaillée</summary>

**Panne 1 — DNS.** `getent hosts app.kamer.test` renvoie `127.0.0.9` (entrée `/etc/hosts`), alors que l'application est sur `127.0.0.1`. `dig +short` ne renvoie rien (le nom n'existe pas dans le vrai DNS) : divergence `dig` / `getent` = indice d'un **`/etc/hosts`** ou d'un résolveur local.

```bash
sudo sed -i 's/^127.0.0.9 app.kamer.test/127.0.0.1 app.kamer.test/' /etc/hosts
getent hosts app.kamer.test        # 127.0.0.1
```

**Panne 2 — Port.** `nc -zv app.kamer.test 8443` → *Connection refused* (réponse immédiate : la machine est joignable, **personne n'écoute** sur 8443). `ss -tlnp` montre `openssl` sur `127.0.0.1:9443`.

```bash
pkill -f "s_server -accept"
cd ~/diag
nohup openssl s_server -accept 127.0.0.1:8443 -cert app.crt -key app.key -www >/tmp/app-diag.log 2>&1 &
```

**Panne 3 — Certificat.** `Verify return code: 10 (certificate has expired)` (auto-signé : sans `--cacert`, `18/19`). `notAfter` est 9 jours dans le passé.

```bash
cd ~/diag
openssl req -x509 -newkey rsa:2048 -nodes -days 30 -keyout app.key -out app.crt \
  -subj "/CN=app.kamer.test" -addext "subjectAltName=DNS:app.kamer.test"
pkill -f "s_server -accept"
nohup openssl s_server -accept 127.0.0.1:8443 -cert app.crt -key app.key -www >/tmp/app-diag.log 2>&1 &
```

**Vérification finale :** `curl --cacert ~/diag/app.crt https://app.kamer.test:8443/` → `HTTP 200`.

**Leçon :** les pannes se **masquent l'une l'autre**. Le DNS cassé empêchait de voir le port fermé, qui empêchait de voir le certificat expiré. D'où l'intérêt de suivre l'**ordre** de la checklist et de corriger **une couche à la fois**.

</details>

### Nettoyage

```bash
pkill -f "s_server -accept" 2>/dev/null
sudo sed -i '/app.kamer.test/d' /etc/hosts
grep kamer /etc/hosts || echo "hosts propre"
```

## ✅ Validation

- [ ] Vous avez identifié les **trois** pannes dans l'ordre DNS → port → certificat, avec la commande qui prouve chacune.
- [ ] Vous avez distingué « refused » (rien n'écoute) de « timeout » (filtré).
- [ ] Vous avez corrigé le certificat **sans** utiliser `curl -k` comme solution.
- [ ] `verif.sh` affiche quatre `OK` et se termine avec le code 0.
- [ ] `rapport.md` contient la chronologie, les causes racines et une mesure de détection préventive.
- [ ] `/etc/hosts` est revenu à son état initial.

## 💡 Pour aller plus loin

- **Défi 1** : rejouez l'atelier avec un **certificat au mauvais SAN** (`DNS:autre.kamer.test`) et reconnaissez le message `hostname mismatch`.
- **Défi 2** : ajoutez à `verif.sh` une mesure de latence par phase (`curl -w`) et un seuil d'alerte.
- **Défi 3** : écrivez une sonde de supervision qui exporte « jours restants avant expiration » pour Prometheus (fichier texte pour `node_exporter`).
- **Défi 4** : transposez le scénario dans Kubernetes : Service au mauvais `targetPort`, Ingress avec certificat expiré, DNS interne erroné. Menez le diagnostic avec `kubectl` et `netshoot`.

Retour au [sommaire du module 06](../README.md).
