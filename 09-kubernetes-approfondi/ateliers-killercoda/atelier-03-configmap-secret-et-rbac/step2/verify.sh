#!/bin/bash
# Étape 2 : le ServiceAccount « lecteur » peut lister les pods du namespace « atelier » mais pas les supprimer
SA="system:serviceaccount:atelier:lecteur"
if ! kubectl get serviceaccount lecteur -n atelier >/dev/null 2>&1; then
  echo "Le ServiceAccount « lecteur » n'existe pas dans le namespace « atelier »."
  exit 1
fi
if [ "$(kubectl auth can-i list pods -n atelier --as="$SA" 2>/dev/null)" != "yes" ]; then
  echo "« lecteur » devrait pouvoir lister les pods du namespace atelier (Role + RoleBinding manquants ?)."
  exit 1
fi
if [ "$(kubectl auth can-i delete pods -n atelier --as="$SA" 2>/dev/null)" != "no" ]; then
  echo "« lecteur » ne devrait PAS pouvoir supprimer des pods (principe du moindre privilège)."
  exit 1
fi
if [ "$(kubectl auth can-i list secrets -n atelier --as="$SA" 2>/dev/null)" != "no" ]; then
  echo "« lecteur » ne devrait PAS pouvoir lister les secrets."
  exit 1
fi
if [ "$(kubectl auth can-i list pods -n default --as="$SA" 2>/dev/null)" != "no" ]; then
  echo "« lecteur » ne devrait avoir aucun droit en dehors du namespace atelier."
  exit 1
fi
echo "OK : « lecteur » peut lister les pods d'atelier, mais ne peut ni les supprimer ni lire les secrets."
exit 0
