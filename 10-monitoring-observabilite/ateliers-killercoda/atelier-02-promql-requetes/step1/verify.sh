#!/bin/bash
# Prérequis : jq
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

requete() {   # requete <fichier> → JSON de l'API Prometheus (instantané)
  curl -fsS --max-time 10 --data-urlencode "query@$1" http://localhost:9090/api/v1/query 2>/dev/null
}

f="$HOME/monitoring/requete-cpu.promql"
if [ ! -s "$f" ]; then
  echo "Le fichier $f est absent ou vide."
  exit 1
fi
if ! grep -q 'rate(' "$f" || ! grep -q 'node_cpu_seconds_total' "$f"; then
  echo "La requête doit utiliser rate() sur node_cpu_seconds_total."
  exit 1
fi
rep=$(requete "$f")
if [ "$(echo "$rep" | jq -r '.status' 2>/dev/null)" != "success" ]; then
  echo "La requête est invalide pour Prometheus : $(echo "$rep" | jq -r '.error // "erreur de syntaxe"' 2>/dev/null)"
  exit 1
fi
nb=$(echo "$rep" | jq '.data.result | length')
if [ "${nb:-0}" -lt 1 ]; then
  echo "La requête ne renvoie aucune série (attendez ~1 minute que Prometheus ait collecté assez de données)."
  exit 1
fi
val=$(echo "$rep" | jq -r '.data.result[0].value[1]')
if ! awk -v v="$val" 'BEGIN { exit !(v+0 >= 0 && v+0 <= 100) }'; then
  echo "Le résultat ($val) n'est pas un pourcentage entre 0 et 100 : vérifiez la formule 100 * (1 - avg(rate(...idle...)))."
  exit 1
fi
echo "OK : la requête renvoie $nb série(s), valeur = $val %."
exit 0
