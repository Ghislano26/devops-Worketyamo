# PromQL : interroger Prometheus

**Durée : ~20 minutes.** Compétence travaillée : écrire des requêtes **PromQL** correctes, et les valider par l'**API HTTP** de Prometheus (`/api/v1/query`), comme le font les dashboards et les alertes.

Rappel du [cours PromQL](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/03-promql-et-metriques.md) :

| Type | Fonctions |
|---|---|
| **counter** (`*_total`) | `rate()`, `increase()`, `irate()` |
| **gauge** | valeur directe, `avg_over_time()`, `predict_linear()` |
| **histogram** | `histogram_quantile(φ, sum by (le) (rate(..._bucket[5m])))` |
| Agrégations | `sum`, `avg`, `max`, `topk` avec `by` / `without` |

## Mise en place de l'environnement

L'atelier a besoin d'une petite pile (node_exporter, cAdvisor, deux conteneurs de charge, Prometheus). Lancez ce script, puis **attendez environ une minute** que Prometheus accumule des données :

```bash
# Lancement de la pile de l'atelier : node_exporter, cAdvisor, une charge CPU de démonstration, Prometheus
mkdir -p ~/monitoring && cd ~/monitoring
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: prometheus
    static_configs: [{ targets: ["localhost:9090"] }]
  - job_name: node_exporter
    static_configs: [{ targets: ["localhost:9100"] }]
  - job_name: cadvisor
    static_configs: [{ targets: ["localhost:8081"] }]
EOF
docker run -d --name node-exporter --restart unless-stopped --network host --pid host -v /:/host:ro,rslave prom/node-exporter:v1.8.2 --path.rootfs=/host
docker run -d --name cadvisor --restart unless-stopped -p 8081:8080 -v /:/rootfs:ro -v /var/run:/var/run:ro -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro gcr.io/cadvisor/cadvisor:v0.49.1
docker run -d --name charge-cpu busybox sh -c 'while true; do :; done'
docker run -d --name charge-legere busybox sh -c 'while true; do sleep 0.1; done'
docker run -d --name prometheus --restart unless-stopped --network host -v $HOME/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro -v prometheus-data:/prometheus prom/prometheus:v2.54.1 --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle
until curl -fs localhost:9090/-/ready >/dev/null; do sleep 2; done; echo "Pile prête (patientez ~1 minute pour accumuler des données)"
```{{exec}}

```bash
apt-get update -qq && apt-get install -y -qq jq >/dev/null
curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job)\t\(.health)"'
```{{exec}}

Les trois cibles (`prometheus`, `node_exporter`, `cadvisor`) doivent être `up`.
