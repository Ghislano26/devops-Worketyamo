# Étape 3 : Grafana, datasource et dashboard « Node Exporter Full »

Grafana **interroge** Prometheus ; il ne stocke pas les métriques (voir le [cours 04](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/04-grafana-visualisation.md)). On configure la datasource **par provisioning** (en code), comme en production :

```bash
mkdir -p ~/monitoring/grafana/provisioning/datasources
cat > ~/monitoring/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
EOF
```{{exec}}

Lancez Grafana (mot de passe admin `admin` pour l'atelier) et attendez qu'il soit prêt :

```bash
docker run -d --name grafana --restart unless-stopped --network host \
  -v $HOME/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:11.2.0
until curl -fs localhost:3000/api/health >/dev/null; do sleep 2; done; echo "Grafana prêt"
```{{exec}}

Vérifiez la datasource, et sa **santé** :

```bash
curl -s -u admin:admin localhost:3000/api/datasources | jq '.[] | {name, type, url}'
curl -s -u admin:admin localhost:3000/api/datasources/uid/prometheus/health | jq
```{{exec}}

## Importer le dashboard « Node Exporter Full » (ID 1860)

Téléchargez-le depuis grafana.com et importez-le par l'API (en branchant l'entrée `DS_PROMETHEUS` sur notre datasource) :

```bash
cd ~/monitoring
apt-get install -y -qq jq >/dev/null 2>&1
curl -fsSL https://grafana.com/api/dashboards/1860/revisions/latest/download -o node-exporter-full.json
jq -n --slurpfile d node-exporter-full.json \
  '{dashboard: ($d[0] | .id = null), overwrite: true, folderId: 0,
    inputs: [($d[0].__inputs[]? | {name: .name, type: "datasource", pluginId: "prometheus", value: "Prometheus"})]}' \
  | curl -fsS -u admin:admin -H 'Content-Type: application/json' -X POST localhost:3000/api/dashboards/import -d @- | jq '{title, imported}'
```{{exec}}

Retrouvez-le :

```bash
curl -s -u admin:admin 'localhost:3000/api/search?query=Node%20Exporter' | jq '.[] | {title, url}'
```{{exec}}

> Dans l'interface (Traffic / Ports → **3000**, identifiants `admin` / `admin`) : *Dashboards → Node Exporter Full*. Observez les panels CPU, mémoire, disque, réseau : chaque panel est une **requête PromQL**. Ouvrez un panel (touche `e`) pour lire sa requête.

## Questions

- Pourquoi `access: proxy` ? (C'est Grafana, côté serveur, qui interroge Prometheus : le navigateur n'a pas besoin de l'atteindre.)
- Un dashboard communautaire est-il adapté à vos labels ? (À vérifier : il suppose des noms de métriques et de labels précis.)

Cliquez sur **Vérifier**.
