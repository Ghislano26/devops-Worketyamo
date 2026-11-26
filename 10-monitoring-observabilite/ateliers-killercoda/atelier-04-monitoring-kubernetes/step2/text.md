# Étape 2 : explorer les dashboards

Exposez Grafana (service `kps-grafana`, port 80) sur le port **3000** de la machine, en arrière-plan :

```bash
kubectl port-forward -n monitoring svc/kps-grafana 3000:80 --address 0.0.0.0 >/tmp/pf-grafana.log 2>&1 &
sleep 3
curl -s localhost:3000/api/health
```{{exec}}

Ouvrez l'interface : menu Killercoda **Traffic / Ports** → port **3000** (identifiants `admin` / `admin`). Grafana est **déjà provisionné** par le chart : la datasource Prometheus et des dashboards Kubernetes existent.

```bash
curl -s -u admin:admin localhost:3000/api/datasources | jq '.[] | {name, type, uid, url}'
curl -s -u admin:admin 'localhost:3000/api/search?query=Compute%20Resources' | jq -r '.[] | .title'
```{{exec}}

Dans l'interface : *Dashboards* → **Kubernetes / Compute Resources / Cluster** : CPU et mémoire par namespace, requests/limits. Puis *Kubernetes / Compute Resources / Namespace (Pods)* avec la variable `namespace`.

## Importer un dashboard communautaire (facultatif)

Importez le dashboard **15757** (*Kubernetes / Views / Global*) : *Dashboards → New → Import → 15757 → choisir la datasource Prometheus*. Ou en ligne de commande :

```bash
cd ~ && curl -fsSL https://grafana.com/api/dashboards/15757/revisions/latest/download -o k8s-global.json
jq -n --slurpfile d k8s-global.json \
  '{dashboard: ($d[0] | .id = null), overwrite: true, folderId: 0,
    inputs: [($d[0].__inputs[]? | {name: .name, type: "datasource", pluginId: "prometheus", value: "Prometheus"})]}' \
  | curl -fsS -u admin:admin -H 'Content-Type: application/json' -X POST localhost:3000/api/dashboards/import -d @- | jq '{title, imported}'
```{{exec}}

## Interroger les métriques par Grafana

Grafana sait faire proxy vers Prometheus : vérifions que les métriques du **cluster** remontent (nombre de pods connus de kube-state-metrics) :

```bash
UID_DS=$(curl -s -u admin:admin localhost:3000/api/datasources | jq -r '[.[] | select(.type=="prometheus")][0].uid')
curl -s -u admin:admin -G "localhost:3000/api/datasources/proxy/uid/$UID_DS/api/v1/query" \
  --data-urlencode 'query=count(kube_pod_info)' | jq '.data.result'
curl -s -u admin:admin -G "localhost:3000/api/datasources/proxy/uid/$UID_DS/api/v1/query" \
  --data-urlencode 'query=sum by (namespace) (kube_pod_status_phase{phase="Running"})' | jq -r '.data.result[] | "\(.metric.namespace)\t\(.value[1])"'
```{{exec}}

## Questions

- Quel composant fournit `kube_pod_info` ? (kube-state-metrics.) Et `container_cpu_usage_seconds_total` ? (cAdvisor, dans le kubelet.)
- Pourquoi les métriques `etcd`, `kube-scheduler` n'apparaissent-elles pas ? (On a désactivé ces cibles : elles écoutent en local sur kubeadm.)

Cliquez sur **Vérifier**.
