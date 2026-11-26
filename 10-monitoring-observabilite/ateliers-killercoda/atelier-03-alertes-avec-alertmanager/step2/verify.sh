#!/bin/bash
# Prérequis : jq
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

if ! curl -fsS --max-time 5 http://localhost:9090/-/ready >/dev/null 2>&1; then
  echo "Prometheus ne répond pas."
  exit 1
fi
etat="absente"
for _ in 1 2 3 4 5 6; do
  etat=$(curl -fsS --max-time 5 http://localhost:9090/api/v1/alerts 2>/dev/null \
    | jq -r '[.data.alerts[] | select(.labels.alertname=="HighCPUUsage")][0].state // "absente"')
  [ "$etat" = "firing" ] && break
  sleep 10
done
if [ "$etat" != "firing" ]; then
  echo "L'alerte HighCPUUsage n'est pas en firing dans Prometheus (état : $etat)."
  if ! pgrep -x stress-ng >/dev/null && ! pgrep -f 'stress-ng' >/dev/null; then
    echo "stress-ng ne tourne plus : relancez « stress-ng --cpu \$(nproc) --timeout 240s & » et patientez 1 à 2 minutes."
  else
    echo "Patientez encore un peu (scrape 15 s + évaluation + for: 1m) puis revérifiez."
  fi
  exit 1
fi
for _ in 1 2 3 4 5 6; do
  am=$(curl -fsS --max-time 5 http://localhost:9093/api/v2/alerts 2>/dev/null \
    | jq -r '[.[] | select(.labels.alertname=="HighCPUUsage")] | length')
  [ "${am:-0}" -ge 1 ] && break
  sleep 5
done
if [ "${am:-0}" -lt 1 ]; then
  echo "L'alerte est firing dans Prometheus mais Alertmanager ne l'a pas reçue (section « alerting » de prometheus.yml ? cible localhost:9093)."
  exit 1
fi
echo "OK : HighCPUUsage est firing dans Prometheus et reçue par Alertmanager."
exit 0
