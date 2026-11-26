#!/bin/bash
# Prérequis : jq
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

if ! curl -fsS --max-time 5 http://localhost:9090/-/ready >/dev/null 2>&1; then
  echo "Prometheus ne répond pas (la pile de l'atelier est-elle lancée ? voir l'introduction)."
  exit 1
fi
regle=$(curl -fsS --max-time 10 http://localhost:9090/api/v1/rules 2>/dev/null | jq -c '[.data.groups[].rules[] | select(.name=="HighCPUUsage")][0]')
if [ -z "$regle" ] || [ "$regle" = "null" ]; then
  echo "La règle « HighCPUUsage » n'est pas chargée dans Prometheus (fichier ~/monitoring/rules/alerts.yml puis curl -X POST localhost:9090/-/reload)."
  exit 1
fi
duree=$(echo "$regle" | jq -r '.duration')
if [ "$duree" != "60" ]; then
  echo "La règle doit avoir « for: 1m » (durée lue : ${duree}s)."
  exit 1
fi
expr=$(echo "$regle" | jq -r '.query')
echo "$expr" | grep -q 'node_cpu_seconds_total' || { echo "L'expression doit utiliser node_cpu_seconds_total."; exit 1; }
echo "$expr" | grep -q '> 80' || { echo "L'expression doit comparer l'utilisation CPU à 80 (> 80)."; exit 1; }
echo "OK : la règle HighCPUUsage est chargée (for 1m, seuil 80 %)."
exit 0
