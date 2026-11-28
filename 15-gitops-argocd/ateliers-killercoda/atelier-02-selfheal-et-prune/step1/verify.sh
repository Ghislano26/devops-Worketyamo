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

appf web '{.metadata.name}' | grep -q web || { echo "L'Application « web » est absente (kubectl apply -f ~/app-web.yaml)."; exit 1; }
[ "$(appf web '{.spec.syncPolicy.automated.prune}')" = "true" ] || { echo "syncPolicy.automated.prune doit valoir true."; exit 1; }
[ "$(appf web '{.spec.syncPolicy.automated.selfHeal}')" = "true" ] || { echo "syncPolicy.automated.selfHeal doit valoir true."; exit 1; }
[ "$(appf web '{.status.sync.status}')" = "Synced" ] || { echo "L'application n'est pas Synced (statut : $(appf web '{.status.sync.status}')). Attendez, ou consultez : kubectl -n argocd get application web -o yaml"; exit 1; }
[ "$(appf web '{.status.health.status}')" = "Healthy" ] || { echo "L'application n'est pas Healthy (statut : $(appf web '{.status.health.status}'))."; exit 1; }
spec=$(kubectl -n demo get deployment web -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$spec" = "2" ] || { echo "Le Deployment web doit avoir 2 réplicas demandés (actuel : ${spec:-absent}). Le self-heal n'a pas encore corrigé le scale à 5 : patientez quelques secondes."; exit 1; }
dispo=$(kubectl -n demo get deployment web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" = "2" ] || { echo "Le Deployment web doit avoir 2 réplicas disponibles (actuel : ${dispo:-0})."; exit 1; }
kubectl -n demo get deployment legacy >/dev/null 2>&1 || { echo "Le Deployment « legacy » devrait exister à ce stade (il est supprimé à l'étape 2)."; exit 1; }
echo "OK : Application web automatisée (prune + selfHeal), Synced + Healthy, web revenu à 2 réplicas."
exit 0
