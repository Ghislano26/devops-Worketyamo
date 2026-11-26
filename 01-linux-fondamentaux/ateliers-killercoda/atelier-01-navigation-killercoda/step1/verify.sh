#!/bin/bash
# Étape 1 : /tmp/chemin-dpkg.txt contient exactement le chemin trouvé par find
f=/tmp/chemin-dpkg.txt
if [ ! -f "$f" ]; then
  echo "Le fichier $f n'existe pas : redirigez la sortie de find vers ce fichier."
  exit 1
fi
if [ "$(wc -l < "$f")" -ne 1 ] || [ "$(cat "$f")" != "/var/log/dpkg.log" ]; then
  echo "Le fichier doit contenir une seule ligne : /var/log/dpkg.log (contenu actuel : $(head -n 1 "$f"))."
  exit 1
fi
echo "OK : chemin correct."
exit 0
