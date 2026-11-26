# Bravo !

Vous avez déployé la pile de monitoring d'un cluster Kubernetes et constaté que ses métriques remontent :

| Étape | Résultat |
|---|---|
| 1 | `kube-prometheus-stack` : Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics |
| 2 | Grafana provisionné, datasource saine, métriques `kube_pod_info` présentes |

## Défi bonus : alerter sur un pod en CrashLoopBackOff

Créez une `PrometheusRule` (l'opérateur la charge automatiquement s'il porte le label `release: kps`) :

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: crashloop
  namespace: monitoring
  labels:
    release: kps
spec:
  groups:
    - name: pods
      rules:
        - alert: PodCrashLooping
          expr: kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} == 1
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: "{{ $labels.namespace }}/{{ $labels.pod }} est en CrashLoopBackOff"
EOF
```{{copy}}

1. Provoquez la panne : `kubectl run plante --image=busybox:1.36 -- sh -c "exit 1"`.
2. Interrogez `kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}` dans Prometheus (`kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090`).
3. Attendez l'alerte `firing` (page *Alerts*), puis vérifiez sa réception dans Alertmanager (`svc/kps-kube-prometheus-stack-alertmanager`, port 9093).
4. Nettoyage : `kubectl delete pod plante` ; `helm uninstall kps -n monitoring`.

## Pour aller plus loin

- [Prometheus : fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/02-prometheus-fondamentaux.md), [Alertmanager et alertes](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/05-alertmanager-alertes.md), [Traces et OpenTelemetry](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/07-traces-et-opentelemetry.md).
- Ajoutez un `ServiceMonitor` pour votre propre application et un dashboard **provisionné** par ConfigMap (`grafana_dashboard: "1"`).
- Retour au [module 10](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/README.md).
