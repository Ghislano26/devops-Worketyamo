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

kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1 || { echo "Le Secret « argocd-initial-admin-secret » est introuvable (supprimé ?)."; exit 1; }
command -v argocd >/dev/null 2>&1 || { echo "La CLI « argocd » n'est pas installée (/usr/local/bin/argocd)."; exit 1; }
code=$(curl -sk -o /dev/null -m 10 -w '%{http_code}' https://localhost:8080/ 2>/dev/null)
[ "$code" = "200" ] || { echo "https://localhost:8080 ne répond pas HTTP 200 (obtenu : ${code:-aucun}). Le port-forward tourne-t-il ? (voir /tmp/port-forward.log)"; exit 1; }
timeout 30 argocd app list >/dev/null 2>&1 || { echo "« argocd app list » échoue : relancez « argocd login localhost:8080 --username admin --insecure »."; exit 1; }
echo "OK : interface joignable sur le port 8080 (HTTP 200) et CLI argocd connectée."
exit 0
