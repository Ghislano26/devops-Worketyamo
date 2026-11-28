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

[ "$(appf web '{.spec.syncPolicy.automated.prune}')" = "true" ] || { echo "prune doit être réactivé (syncPolicy.automated.prune: true)."; exit 1; }
[ "$(appf web '{.spec.syncPolicy.automated.selfHeal}')" = "true" ] || { echo "selfHeal doit rester activé."; exit 1; }
dernier=$(git --git-dir=/srv/git/repo.git ls-tree -r --name-only main 2>/dev/null)
echo "$dernier" | grep -q 'apps/web/deployment.yaml' || { echo "apps/web/deployment.yaml doit rester dans le dépôt Git."; exit 1; }
if echo "$dernier" | grep -q 'apps/web/legacy.yaml'; then echo "apps/web/legacy.yaml est encore dans le dépôt Git : retirez-le (git rm), commitez et poussez."; exit 1; fi
nb=$(git --git-dir=/srv/git/repo.git rev-list --count main 2>/dev/null)
[ "${nb:-0}" -ge 2 ] || { echo "Il faut au moins 2 commits dans le dépôt (état initial + retrait de legacy) ; trouvé : ${nb:-0}."; exit 1; }
if kubectl -n demo get deployment legacy >/dev/null 2>&1; then echo "Le Deployment « legacy » existe encore dans le cluster : le prune ne s'est pas exécuté (prune actif ? rafraîchissement ? attendez ~30 s)."; exit 1; fi
dispo=$(kubectl -n demo get deployment web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" = "2" ] || { echo "Le Deployment web doit toujours avoir 2 réplicas disponibles (actuel : ${dispo:-0})."; exit 1; }
[ "$(appf web '{.status.sync.status}')" = "Synced" ] || { echo "L'application n'est pas Synced (statut : $(appf web '{.status.sync.status}'))."; exit 1; }
[ "$(appf web '{.status.health.status}')" = "Healthy" ] || { echo "L'application n'est pas Healthy."; exit 1; }
echo "OK : legacy retiré de Git puis pruné du cluster, web intact (2 réplicas), application Synced + Healthy avec prune et selfHeal."
exit 0
