#!/bin/bash
# Étape 1 : top-ip.txt et nb404.txt cohérents avec access.log
d=/tmp/luc
[ -f "$d/access.log" ] || { echo "$d/access.log est absent : recréez-le avec la commande de l'énoncé."; exit 1; }
attendu_top=$(awk '{c[$1]++} END {for (i in c) print c[i], i}' "$d/access.log" | sort -nr | head -n 1)
lu_top=$(tr -s ' ' < "$d/top-ip.txt" 2>/dev/null | sed 's/^ //')
if [ "$lu_top" != "$attendu_top" ]; then
  echo "top-ip.txt devrait contenir « $attendu_top » (contenu : « $lu_top »)."
  exit 1
fi
attendu_404=$(grep -c ' 404' "$d/access.log")
lu_404=$(tr -d ' \n' < "$d/nb404.txt" 2>/dev/null)
if [ "$lu_404" != "$attendu_404" ]; then
  echo "nb404.txt devrait contenir $attendu_404 (contenu : « $lu_404 »)."
  exit 1
fi
echo "OK : analyse correcte."
exit 0
