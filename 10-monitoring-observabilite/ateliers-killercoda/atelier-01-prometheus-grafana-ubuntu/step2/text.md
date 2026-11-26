# Étape 2 : un serveur Prometheus

Prometheus **interroge** (pull) ses cibles à intervalle régulier. Décrivez-les dans `prometheus.yml` :

```bash
mkdir -p ~/monitoring && cd ~/monitoring
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: node_exporter
    static_configs:
      - targets: ["localhost:9100"]
EOF
```{{exec}}

Lancez Prometheus (réseau de l'hôte, volume pour la base TSDB, rechargement à chaud activé) :

```bash
docker run -d --name prometheus --restart unless-stopped --network host \
  -v $HOME/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  -v prometheus-data:/prometheus \
  prom/prometheus:v2.54.1 \
  --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle
```{{exec}}

Attendez qu'il soit prêt, puis regardez l'état des **cibles** (la page `/targets` de l'interface, ou l'API) :

```bash
until curl -fs localhost:9090/-/ready >/dev/null; do sleep 2; done; echo "Prometheus prêt"
sleep 20
curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job)\t\(.health)\t\(.scrapeUrl)"'
```{{exec}}

Chaque cible doit être **`up`**. Interrogez la série automatique `up` (1 = scrape réussi) :

```bash
curl -s 'localhost:9090/api/v1/query?query=up' | jq '.data.result[] | {job: .metric.job, up: .value[1]}'
```{{exec}}

> Sur Killercoda, l'interface web est accessible par le menu **Traffic / Ports** → port **9090** : essayez `Status → Targets`.

## Questions

- Que signifie `up == 0` pour une cible ? (Le dernier scrape a échoué : cible arrêtée, port, réseau.)
- Pourquoi `--web.enable-lifecycle` ? (Pour recharger la configuration par `POST /-/reload` sans redémarrer.)

Cliquez sur **Vérifier**.
