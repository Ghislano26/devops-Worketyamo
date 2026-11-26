#!/bin/bash
# Prérequis : jq, kubectl
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

if ! command -v kubectl >/dev/null 2>&1; then echo "kubectl est introuvable."; exit 1; fi
verifie() {   # verifie <libellé> <sélecteur de label>
  local lib="$1" sel="$2" total pas_prets
  total=$(kubectl get pods -n monitoring -l "$sel" --no-headers 2>/dev/null | wc -l)
  if [ "$total" -lt 1 ]; then
    echo "Aucun pod « $lib » dans le namespace monitoring (helm install kps … --namespace monitoring)."
    exit 1
  fi
  pas_prets=$(kubectl get pods -n monitoring -l "$sel" -o json 2>/dev/null \
    | jq '[.items[] | select(.status.phase != "Running" or ([.status.containerStatuses[]?.ready] | all | not))] | length')
  if [ "${pas_prets:-1}" -ne 0 ]; then
    echo "Des pods « $lib » ne sont pas encore Running/Ready : kubectl get pods -n monitoring (patientez)."
    exit 1
  fi
}
verifie "Prometheus" "app.kubernetes.io/name=prometheus"
verifie "Grafana" "app.kubernetes.io/name=grafana"
verifie "Alertmanager" "app.kubernetes.io/name=alertmanager"
verifie "node-exporter" "app.kubernetes.io/name=prometheus-node-exporter"
verifie "kube-state-metrics" "app.kubernetes.io/name=kube-state-metrics"
echo "OK : Prometheus, Grafana, Alertmanager, node-exporter et kube-state-metrics sont Running."
exit 0
