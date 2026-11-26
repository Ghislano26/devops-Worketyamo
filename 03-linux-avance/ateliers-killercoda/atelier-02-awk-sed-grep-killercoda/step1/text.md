# Étape 1 : interroger un journal

Créez un petit journal d'accès web (colonnes : IP, méthode, page, code HTTP) :

```bash
mkdir -p /tmp/luc && cd /tmp/luc
cat > access.log <<'EOF'
10.1.1.5 GET /index 200
10.1.1.7 GET /panier 404
10.1.1.5 POST /login 401
10.1.1.9 GET /index 200
10.1.1.5 GET /api 500
10.1.1.7 GET /index 404
10.1.1.9 GET /panier 200
10.1.1.5 GET /index 200
10.1.1.12 GET /contact 404
10.1.1.5 GET /index 200
EOF
wc -l access.log
```{{exec}}

Quelques réflexes (voir le [cours Traitement de texte avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/03-linux-avance/cours/02-traitement-texte-avance.md)) :

```bash
grep -c " 404" access.log                       # combien de 404 ?
grep -v " 200" access.log                       # tout sauf les succès
awk '{print $1}' access.log | sort | uniq -c    # requêtes par IP (méthode « pipe »)
```{{exec}}

## À vous de jouer

1. Avec **`awk`**, trouvez l'**IP la plus active** et enregistrez la ligne `NOMBRE IP` dans `/tmp/luc/top-ip.txt` (comptage avec un **tableau associatif** : `c[$1]++`) ;
2. Avec **`grep -c`**, enregistrez le nombre de réponses `404` dans `/tmp/luc/nb404.txt`.

```bash
awk '{c[$1]++} END {for (i in c) print c[i], i}' access.log | sort -nr | head -n 1 > top-ip.txt
grep -c " 404" access.log > nb404.txt
cat top-ip.txt nb404.txt
```{{exec}}

> Pourquoi `sort -nr` ? `-n` trie numériquement (sinon « 10 » < « 9 »), `-r` met le plus grand en premier.

Cliquez sur **Vérifier**.
