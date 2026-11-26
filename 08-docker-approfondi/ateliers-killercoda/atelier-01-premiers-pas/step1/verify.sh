#!/bin/bash
# Étape 1 : le conteneur « web » tourne et répond sur le port 8080
running=$(docker inspect -f '{{.State.Running}}' web 2>/dev/null)
if [ "$running" != "true" ]; then
  echo "Le conteneur « web » n'existe pas ou n'est pas en cours d'exécution."
  exit 1
fi
if ! docker port web 80/tcp 2>/dev/null | grep -q ':8080'; then
  echo "Le port 80 du conteneur n'est pas publié sur le port 8080 de l'hôte (option -p 8080:80)."
  exit 1
fi
if ! curl -fsS --max-time 5 http://localhost:8080 2>/dev/null | grep -qi 'nginx'; then
  echo "Le serveur ne répond pas correctement sur http://localhost:8080."
  exit 1
fi
echo "OK : nginx répond sur le port 8080."
exit 0
