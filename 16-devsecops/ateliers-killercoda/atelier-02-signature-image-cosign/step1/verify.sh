#!/bin/bash
d="$HOME/cosign-lab"
command -v cosign >/dev/null 2>&1 || { echo "cosign n'est pas installé (voir la mise en place)."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker est introuvable."; exit 1; }
docker ps --filter name='^/registry$' --filter status=running -q | grep -q . || { echo "Le conteneur « registry » ne tourne pas (docker run -d --name registry -p 5000:5000 registry:2)."; exit 1; }
for r in demo/app demo/non-signee; do
  curl -fs --max-time 5 "http://localhost:5000/v2/$r/tags/list" | grep -q '"1.0"' || { echo "L'image localhost:5000/$r:1.0 est absente du registre."; exit 1; }
done
[ -s "$d/cosign.key" ] && [ -s "$d/cosign.pub" ] || { echo "La paire de clés cosign.key / cosign.pub est absente de $d (étape B)."; exit 1; }
curl -fs --max-time 5 "http://localhost:5000/v2/demo/app/tags/list" | grep -q '\.sig' || { echo "Aucune signature (tag .sig) dans le dépôt demo/app : l'image n'a pas été signée (étape C)."; exit 1; }
cd "$d" || exit 1
cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5000/demo/app:1.0 >/dev/null 2>&1 || { echo "« cosign verify » échoue sur localhost:5000/demo/app:1.0 : signature absente ou clé différente."; exit 1; }
echo "OK : registre local actif, clés générées, demo/app:1.0 signée et vérifiable avec cosign.pub ; demo/non-signee:1.0 publiée."
exit 0
