# Bravo !

Vous avez suivi une alerte de bout en bout : **règle** → `pending` → `firing` → **Alertmanager** → **webhook**.

| Ce que vous avez vu | Où |
|---|---|
| Validation avant déploiement | `promtool check rules` |
| `for` évite les pics brefs | état `pending` |
| Déduplication, groupement, routage | Alertmanager (`group_wait`, `route`, `receivers`) |

## Défi bonus : poser un silence

Pendant une maintenance, on **silence** une alerte sans la supprimer.

1. Relancez la charge : `stress-ng --cpu $(nproc) --timeout 240s &`, et attendez `firing`.
2. Créez un silence de 30 minutes sur `alertname="HighCPUUsage"` avec `amtool` (fourni dans l'image) :

```bash
docker run --rm --network host --entrypoint amtool prom/alertmanager:v0.27.0 \
  --alertmanager.url=http://localhost:9093 silence add alertname=HighCPUUsage \
  --duration=30m --author="vous" --comment="maintenance planifiée"
```{{copy}}

3. Constatez dans `curl -s localhost:9093/api/v2/alerts | jq '.[].status'` que l'état devient `suppressed`, et qu'aucune nouvelle notification n'arrive dans `/tmp/webhook.log`.
4. Listez puis expirez le silence : `amtool silence query` puis `amtool silence expire <id>`.

## Pour aller plus loin

- [Alertmanager et alertes](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/05-alertmanager-alertes.md) : inhibition, sévérités, *alert fatigue*, burn rate.
- Ajoutez une route `severity="critical"` avec un `group_wait` plus court, et testez avec `amtool config routes test`.
- Suite : [atelier 4 — monitoring Kubernetes](https://github.com/Ghislano26/devops-Worketyamo/tree/main/10-monitoring-observabilite/ateliers-killercoda/atelier-04-monitoring-kubernetes).
