# Bravo !

Vous avez monté une chaîne complète : **node_exporter → Prometheus → Grafana**.

| Étape | Ce que vous avez appris |
|---|---|
| 1 | Un exporter expose des métriques au format texte sur `/metrics` (types `counter`, `gauge`) |
| 2 | Prometheus **pull** ses cibles ; `up` indique la santé du scrape |
| 3 | Grafana interroge Prometheus ; datasource et dashboards peuvent être **provisionnés** |

## Défi bonus : surveiller les conteneurs avec cAdvisor

1. Lancez cAdvisor :

```bash
docker run -d --name cadvisor --restart unless-stopped -p 8081:8080 \
  -v /:/rootfs:ro -v /var/run:/var/run:ro -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro \
  gcr.io/cadvisor/cadvisor:v0.49.1
```{{copy}}

2. Ajoutez un job `cadvisor` (cible `localhost:8081`) dans `~/monitoring/prometheus.yml`, puis rechargez : `curl -X POST localhost:9090/-/reload`.
3. Vérifiez la cible UP, puis interrogez `container_memory_working_set_bytes` dans Prometheus.
4. Importez le dashboard Docker/cAdvisor (ID **14282**) dans Grafana.

## Pour aller plus loin

- [Prometheus : fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/02-prometheus-fondamentaux.md) · [PromQL](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/03-promql-et-metriques.md) · [Grafana](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/04-grafana-visualisation.md).
- Suite : [atelier 2 — requêtes PromQL](https://github.com/Ghislano26/devops-Worketyamo/tree/main/10-monitoring-observabilite/ateliers-killercoda/atelier-02-promql-requetes).
