#!/bin/bash
# Étape 2 : api:optimise plus petite que api:naive, et conteneur « api » qui répond
for img in api:naive api:optimise; do
  if ! docker image inspect "$img" >/dev/null 2>&1; then
    echo "L'image $img n'existe pas."
    exit 1
  fi
done
naive=$(docker image inspect -f '{{.Size}}' api:naive)
opt=$(docker image inspect -f '{{.Size}}' api:optimise)
if [ "$opt" -ge "$naive" ]; then
  echo "L'image optimisée ($opt octets) n'est pas plus petite que la naïve ($naive octets)."
  exit 1
fi
if [ "$(docker inspect -f '{{.State.Running}}' api 2>/dev/null)" != "true" ]; then
  echo "Le conteneur « api » ne tourne pas (docker run -d --name api -p 5000:5000 api:optimise)."
  exit 1
fi
if [ "$(docker inspect -f '{{.Config.Image}}' api 2>/dev/null)" != "api:optimise" ]; then
  echo "Le conteneur « api » doit utiliser l'image api:optimise."
  exit 1
fi
if ! curl -fsS --max-time 5 http://localhost:5000 2>/dev/null | grep -q 'statut'; then
  echo "L'API ne répond pas sur http://localhost:5000."
  exit 1
fi
echo "OK : api:optimise est plus petite et l'API répond."
exit 0
