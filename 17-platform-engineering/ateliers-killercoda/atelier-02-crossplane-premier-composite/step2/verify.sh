#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
etab=$(kubectl get xrd xwebapps.platform.worketyamo.org -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)
[ "$etab" = "True" ] || { echo "Le XRD xwebapps.platform.worketyamo.org n'est pas Established (partie A)."; exit 1; }
mode=$(kubectl get composition webapp-kubernetes -o jsonpath='{.spec.mode}' 2>/dev/null)
[ "$mode" = "Pipeline" ] || { echo "La Composition « webapp-kubernetes » est absente ou n'est pas en mode Pipeline (trouvé : ${mode:-absente})."; exit 1; }
kubectl get xwebapp boutique >/dev/null 2>&1 || { echo "La ressource composite XWebApp « boutique » est absente (partie B)."; exit 1; }
for c in Ready Synced; do
  s=$(kubectl get xwebapp boutique -o jsonpath="{.status.conditions[?(@.type==\"$c\")].status}" 2>/dev/null)
  [ "$s" = "True" ] || { echo "La condition $c de la XR n'est pas True (statut : ${s:-inconnu}) : kubectl describe xwebapp boutique."; exit 1; }
done
refs=$(kubectl get xwebapp boutique -o jsonpath='{.spec.resourceRefs[*].name}' 2>/dev/null | wc -w | tr -d ' ')
[ "$refs" -ge 2 ] || { echo "La XR doit référencer 2 ressources composées (Deployment et Service) ; trouvé : $refs."; exit 1; }
voulu=$(kubectl get xwebapp boutique -o jsonpath='{.spec.parameters.replicas}')
[ "$voulu" = "3" ] || { echo "La XR doit demander replicas: 3 (partie C) ; actuel : $voulu."; exit 1; }
reel=$(kubectl -n apps-plateforme get deployment boutique -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$reel" = "3" ] || { echo "Le Deployment réel « boutique » doit avoir 3 réplicas (actuel : ${reel:-absent}) : la réconciliation n'est pas terminée ?"; exit 1; }
img=$(kubectl -n apps-plateforme get deployment boutique -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$img" = "nginx:1.27-alpine" ] || { echo "L'image du Deployment réel doit être nginx:1.27-alpine (trouvé : ${img:-absent})."; exit 1; }
dispo=$(kubectl -n apps-plateforme get deployment boutique -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" -ge 1 ] || { echo "Aucun réplica du Deployment réel n'est disponible (kubectl -n apps-plateforme get pods)."; exit 1; }
sel=$(kubectl -n apps-plateforme get service boutique -o jsonpath='{.spec.selector.app}' 2>/dev/null)
[ "$sel" = "boutique" ] || { echo "Le Service réel « boutique » est absent ou son sélecteur app est incorrect (trouvé : ${sel:-absent})."; exit 1; }
echo "OK : XRD, Composition (Pipeline), XR boutique Ready+Synced ; Deployment réel à 3 réplicas (nginx:1.27-alpine) et Service réel créés par Crossplane."
exit 0
