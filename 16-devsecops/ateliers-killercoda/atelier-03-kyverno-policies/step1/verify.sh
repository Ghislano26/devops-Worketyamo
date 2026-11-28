#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl get namespace kyverno >/dev/null 2>&1 || { echo "Le namespace « kyverno » est absent : Kyverno n'est pas installé."; exit 1; }
kubectl get crd clusterpolicies.kyverno.io >/dev/null 2>&1 || { echo "Le CRD clusterpolicies.kyverno.io est absent."; exit 1; }
dispo=$(kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" -ge 1 ] || { echo "Le Deployment « kyverno-admission-controller » n'est pas prêt (kubectl -n kyverno get pods)."; exit 1; }
kubectl get clusterpolicy interdire-latest >/dev/null 2>&1 || { echo "La ClusterPolicy « interdire-latest » est absente (kubectl apply -f interdire-latest.yaml)."; exit 1; }
action=$(kubectl get clusterpolicy interdire-latest -o jsonpath='{.spec.validationFailureAction}')
case "$action" in Enforce|enforce) ;; *) echo "validationFailureAction doit valoir Enforce (trouvé : ${action:-vide})."; exit 1;; esac
ready=$(kubectl get clusterpolicy interdire-latest -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
rd2=$(kubectl get clusterpolicy interdire-latest -o jsonpath='{.status.ready}' 2>/dev/null)
if [ "$ready" != "True" ] && [ "$rd2" != "true" ]; then echo "La politique n'est pas encore Ready (patientez quelques secondes : kubectl get clusterpolicy)."; exit 1; fi
nbr=$(kubectl get clusterpolicy interdire-latest -o jsonpath='{.spec.rules[*].name}' | wc -w | tr -d ' ')
[ "$nbr" -ge 2 ] || { echo "La politique doit contenir 2 règles (tag obligatoire, pas de latest) ; trouvé : $nbr."; exit 1; }
echo "OK : Kyverno installé (admission-controller prêt), ClusterPolicy interdire-latest en mode Enforce et Ready."
exit 0
