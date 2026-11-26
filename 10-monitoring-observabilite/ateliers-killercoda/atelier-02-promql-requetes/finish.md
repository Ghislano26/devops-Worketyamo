# Bravo !

Vous avez utilisé : `rate()` sur un **counter**, `avg` / `sum by`, `topk()`, `sort_desc()`, et l'API `/api/v1/query` pour valider vos requêtes.

| Piège évité | Comment |
|---|---|
| Lire la valeur brute d'un counter | `rate(...[5m])` |
| Fenêtre trop courte | ≥ 4 × `scrape_interval` |
| Résultat non trié | `sort_desc(topk(...))` |

## Défi bonus : mémoire disponible en %

Écrivez la requête qui donne, **pour chaque machine**, le **pourcentage de mémoire disponible** :

```promql
100 * node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
```{{copy}}

1. Testez-la avec `curl --data-urlencode`.
2. Transformez-la en alerte « moins de 10 % de mémoire disponible pendant 5 minutes » (voir le [cours Alertmanager](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/05-alertmanager-alertes.md)).
3. Calculez la mémoire disponible **dans 1 heure** avec `predict_linear(node_memory_MemAvailable_bytes[30m], 3600)`.

## Pour aller plus loin

- [PromQL et métriques](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/03-promql-et-metriques.md) (pièges classiques, recording rules).
- Suite : [atelier 3 — alertes avec Alertmanager](https://github.com/Ghislano26/devops-Worketyamo/tree/main/10-monitoring-observabilite/ateliers-killercoda/atelier-03-alertes-avec-alertmanager).
