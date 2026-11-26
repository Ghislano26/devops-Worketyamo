# Alertes avec Alertmanager

**Durée : ~25 minutes.** Compétence travaillée : écrire une règle d'alerte, la valider, la déclencher et suivre son parcours jusqu'à la notification.

Rappel du [cours Alertmanager et alertes](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/05-alertmanager-alertes.md) :

```text
Règle (expr + for) ─► Prometheus : pending ─► firing ─► Alertmanager : déduplication ─► routage ─► groupement ─► receiver
```

| Champ d'une règle | Rôle |
|---|---|
| `alert` / `expr` | Nom et condition PromQL |
| `for` | Durée pendant laquelle la condition doit rester vraie |
| `labels` | Servent au **routage** (`severity`, `team`) |
| `annotations` | Texte du message (`summary`, `description`, `runbook_url`) |

## Mise en place de l'environnement

Lancez cette pile (node_exporter, Prometheus avec `rule_files` et `alerting`, Alertmanager, et un petit récepteur *webhook* qui enregistre les notifications dans `/tmp/webhook.log`) :

```bash
mkdir -p ~/monitoring/rules && cd ~/monitoring
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
rule_files:
  - /etc/prometheus/rules/*.yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["localhost:9093"]
scrape_configs:
  - job_name: prometheus
    static_configs: [{ targets: ["localhost:9090"] }]
  - job_name: node_exporter
    static_configs: [{ targets: ["localhost:9100"] }]
EOF
cat > alertmanager.yml <<'EOF'
route:
  receiver: webhook-local
  group_by: [alertname]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 1h
receivers:
  - name: webhook-local
    webhook_configs:
      - url: http://localhost:5001/
        send_resolved: true
EOF
cat > webhook.py <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        open("/tmp/webhook.log", "a").write(self.rfile.read(n).decode() + "\n")
        self.send_response(200); self.end_headers()
    def log_message(self, *a): pass
HTTPServer(("0.0.0.0", 5001), H).serve_forever()
EOF
nohup python3 webhook.py >/dev/null 2>&1 &
docker run -d --name node-exporter --restart unless-stopped --network host --pid host -v /:/host:ro,rslave prom/node-exporter:v1.8.2 --path.rootfs=/host
docker run -d --name alertmanager --restart unless-stopped --network host -v $HOME/monitoring/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro prom/alertmanager:v0.27.0
docker run -d --name prometheus --restart unless-stopped --network host -v $HOME/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro -v $HOME/monitoring/rules:/etc/prometheus/rules:ro -v prometheus-data:/prometheus prom/prometheus:v2.54.1 --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle
until curl -fs localhost:9090/-/ready >/dev/null && curl -fs localhost:9093/-/ready >/dev/null; do sleep 2; done; echo "Pile prête"
```{{exec}}

```bash
apt-get update -qq && apt-get install -y -qq jq >/dev/null
curl -s localhost:9090/api/v1/alertmanagers | jq '.data.activeAlertmanagers'
```{{exec}}

Prometheus doit voir **un** Alertmanager actif (`localhost:9093`).
