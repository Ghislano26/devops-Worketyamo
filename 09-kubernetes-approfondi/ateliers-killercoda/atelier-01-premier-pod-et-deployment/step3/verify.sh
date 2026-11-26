#!/bin/bash
# Étape 3 : 5 réplicas disponibles, historique >= 2 révisions, rollback effectué (image nginx:1.27)
dispo=$(kubectl get deployment web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${dispo:-0}" != "5" ]; then
  echo "Attendu : 5 réplicas disponibles. Constaté : ${dispo:-0}."
  exit 1
fi
revisions=$(kubectl rollout history deployment/web 2>/dev/null | grep -cE '^[0-9]+')
if [ "${revisions:-0}" -lt 2 ]; then
  echo "L'historique contient ${revisions:-0} révision(s) : faites d'abord la mise à jour (kubectl set image deployment/web nginx=nginx:alpine)."
  exit 1
fi
image=$(kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$image" != "nginx:1.27" ]; then
  echo "L'image actuelle est « $image » : effectuez le rollback (kubectl rollout undo deployment/web)."
  exit 1
fi
if ! kubectl rollout status deployment/web --timeout=60s >/dev/null 2>&1; then
  echo "Le rollout n'est pas terminé."
  exit 1
fi
echo "OK : scale, rollout et rollback réalisés."
exit 0
