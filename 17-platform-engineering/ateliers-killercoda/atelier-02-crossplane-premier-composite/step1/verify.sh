#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl get namespace crossplane-system >/dev/null 2>&1 || { echo "Le namespace crossplane-system est absent : Crossplane n'est pas installé (étape A)."; exit 1; }
dispo=$(kubectl -n crossplane-system get deployment crossplane -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${dispo:-0}" -ge 1 ] || { echo "Le Deployment « crossplane » n'est pas prêt (kubectl -n crossplane-system get pods)."; exit 1; }
sain=$(kubectl get provider.pkg.crossplane.io provider-kubernetes -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null)
[ "$sain" = "True" ] || { echo "Le provider « provider-kubernetes » n'est pas Healthy (kubectl describe provider provider-kubernetes)."; exit 1; }
sain=$(kubectl get function.pkg.crossplane.io function-patch-and-transform -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null)
[ "$sain" = "True" ] || { echo "La fonction « function-patch-and-transform » n'est pas Healthy."; exit 1; }
kubectl get providerconfig.kubernetes.crossplane.io default >/dev/null 2>&1 || { echo "Le ProviderConfig « default » est absent (étape C)."; exit 1; }
kubectl get clusterrolebinding provider-kubernetes-admin >/dev/null 2>&1 || { echo "Le ClusterRoleBinding « provider-kubernetes-admin » est absent (étape C) : le provider n'aurait pas les droits."; exit 1; }
kubectl get namespace apps-plateforme >/dev/null 2>&1 || { echo "Le namespace « apps-plateforme » est absent."; exit 1; }
prete=$(kubectl get object.kubernetes.crossplane.io bonjour -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$prete" = "True" ] || { echo "L'Object « bonjour » n'est pas Ready (étape D ; kubectl describe object bonjour)."; exit 1; }
msg=$(kubectl -n apps-plateforme get configmap bonjour -o jsonpath='{.data.message}' 2>/dev/null)
echo "$msg" | grep -q 'Crossplane' || { echo "Le ConfigMap réel « bonjour » est absent ou n'a pas le contenu attendu (trouvé : « $msg »)."; exit 1; }
echo "OK : Crossplane et provider-kubernetes prêts, ProviderConfig et droits en place, ConfigMap réel créé par une ressource gérée."
exit 0
