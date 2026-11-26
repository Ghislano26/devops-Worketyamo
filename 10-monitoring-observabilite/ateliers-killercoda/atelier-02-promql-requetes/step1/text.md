# Étape 1 : de `node_cpu_seconds_total` à un pourcentage

`node_cpu_seconds_total` est un **counter** : le nombre de secondes CPU passées dans chaque **mode** (`idle`, `user`, `system`…), cumulé depuis le démarrage. Sa valeur brute ne veut rien dire : on calcule un **taux** avec `rate()` (voir le [cours 03](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/03-promql-et-metriques.md)).

Observez d'abord la métrique brute puis son taux, avec l'API HTTP :

```bash
cd ~/monitoring
curl -s 'localhost:9090/api/v1/query?query=node_cpu_seconds_total{mode="idle"}' | jq '.data.result[0]'
curl -s --data-urlencode 'query=rate(node_cpu_seconds_total{mode="idle"}[1m])' localhost:9090/api/v1/query | jq '.data.result[] | {cpu: .metric.cpu, taux: .value[1]}'
```{{exec}}

Un taux d'`idle` de 0,95 signifie « 95 % du temps au repos » sur ce cœur.

## À vous de jouer

Écrivez la requête qui donne le **pourcentage d'utilisation CPU de la machine** :

> 100 × (1 − taux moyen d'inactivité sur 5 minutes, moyenné sur tous les cœurs)

Enregistrez-la dans le fichier `~/monitoring/requete-cpu.promql` et testez-la via l'API :

```bash
cat > ~/monitoring/requete-cpu.promql <<'EOF'
100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])))
EOF
curl -s --data-urlencode "query@$HOME/monitoring/requete-cpu.promql" localhost:9090/api/v1/query | jq '.data.result'
```{{exec}}

Le résultat doit être **une série** avec une valeur numérique (un pourcentage). Essayez aussi la version **par machine** et **par mode** :

```bash
curl -s --data-urlencode 'query=sum by (mode) (rate(node_cpu_seconds_total[5m]))' localhost:9090/api/v1/query | jq -r '.data.result[] | "\(.metric.mode)\t\(.value[1])"'
```{{exec}}

## Questions

- Pourquoi `avg(...)` sans `by` ? (On agrège **tous** les cœurs en une seule série.)
- Que se passerait-il avec `rate(...[5s])` alors que le scrape est de 15 s ? (Moins de 2 samples dans la fenêtre : **pas de résultat**. Règle : fenêtre ≥ 4 × `scrape_interval`.)

Cliquez sur **Vérifier**.
