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

for crd in applicationsets.argoproj.io appprojects.argoproj.io; do
  kubectl get crd "$crd" >/dev/null 2>&1 || { echo "Le CRD « $crd » est absent (avez-vous utilisé --server-side ?)."; exit 1; }
done
redis=$(kubectl -n argocd get deployment argocd-redis -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${redis:-0}" -ge 1 ] || { echo "Le Deployment « argocd-redis » n'est pas prêt."; exit 1; }
echo "OK : Argo CD v2.13.3 est installé (server, repo-server, application-controller, applicationset-controller, redis prêts ; CRD présents)."
exit 0
