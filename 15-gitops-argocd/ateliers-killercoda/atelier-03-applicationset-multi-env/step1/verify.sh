#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl get namespace argocd >/dev/null 2>&1 || { echo "Le namespace « argocd » est absent : Argo CD n'est pas installé."; exit 1; }
kubectl get crd applications.argoproj.io >/dev/null 2>&1 || { echo "Le CRD « applications.argoproj.io » est absent : l'installation d'Argo CD est incomplète."; exit 1; }
appf() { kubectl -n argocd get application.argoproj.io "$1" -o jsonpath="$2" 2>/dev/null; }

kubectl -n argocd get applicationset.argoproj.io guestbook >/dev/null 2>&1 || { echo "L'ApplicationSet « guestbook » est absent (kubectl apply -f applicationset.yaml)."; exit 1; }
nb=$(kubectl -n argocd get applicationset.argoproj.io guestbook -o jsonpath='{.spec.generators[0].list.elements[*].env}' 2>/dev/null | wc -w | tr -d ' ')
[ "$nb" -ge 3 ] || { echo "Le générateur List doit contenir au moins dev, staging et prod (trouvé : $nb éléments)."; exit 1; }
for e in dev staging prod; do
  app="guestbook-$e"
  appf "$app" '{.metadata.name}' | grep -q "$app" || { echo "L'Application « $app » n'a pas été générée (kubectl -n argocd get applications)."; exit 1; }
  [ "$(appf "$app" '{.metadata.ownerReferences[0].kind}')" = "ApplicationSet" ] || { echo "« $app » n'appartient pas à l'ApplicationSet (elle a été créée à la main ?)."; exit 1; }
  [ "$(appf "$app" '{.status.sync.status}')" = "Synced" ] || { echo "« $app » n'est pas Synced (statut : $(appf "$app" '{.status.sync.status}')). Patientez."; exit 1; }
  [ "$(appf "$app" '{.status.health.status}')" = "Healthy" ] || { echo "« $app » n'est pas Healthy (statut : $(appf "$app" '{.status.health.status}')). Patientez."; exit 1; }
  kubectl get namespace "guestbook-$e" >/dev/null 2>&1 || { echo "Le namespace « guestbook-$e » est absent."; exit 1; }
  voulu=$(appf "$app" '{.spec.source.helm.parameters[?(@.name=="replicaCount")].value}')
  reel=$(kubectl -n "guestbook-$e" get deployment -o jsonpath='{.items[0].spec.replicas}' 2>/dev/null)
  [ -n "$voulu" ] && [ "$reel" = "$voulu" ] || { echo "Dans guestbook-$e, le Deployment a ${reel:-aucun} réplicas au lieu de ${voulu:-?} (paramètre de l'Application)."; exit 1; }
done
echo "OK : ApplicationSet List, 3 Applications générées (dev, staging, prod) Synced + Healthy, 3 namespaces, réplicas conformes."
exit 0
