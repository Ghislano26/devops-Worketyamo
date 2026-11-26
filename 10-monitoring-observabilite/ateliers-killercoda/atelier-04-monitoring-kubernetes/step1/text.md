# Étape 1 : la pile de monitoring d'un cluster

Le chart **`kube-prometheus-stack`** déploie d'un coup : l'**opérateur Prometheus**, Prometheus, Alertmanager, Grafana (avec des dashboards Kubernetes prêts à l'emploi), **node-exporter** (un pod par nœud), **kube-state-metrics** et un ensemble de règles d'alerte.

Ajoutez le dépôt de charts, puis installez la pile dans un namespace dédié **`monitoring`** (release `kps`). On désactive les cibles du control plane qui, sur kubeadm, écoutent sur `127.0.0.1` et resteraient « down », et on limite les ressources pour ce petit nœud :

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kps prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.retention=6h \
  --set prometheus.prometheusSpec.resources.requests.memory=400Mi \
  --set kubeEtcd.enabled=false --set kubeControllerManager.enabled=false \
  --set kubeScheduler.enabled=false --set kubeProxy.enabled=false \
  --wait --timeout 10m
```{{exec}}

(L'installation prend **quelques minutes**.) Regardez ce qui a été déployé :

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get crd | grep monitoring.coreos.com
```{{exec}}

## Qui produit quelles métriques ?

| Composant | Ce qu'il expose |
|---|---|
| **node-exporter** (DaemonSet) | Ressources de **chaque nœud** (CPU, mémoire, disque, réseau) |
| **cAdvisor** (intégré au *kubelet*) | Ressources de chaque **conteneur** : `container_cpu_usage_seconds_total`… |
| **kube-state-metrics** | **État des objets** Kubernetes : `kube_pod_status_phase`, `kube_deployment_status_replicas_available`… |
| **kube-apiserver**, kubelet | Métriques propres du control plane et des nœuds |

Les cibles sont découvertes via des **`ServiceMonitor`** (voir le [cours 02](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/02-prometheus-fondamentaux.md)) :

```bash
kubectl get servicemonitors -n monitoring
kubectl get prometheusrules -n monitoring | head
```{{exec}}

## Questions

- Pourquoi des CRD (`Prometheus`, `ServiceMonitor`, `PrometheusRule`) plutôt qu'un `prometheus.yml` ? (L'opérateur génère la configuration à partir d'objets Kubernetes, gérables comme le reste.)
- Quel composant donne l'état `Running`/`CrashLoopBackOff` d'un pod ? (**kube-state-metrics**, pas cAdvisor.)

Cliquez sur **Vérifier**.
