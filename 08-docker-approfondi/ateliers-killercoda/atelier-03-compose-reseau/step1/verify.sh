#!/bin/bash
# Étape 1 : réseau atelier3_reseau-app existant, avec backend et redis dessus, DNS interne fonctionnel
if ! docker network inspect atelier3_reseau-app >/dev/null 2>&1; then
  echo "Le réseau atelier3_reseau-app n'existe pas (docker compose up -d dans ~/atelier3)."
  exit 1
fi
membres=$(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' atelier3_reseau-app)
for svc in backend redis; do
  if ! echo "$membres" | grep -q "$svc"; then
    echo "Le service $svc n'est pas connecté au réseau atelier3_reseau-app."
    exit 1
  fi
done
if ! docker compose -p atelier3 exec -T backend ping -c 1 -W 3 redis >/dev/null 2>&1; then
  echo "Le backend ne parvient pas à joindre « redis » par son nom."
  exit 1
fi
echo "OK : backend et redis communiquent sur atelier3_reseau-app."
exit 0
