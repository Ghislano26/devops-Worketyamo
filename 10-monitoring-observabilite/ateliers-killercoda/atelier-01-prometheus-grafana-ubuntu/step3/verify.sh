#!/bin/bash
# Prérequis : jq
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

if ! curl -fsS --max-time 5 http://localhost:3000/api/health >/dev/null 2>&1; then
  echo "Grafana ne répond pas sur http://localhost:3000 (docker run … grafana/grafana:11.2.0)."
  exit 1
fi
ds=$(curl -fsS --max-time 5 -u admin:admin http://localhost:3000/api/datasources 2>/dev/null)
if [ "$(echo "$ds" | jq '[.[] | select(.type=="prometheus")] | length' 2>/dev/null)" -lt 1 ] 2>/dev/null; then
  echo "Aucune datasource de type prometheus n'est configurée dans Grafana (provisioning ?)."
  exit 1
fi
uid=$(echo "$ds" | jq -r '[.[] | select(.type=="prometheus")][0].uid')
statut=$(curl -fsS --max-time 10 -u admin:admin "http://localhost:3000/api/datasources/uid/$uid/health" 2>/dev/null | jq -r '.status // "?"')
if [ "$statut" != "OK" ]; then
  echo "La datasource Prometheus n'est pas en bonne santé (statut : $statut) : vérifiez l'URL http://localhost:9090."
  exit 1
fi
nb=$(curl -fsS --max-time 5 -u admin:admin 'http://localhost:3000/api/search?query=Node%20Exporter' 2>/dev/null | jq 'length')
if [ "${nb:-0}" -lt 1 ]; then
  echo "Le dashboard « Node Exporter Full » n'est pas importé."
  exit 1
fi
echo "OK : Grafana répond, la datasource Prometheus est saine et le dashboard est importé."
exit 0
