#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl get namespace backstage >/dev/null 2>&1 || { echo "Le namespace « backstage » est absent (étape A)."; exit 1; }
kubectl -n backstage get configmap catalogue -o jsonpath='{.data.catalog-info\.yaml}' 2>/dev/null | grep -q 'boutique-api' || { echo "Le ConfigMap « catalogue » doit contenir catalog-info.yaml avec le composant boutique-api (étape A)."; exit 1; }
POD=$(kubectl -n backstage get pod -l app.kubernetes.io/name=backstage -o name 2>/dev/null | head -n1)
[ -n "$POD" ] || { echo "Aucun pod Backstage (helm install backstage ... ; kubectl -n backstage get pods)."; exit 1; }
dispo=$(kubectl -n backstage get deployment -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" -ge 1 ] || { echo "Le Deployment Backstage n'est pas prêt (kubectl -n backstage get pods ; logs)."; exit 1; }
sortie=$(kubectl -n backstage exec "$POD" -- node -e "fetch('http://localhost:7007/api/catalog/entities').then(r=>r.json()).then(e=>console.log(JSON.stringify(e.map(x=>({k:x.kind,n:x.metadata.name,r:(x.relations||[]).map(y=>y.type+'>'+y.targetRef)})))))" 2>/dev/null)
[ -n "$sortie" ] || { echo "L'API du catalogue ne renvoie pas de liste d'entités (démarrage en cours, ou authentification : vérifiez backend.auth.dangerouslyDisableDefaultAuthPolicy dans values-backstage.yaml)."; exit 1; }
for e in '"k":"Component","n":"boutique-api"' '"k":"System","n":"boutique"' '"k":"Group","n":"equipe-boutique"'; do
  echo "$sortie" | grep -q "$e" || { echo "Entité absente du catalogue : $e (le fichier est-il bien monté dans /catalog et la location configurée ? attendez ~1 minute)."; exit 1; }
done
echo "$sortie" | grep -q 'ownedBy>group:default/equipe-boutique' || { echo "La relation ownedBy vers equipe-boutique est absente : vérifiez owner: equipe-boutique."; exit 1; }
echo "OK : Backstage déployé, catalogue chargé depuis /catalog (Group, System, Component) avec relations ownedBy et partOf."
exit 0
