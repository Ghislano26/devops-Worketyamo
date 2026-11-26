#!/bin/bash
d="$HOME/cicd-app"
if ! docker ps --filter name=^/registry$ --filter status=running -q | grep -q .; then
  echo "Le conteneur « registry » n'est pas démarré (docker run -d --name registry -p 5000:5000 registry:2)."
  exit 1
fi
curl -fs http://localhost:5000/v2/ >/dev/null || { echo "Le registry ne répond pas sur http://localhost:5000/v2/."; exit 1; }
for f in app.py test_app.py Makefile; do
  [ -s "$d/$f" ] || { echo "Le fichier $d/$f est absent ou vide."; exit 1; }
done
for cible in test build push; do
  grep -qE "^$cible:" "$d/Makefile" || { echo "Makefile : la cible « $cible » est absente."; exit 1; }
done
if ! sortie=$(make -C "$d" test 2>&1); then
  echo "« make test » échoue :"
  echo "$sortie" | tail -n 12
  exit 1
fi
echo "OK : registry opérationnel, application, tests et Makefile en place (make test passe)."
exit 0
