#!/bin/bash
# Prérequis : jq
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

if [ "$(docker inspect -f '{{.State.Running}}' prometheus 2>/dev/null)" != "true" ]; then
  echo "Le conteneur « prometheus » n'est pas en cours d'exécution."
  exit 1
fi
if ! curl -fsS --max-time 5 http://localhost:9090/-/ready >/dev/null 2>&1; then
  echo "Prometheus ne répond pas encore sur http://localhost:9090 (patientez quelques secondes)."
  exit 1
fi
for _ in 1 2 3 4 5 6; do
  etat=$(curl -fsS --max-time 5 http://localhost:9090/api/v1/targets 2>/dev/null \
    | jq -r '[.data.activeTargets[] | select(.labels.job=="node_exporter")][0].health // "absente"')
  [ "$etat" = "up" ] && break
  sleep 5
done
if [ "$etat" != "up" ]; then
  echo "La cible du job « node_exporter » n'est pas UP (état : $etat). Vérifiez prometheus.yml et le conteneur node-exporter."
  exit 1
fi
echo "OK : Prometheus collecte node_exporter (cible UP)."
exit 0
