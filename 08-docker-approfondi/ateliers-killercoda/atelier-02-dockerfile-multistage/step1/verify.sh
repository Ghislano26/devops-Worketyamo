#!/bin/bash
# Étape 1 : l'image api:naive existe
if ! docker image inspect api:naive >/dev/null 2>&1; then
  echo "L'image api:naive n'existe pas. Lancez : cd ~/api && docker build -t api:naive ."
  exit 1
fi
echo "OK : api:naive construite ($(docker image inspect -f '{{.Size}}' api:naive | awk '{printf "%.0f Mo", $1/1000000}'))."
exit 0
