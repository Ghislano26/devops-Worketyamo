# Étape 1 : la règle `HighCPUUsage`

Une **règle d'alerte** est une expression PromQL évaluée en continu : toute série renvoyée est une alerte potentielle, qui passe à `firing` si la condition reste vraie pendant la durée **`for`** (voir le [cours 05](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/05-alertmanager-alertes.md)).

Écrivez `~/monitoring/rules/alerts.yml` :

- alerte **`HighCPUUsage`** ;
- condition : utilisation CPU **supérieure à 80 %** (formule de l'atelier précédent, fenêtre `1m`) ;
- `for: 1m` ;
- label `severity: warning`, annotations `summary` et `description`.

```bash
cat > ~/monitoring/rules/alerts.yml <<'EOF'
groups:
  - name: infra
    rules:
      - alert: HighCPUUsage
        expr: 100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m]))) > 80
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "CPU élevé sur {{ $labels.instance }}"
          description: "Utilisation CPU à {{ $value | printf \"%.1f\" }} % depuis plus d'une minute."
EOF
```{{exec}}

**Validez la syntaxe** avec `promtool` (livré dans l'image Prometheus) **avant** de recharger :

```bash
docker run --rm --entrypoint promtool -v $HOME/monitoring/rules:/rules:ro prom/prometheus:v2.54.1 check rules /rules/alerts.yml
```{{exec}}

Rechargez Prometheus et vérifiez que la règle est **chargée** (page `/rules`, ou API) :

```bash
curl -s -X POST localhost:9090/-/reload
sleep 3
curl -s localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | {alerte: .name, etat: .state, duree: .duration, expression: .query}'
```{{exec}}

L'état doit être **`inactive`** (le CPU est calme pour l'instant).

## Questions

- Pourquoi `for: 1m` ? (Pour ignorer les pics brefs : une alerte ne doit pas sonner pour 5 secondes de CPU élevé.)
- Pourquoi `avg by (instance)` ? (Une alerte **par machine**, avec son label `instance` utilisable dans le message.)

Cliquez sur **Vérifier**.
