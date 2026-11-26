#!/bin/bash
# Prérequis : jq
command -v jq >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq jq >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { echo "jq est introuvable et n'a pas pu être installé."; exit 1; }

requete() {   # requete <fichier> → JSON de l'API Prometheus (instantané)
  curl -fsS --max-time 10 --data-urlencode "query@$1" http://localhost:9090/api/v1/query 2>/dev/null
}

f="$HOME/monitoring/requete-top3.promql"
[ -s "$f" ] || { echo "Le fichier $f est absent ou vide."; exit 1; }
grep -q 'topk' "$f" || { echo "La requête doit utiliser topk()."; exit 1; }
grep -q 'sort_desc' "$f" || { echo "La requête doit utiliser sort_desc() pour garantir l'ordre."; exit 1; }
rep=$(requete "$f")
if [ "$(echo "$rep" | jq -r '.status' 2>/dev/null)" != "success" ]; then
  echo "La requête est invalide : $(echo "$rep" | jq -r '.error // "erreur de syntaxe"' 2>/dev/null)"
  exit 1
fi
nb=$(echo "$rep" | jq '.data.result | length')
if [ "${nb:-0}" -lt 1 ] || [ "${nb:-0}" -gt 3 ]; then
  echo "La requête doit renvoyer entre 1 et 3 séries (obtenu : ${nb:-0}). Les cibles cadvisor/node_exporter sont-elles UP ?"
  exit 1
fi
trie=$(echo "$rep" | jq '[.data.result[].value[1] | tonumber] as $v | ($v == ($v | sort | reverse))')
if [ "$trie" != "true" ]; then
  echo "Les résultats ne sont pas triés par ordre décroissant."
  exit 1
fi
premier=$(echo "$rep" | jq -r '.data.result[0].metric | (.name // .mode // "?")')
echo "OK : $nb série(s) triée(s) ; premier = $premier."
exit 0
