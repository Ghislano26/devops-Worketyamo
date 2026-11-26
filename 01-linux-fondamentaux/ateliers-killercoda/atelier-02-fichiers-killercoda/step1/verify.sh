#!/bin/bash
# Étape 1 : arborescence /tmp/devops conforme
base=/tmp/devops
for d in config logs scripts; do
  if [ ! -d "$base/$d" ]; then
    echo "Le dossier $base/$d est manquant."
    exit 1
  fi
done
if ! grep -q '^port=' "$base/config/app.conf" 2>/dev/null; then
  echo "config/app.conf doit contenir une ligne port=…"
  exit 1
fi
if [ "$(wc -l < "$base/logs/app.log" 2>/dev/null)" -lt 2 ]; then
  echo "logs/app.log doit contenir au moins 2 lignes."
  exit 1
fi
if ! head -n 1 "$base/scripts/deploy.sh" 2>/dev/null | grep -q '^#!'; then
  echo "scripts/deploy.sh doit commencer par un shebang (#!)."
  exit 1
fi
echo "OK : arborescence conforme."
exit 0
