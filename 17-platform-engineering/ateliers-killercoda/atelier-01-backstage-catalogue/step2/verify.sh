#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl -n backstage get configmap catalogue -o jsonpath='{.data.catalog-info\.yaml}' 2>/dev/null | grep -q 'boutique-web' || { echo "Le ConfigMap « catalogue » ne contient pas encore boutique-web (mettez-le à jour avec kubectl apply)."; exit 1; }
POD=$(kubectl -n backstage get pod -l app.kubernetes.io/name=backstage -o name 2>/dev/null | head -n1)
[ -n "$POD" ] || { echo "Aucun pod Backstage."; exit 1; }
dispo=$(kubectl -n backstage get deployment -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" -ge 1 ] || { echo "Backstage n'est pas prêt (redémarrage en cours ? kubectl -n backstage rollout status deployment -l app.kubernetes.io/name=backstage)."; exit 1; }
sortie=$(kubectl -n backstage exec "$POD" -- node -e "fetch('http://localhost:7007/api/catalog/entities').then(r=>r.json()).then(e=>console.log(JSON.stringify(e.map(x=>({k:x.kind,n:x.metadata.name,r:(x.relations||[]).map(y=>y.type+'>'+y.targetRef)})))))" 2>/dev/null)
[ -n "$sortie" ] || { echo "L'API du catalogue ne répond pas encore : patientez 1 minute après le redémarrage."; exit 1; }
for e in '"k":"Component","n":"boutique-api"' '"k":"Component","n":"boutique-web"'; do
  echo "$sortie" | grep -q "$e" || { echo "Entité absente du catalogue : $e (redémarrage effectué ? attendez quelques dizaines de secondes)."; exit 1; }
done
echo "$sortie" | grep -q 'dependsOn>component:default/boutique-api' || { echo "La relation dependsOn de boutique-web vers boutique-api est absente : vérifiez dependsOn: [component:boutique-api]."; exit 1; }
echo "$sortie" | grep -q 'dependencyOf>component:default/boutique-web' || { echo "La relation inverse dependencyOf sur boutique-api est absente (le catalogue n'a pas fini de la calculer : patientez)."; exit 1; }
echo "OK : 2 composants dans le catalogue ; boutique-web dependsOn boutique-api (relation inverse dependencyOf calculée)."
exit 0
