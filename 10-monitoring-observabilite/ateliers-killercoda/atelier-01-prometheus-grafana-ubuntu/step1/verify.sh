#!/bin/bash
# Prérequis : jq
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

if [ "$(docker inspect -f '{{.State.Running}}' node-exporter 2>/dev/null)" != "true" ]; then
  echo "Le conteneur « node-exporter » n'est pas en cours d'exécution."
  exit 1
fi
if ! curl -fsS --max-time 5 http://localhost:9100/metrics 2>/dev/null | grep -q '^node_cpu_seconds_total'; then
  echo "http://localhost:9100/metrics ne contient pas node_cpu_seconds_total."
  exit 1
fi
echo "OK : node_exporter expose les métriques système sur le port 9100."
exit 0
