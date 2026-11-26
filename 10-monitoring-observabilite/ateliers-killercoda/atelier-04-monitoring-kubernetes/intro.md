# Monitoring Kubernetes avec kube-prometheus-stack

**Durée : ~30 minutes.** Vous allez déployer sur un cluster Kubernetes la pile standard de monitoring, et vérifier que les métriques du **cluster** remontent dans Grafana.

Rappel d'architecture ([module 09 — Architecture](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/01-architecture-et-composants.md)) : le *kubelet* de chaque nœud embarque **cAdvisor** (ressources des conteneurs) ; il faut y ajouter :

| Composant | Rôle |
|---|---|
| **node-exporter** | Métriques des **nœuds** (DaemonSet : un pod par nœud) |
| **kube-state-metrics** | **État des objets** Kubernetes (pods, Deployments, nœuds…) |
| **Prometheus Operator** | Gère Prometheus par des **CRD** (`ServiceMonitor`, `PrometheusRule`) |

```text
 kubelet/cAdvisor ─┐
 node-exporter ────┼─► Prometheus (via ServiceMonitor) ─► Grafana
 kube-state-metrics┘                                   └► Alertmanager
```

Cet atelier met en pratique les cours [Prometheus : fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/02-prometheus-fondamentaux.md) (Kubernetes SD, opérateur) et [Grafana](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/04-grafana-visualisation.md).

## Vérifions le cluster

```bash
kubectl get nodes
```{{exec}}

Le nœud doit être `Ready`. Vérifions **Helm** (le gestionnaire de paquets de Kubernetes) :

```bash
helm version --short || (curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && bash /tmp/get_helm.sh)
```{{exec}}

> Pour `jq` (utilisé dans l'atelier) : `apt-get update -qq && apt-get install -y -qq jq`.

```bash
apt-get update -qq && apt-get install -y -qq jq >/dev/null; jq --version
```{{exec}}
