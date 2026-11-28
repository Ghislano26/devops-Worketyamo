# Rightsizing des requests avec OpenCost

**Durée : ~40 minutes** (dont 15 minutes d'attente de collecte). Compétence travaillée : déployer une charge **volontairement surdimensionnée**, **mesurer le gaspillage** dans OpenCost, **réduire les requests**, puis **comparer** coût et efficience avant / après.

Rappel du [cours Rightsizing et optimisation](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/04-rightsizing-et-optimisation.md) :

```text
requests = capacité RÉSERVÉE et FACTURÉE (règle max(demandé, utilisé))
Pod qui demande 250 m CPU et en utilise ~1 m  →  efficience ≈ 0 %  →  on paie 250 fois ce qui sert
Rightsizing : ramener les requests près de l'usage réel + une marge
```

Cet atelier est **indépendant** de l'atelier 1 : il installe lui-même Prometheus et OpenCost (**4 à 8 minutes**).

> 🌐 **Réseau et durée** : le scénario installe **Prometheus** (chart `prometheus-community/prometheus`, avec kube-state-metrics et node-exporter) puis **OpenCost** (chart `opencost/opencost`) avec **Helm**. Comptez **4 à 8 minutes** (images, démarrage), puis **quelques minutes de collecte** avant d'avoir des chiffres. Les versions des charts **ne sont pas épinglées** (relevez-les avec `helm list -A`).

> 💲 **Prix fictifs.** Il n'y a **pas de facture cloud** ici : OpenCost utilise des **tarifs personnalisés fictifs** (`CPU 0,03 $/cœur·h`, `RAM 0,004 $/Go·h`). Les montants sont **proportionnels et comparables**, mais **ne correspondent à aucune facture réelle** ([cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/03-kubecost-opencost.md)).

## Mise en place

```bash
mkdir -p ~/finops-lab && cd ~/finops-lab
command -v helm >/dev/null 2>&1 || {
  curl -fsSL -o /tmp/get-helm-3.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 /tmp/get-helm-3.sh && /tmp/get-helm-3.sh --version v3.16.3
}
helm version --short
cat > prometheus-values.yaml <<'EOF'
alertmanager:
  enabled: false
prometheus-pushgateway:
  enabled: false
server:
  persistentVolume:
    enabled: false
  global:
    scrape_interval: 1m
    scrape_timeout: 10s
    evaluation_interval: 1m
extraScrapeConfigs: |
  - job_name: opencost
    honor_labels: true
    scrape_interval: 1m
    scrape_timeout: 10s
    metrics_path: /metrics
    scheme: http
    dns_sd_configs:
      - names:
          - opencost.opencost
        type: A
        port: 9003
EOF
cat > opencost-values.yaml <<'EOF'
opencost:
  exporter:
    defaultClusterId: killercoda
  prometheus:
    internal:
      enabled: true
      serviceName: prometheus-server
      namespaceName: prometheus-system
      port: 80
  ui:
    enabled: true
  customPricing:
    enabled: true
    provider: custom
    costModel:
      description: Prix fictifs de l'atelier (pas une facture)
      CPU: "0.03"
      spotCPU: "0.01"
      RAM: "0.004"
      spotRAM: "0.001"
      GPU: "0.95"
      storage: "0.00005"
      zoneNetworkEgress: "0.01"
      regionNetworkEgress: "0.01"
      internetNetworkEgress: "0.12"
EOF
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update
helm install prometheus prometheus-community/prometheus --namespace prometheus-system --create-namespace -f prometheus-values.yaml --wait --timeout 8m
helm install opencost opencost/opencost --namespace opencost --create-namespace -f opencost-values.yaml --wait --timeout 8m
kubectl get pods -n prometheus-system
kubectl get pods -n opencost
cd ~/finops-lab
cat > couts.py <<'EOF'
#!/usr/bin/env python3
"""Affiche coût et efficience par agrégat (namespace par défaut) depuis l'API OpenCost.
Usage : couts.py [fenetre] [agregat]      ex. couts.py 30m namespace"""
import json, subprocess, sys

fenetre = sys.argv[1] if len(sys.argv) > 1 else "30m"
agregat = sys.argv[2] if len(sys.argv) > 2 else "namespace"
chemin = ("/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute"
          f"?window={fenetre}&aggregate={agregat}&accumulate=true")
res = subprocess.run(["kubectl", "get", "--raw", chemin], capture_output=True, text=True)
if res.returncode:
    sys.exit("Erreur d'appel à OpenCost : " + res.stderr.strip())
data = json.loads(res.stdout).get("data") or []
if not data or not data[0]:
    sys.exit("Aucune donnée pour cette fenêtre : attendez que Prometheus collecte (quelques minutes).")
lignes = sorted(data[0].items(), key=lambda kv: kv[1].get("totalCost", 0), reverse=True)
print(f"{'nom':34} {'coût $':>9} {'cpu dem.':>9} {'cpu util.':>9} {'eff.cpu':>8} {'eff.ram':>8}")
for nom, a in lignes:
    print(f"{nom:34} {a.get('totalCost', 0):9.4f} {a.get('cpuCoreRequestAverage', 0):9.3f} "
          f"{a.get('cpuCoreUsageAverage', 0):9.4f} {a.get('cpuEfficiency', 0) * 100:7.1f}% "
          f"{a.get('ramEfficiency', 0) * 100:7.1f}%")
EOF
chmod +x couts.py
```{{exec}}

Vérifiez que tout est prêt avant de continuer :

```bash
kubectl -n prometheus-system get pods
kubectl -n opencost get pods
```{{exec}}
