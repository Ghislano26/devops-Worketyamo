#!/bin/bash
# Prérequis : jq, kubectl
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

kubectl -n monitoring port-forward svc/kps-grafana 13000:80 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null' EXIT
for _ in 1 2 3 4 5 6 7 8; do
  curl -fsS --max-time 3 http://localhost:13000/api/health >/dev/null 2>&1 && break
  sleep 2
done
if ! curl -fsS --max-time 5 http://localhost:13000/api/health >/dev/null 2>&1; then
  echo "Grafana ne répond pas (service kps-grafana du namespace monitoring) : la pile est-elle installée et Ready ?"
  exit 1
fi
ds=$(curl -fsS --max-time 5 -u admin:admin http://localhost:13000/api/datasources 2>/dev/null)
uid=$(echo "$ds" | jq -r '[.[] | select(.type=="prometheus")][0].uid // empty')
if [ -z "$uid" ]; then
  echo "Aucune datasource Prometheus dans Grafana (identifiants admin/admin ? release nommée kps ?)."
  exit 1
fi
statut=$(curl -fsS --max-time 10 -u admin:admin "http://localhost:13000/api/datasources/uid/$uid/health" 2>/dev/null | jq -r '.status // "?"')
if [ "$statut" != "OK" ]; then
  echo "La datasource Prometheus n'est pas saine (statut : $statut)."
  exit 1
fi
nb=$(curl -fsS --max-time 15 -u admin:admin -G "http://localhost:13000/api/datasources/proxy/uid/$uid/api/v1/query" \
  --data-urlencode 'query=count(kube_pod_info)' 2>/dev/null | jq -r '.data.result[0].value[1] // "0"')
if [ "${nb%.*}" -lt 1 ] 2>/dev/null; then
  echo "Les métriques de kube-state-metrics (kube_pod_info) ne remontent pas encore : patientez 1 à 2 minutes."
  exit 1
fi
echo "OK : Grafana répond, la datasource est saine et le cluster remonte $nb pods dans Prometheus."
exit 0
