#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl get namespace argocd >/dev/null 2>&1 || { echo "Le namespace « argocd » est absent : Argo CD n'est pas installé."; exit 1; }
kubectl get crd applications.argoproj.io >/dev/null 2>&1 || { echo "Le CRD « applications.argoproj.io » est absent : l'installation d'Argo CD est incomplète."; exit 1; }
appf() { kubectl -n argocd get application.argoproj.io "$1" -o jsonpath="$2" 2>/dev/null; }

nb=$(kubectl -n argocd get applicationset.argoproj.io guestbook -o jsonpath='{.spec.generators[0].list.elements[*].env}' 2>/dev/null | wc -w | tr -d ' ')
[ "$nb" -ge 4 ] || { echo "L'ApplicationSet doit contenir 4 éléments (dev, staging, prod, qa) ; trouvé : $nb."; exit 1; }
apps=$(kubectl -n argocd get applications.argoproj.io -o name 2>/dev/null | grep -c 'guestbook-')
[ "$apps" -ge 4 ] || { echo "Il faut 4 Applications guestbook-* (trouvé : $apps)."; exit 1; }
for e in dev staging prod qa; do
  app="guestbook-$e"
  appf "$app" '{.metadata.name}' | grep -q "$app" || { echo "L'Application « $app » est absente (l'ApplicationSet la recrée : patientez)."; exit 1; }
  [ "$(appf "$app" '{.status.sync.status}')" = "Synced" ] || { echo "« $app » n'est pas encore Synced."; exit 1; }
  [ "$(appf "$app" '{.status.health.status}')" = "Healthy" ] || { echo "« $app » n'est pas encore Healthy."; exit 1; }
  kubectl get namespace "guestbook-$e" >/dev/null 2>&1 || { echo "Le namespace « guestbook-$e » est absent."; exit 1; }
  dispo=$(kubectl -n "guestbook-$e" get deployment -o jsonpath='{.items[0].status.availableReplicas}' 2>/dev/null)
  [ "${dispo:-0}" -ge 1 ] || { echo "Aucun Deployment disponible dans guestbook-$e."; exit 1; }
done
echo "OK : 4 environnements générés par l'ApplicationSet (dev, staging, prod, qa), tous Synced + Healthy, 4 namespaces."
exit 0
