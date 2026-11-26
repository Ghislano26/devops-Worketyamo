#!/bin/bash
# Étape 2 : le Deployment « web » a 3 réplicas disponibles
dispo=$(kubectl get deployment web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
voulus=$(kubectl get deployment web -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ -z "$voulus" ]; then
  echo "Le Deployment « web » n'existe pas (kubectl create deployment web --image=nginx:1.27 --replicas=3)."
  exit 1
fi
if [ "$voulus" != "3" ] || [ "${dispo:-0}" != "3" ]; then
  echo "Attendu : 3 réplicas disponibles. Constaté : ${dispo:-0} disponible(s) sur $voulus demandé(s)."
  exit 1
fi
echo "OK : 3 réplicas disponibles."
exit 0
