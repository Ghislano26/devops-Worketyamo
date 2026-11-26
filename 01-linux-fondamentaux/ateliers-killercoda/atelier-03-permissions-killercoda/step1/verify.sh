#!/bin/bash
# Étape 1 : /tmp/perm/script.sh en 750, propriétaire nobody:nogroup, exécutable
f=/tmp/perm/script.sh
[ -f "$f" ] || { echo "Le fichier $f n'existe pas."; exit 1; }
infos=$(stat -c '%a %U %G' "$f")
if [ "$infos" != "750 nobody nogroup" ]; then
  echo "Attendu : « 750 nobody nogroup ». Constaté : « $infos »."
  exit 1
fi
if [ "$("$f" 2>/dev/null)" != "ok" ]; then
  echo "Le script doit s'exécuter et afficher « ok »."
  exit 1
fi
echo "OK : permissions et propriétaire corrects."
exit 0
