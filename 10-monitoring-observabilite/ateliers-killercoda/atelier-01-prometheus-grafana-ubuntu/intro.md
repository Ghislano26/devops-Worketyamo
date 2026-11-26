# Prometheus et Grafana : votre première pile de monitoring

**Durée : ~25 minutes.** Vous allez monter, sur une machine Ubuntu, la pile de monitoring la plus répandue :

```text
node_exporter (9100)  ──scrape──►  Prometheus (9090)  ──PromQL──►  Grafana (3000)
 métriques de la machine            stockage TSDB                    dashboards
```

**Objectifs**

1. exposer les métriques système avec **node_exporter** ;
2. les collecter avec **Prometheus** et vérifier la cible `UP` ;
3. les visualiser dans **Grafana** (datasource par *provisioning* + dashboard *Node Exporter Full*).

**Prérequis** : aucun (l'environnement est fourni). Cet atelier met en pratique les cours [Prometheus : fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/02-prometheus-fondamentaux.md) et [Grafana](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/04-grafana-visualisation.md). Docker est préinstallé ; tout tourne en conteneurs.

## Vérifions l'environnement

```bash
docker --version
```{{exec}}

```bash
apt-get update -qq && apt-get install -y -qq jq >/dev/null && jq --version
docker info | grep -E "Server Version|Cgroup Version"
```{{exec}}

Les images (`prom/node-exporter`, `prom/prometheus`, `grafana/grafana`) sont téléchargées au premier lancement : cela peut prendre une minute.
