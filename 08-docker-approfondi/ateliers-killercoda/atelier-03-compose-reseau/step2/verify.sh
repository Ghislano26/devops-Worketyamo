#!/bin/bash
# Étape 2 : le backend répond sur le port 8000 de l'hôte et « docker compose exec » fonctionne
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost:8000 2>/dev/null)
if [ "$code" != "200" ]; then
  echo "Le backend ne répond pas en HTTP 200 sur localhost:8000 (code reçu : ${code:-aucun})."
  exit 1
fi
if ! docker compose -p atelier3 exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
  echo "« docker compose exec redis redis-cli ping » ne répond pas PONG."
  exit 1
fi
echo "OK : port publié, exec fonctionnel."
exit 0
