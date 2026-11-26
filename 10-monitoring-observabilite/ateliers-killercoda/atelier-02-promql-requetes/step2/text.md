# Étape 2 : classer avec `topk()` et `sort_desc()`

Quels **conteneurs** consomment le plus de CPU ? cAdvisor expose `container_cpu_usage_seconds_total` (un **counter**, par conteneur). Deux conteneurs de démonstration tournent : `charge-cpu` (boucle infinie : ~100 % d'un cœur) et `charge-legere`.

Observez les labels de la métrique, puis calculez le taux par conteneur :

```bash
curl -s 'localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total{name!=""}' | jq -r '.data.result[] | .metric.name' | sort -u
curl -s --data-urlencode 'query=sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[1m]))' localhost:9090/api/v1/query | jq -r '.data.result[] | "\(.metric.name)\t\(.value[1])"'
```{{exec}}

## À vous de jouer

Écrivez la requête qui renvoie les **3 conteneurs les plus gourmands, triés par ordre décroissant** :

- `sum by (name) (rate(...[1m]))` : taux de CPU par conteneur (en cœurs) ;
- `topk(3, ...)` : garde les 3 plus grands ;
- `sort_desc(...)` : **trie** le résultat (l'API ne garantit aucun ordre sinon).

```bash
cat > ~/monitoring/requete-top3.promql <<'EOF'
sort_desc(topk(3, sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[1m]))))
EOF
curl -s --data-urlencode "query@$HOME/monitoring/requete-top3.promql" localhost:9090/api/v1/query | jq -r '.data.result[] | "\(.metric.name)\t\(.value[1])"'
```{{exec}}

`charge-cpu` doit arriver en tête, avec une valeur proche de **1** (un cœur entier).

> **Variante sans cAdvisor** (si `name` est vide chez vous) : classez les **modes** CPU de `node_exporter` : `sort_desc(topk(3, sum by (mode) (rate(node_cpu_seconds_total{mode!="idle"}[1m]))))`. Remplacez alors la requête dans le fichier.

## Questions

- Pourquoi `sum by (name)` avant `topk` ? (cAdvisor produit une série par cœur et par conteneur : on les additionne par nom.)
- Que renvoie `topk(3, …)` s'il n'y a que 2 conteneurs ? (2 séries : jamais d'erreur.)

Cliquez sur **Vérifier**.
