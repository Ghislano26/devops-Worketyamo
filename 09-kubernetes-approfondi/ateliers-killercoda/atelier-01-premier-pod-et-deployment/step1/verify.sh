#!/bin/bash
# Étape 1 : le pod « nginx » est en phase Running
phase=$(kubectl get pod nginx -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" != "Running" ]; then
  echo "Le pod « nginx » n'est pas Running (phase actuelle : ${phase:-inexistant}). Lancez : kubectl run nginx --image=nginx:1.27"
  exit 1
fi
echo "OK : le pod nginx est Running."
exit 0
