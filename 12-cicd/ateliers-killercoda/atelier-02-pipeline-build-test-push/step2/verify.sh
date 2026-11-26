#!/bin/bash
d="$HOME/cicd-app"
[ -s "$d/Dockerfile" ] || { echo "Le fichier $d/Dockerfile est absent ou vide."; exit 1; }
grep -qE '^FROM ' "$d/Dockerfile" || { echo "Dockerfile : l'instruction FROM est absente."; exit 1; }
grep -qE '^USER +[^ ]+' "$d/Dockerfile" || { echo "Dockerfile : ajoutez une instruction USER (utilisateur non root)."; exit 1; }
if grep -qE '^USER +(root|0)( |$)' "$d/Dockerfile"; then echo "Dockerfile : l'utilisateur ne doit pas être root."; exit 1; fi
docker image inspect localhost:5000/monapp:1.0.0 >/dev/null 2>&1 || { echo "L'image localhost:5000/monapp:1.0.0 est absente : lancez « make build »."; exit 1; }
docker image inspect localhost:5000/monapp:latest >/dev/null 2>&1 || { echo "L'image localhost:5000/monapp:latest est absente : lancez « make build »."; exit 1; }
echo "OK : image localhost:5000/monapp:1.0.0 construite (non root)."
exit 0
