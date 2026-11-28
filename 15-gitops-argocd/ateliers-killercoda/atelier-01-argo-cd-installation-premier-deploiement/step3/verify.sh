#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl get namespace argocd >/dev/null 2>&1 || { echo "Le namespace « argocd » est absent : Argo CD n'est pas installé."; exit 1; }
kubectl get crd applications.argoproj.io >/dev/null 2>&1 || { echo "Le CRD « applications.argoproj.io » est absent : l'installation d'Argo CD est incomplète."; exit 1; }
appf() { kubectl -n argocd get application.argoproj.io "$1" -o jsonpath="$2" 2>/dev/null; }

for d in argocd-server argocd-repo-server argocd-applicationset-controller; do
  dispo=$(kubectl -n argocd get deployment "$d" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "${dispo:-0}" -ge 1 ] || { echo "Le Deployment « $d » n'est pas prêt (kubectl -n argocd get pods)."; exit 1; }
done
ctl=$(kubectl -n argocd get statefulset argocd-application-controller -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${ctl:-0}" -ge 1 ] || { echo "Le StatefulSet « argocd-application-controller » n'est pas prêt."; exit 1; }

appf guestbook '{.metadata.name}' | grep -q guestbook || { echo "L'Application « guestbook » est absente du namespace argocd (kubectl apply -f guestbook-app.yaml)."; exit 1; }
repo=$(appf guestbook '{.spec.source.repoURL}')
echo "$repo" | grep -q 'argocd-example-apps' || { echo "La source de l'application doit être le dépôt argocd-example-apps (trouvé : $repo)."; exit 1; }
ns=$(appf guestbook '{.spec.destination.namespace}')
[ "$ns" = "guestbook" ] || { echo "Le namespace de destination doit être « guestbook » (trouvé : $ns)."; exit 1; }
sync=$(appf guestbook '{.status.sync.status}')
[ "$sync" = "Synced" ] || { echo "Le statut de synchronisation est « ${sync:-inconnu} » au lieu de Synced : lancez « argocd app sync guestbook »."; exit 1; }
health=$(appf guestbook '{.status.health.status}')
[ "$health" = "Healthy" ] || { echo "Le statut de santé est « ${health:-inconnu} » au lieu de Healthy : attendez ou consultez « argocd app get guestbook »."; exit 1; }
dispo=$(kubectl -n guestbook get deployment guestbook-ui -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" -ge 1 ] || { echo "Le Deployment « guestbook-ui » n'a aucun réplica disponible dans le namespace guestbook."; exit 1; }
kubectl -n guestbook get service guestbook-ui >/dev/null 2>&1 || { echo "Le Service « guestbook-ui » est absent."; exit 1; }
echo "OK : Application guestbook Synced + Healthy, Deployment guestbook-ui disponible dans le namespace guestbook."
exit 0
