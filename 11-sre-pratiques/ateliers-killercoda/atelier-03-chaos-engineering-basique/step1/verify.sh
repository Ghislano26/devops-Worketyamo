#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }

dispo=$(kubectl get deployment web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${dispo:-0}" != "3" ]; then
  echo "Le Deployment « web » doit avoir 3 réplicas disponibles (actuel : ${dispo:-0})."
  exit 1
fi
non_running=$(kubectl get pods -l app=web --no-headers 2>/dev/null | grep -vc ' Running ')
total=$(kubectl get pods -l app=web --no-headers 2>/dev/null | wc -l)
if [ "$total" -ne 3 ] || [ "$non_running" -ne 0 ]; then
  echo "Les 3 pods « web » doivent tous être Running (total : $total, non Running : $non_running)."
  exit 1
fi
nom="verif-$RANDOM"
if ! kubectl run "$nom" --rm -i --restart=Never --image=busybox:1.36 --command -- wget -q -O- -T 5 http://web 2>/dev/null | grep -qi 'nginx'; then
  echo "Le Service « web » ne répond pas depuis un pod client."
  kubectl delete pod "$nom" --ignore-not-found >/dev/null 2>&1
  exit 1
fi
[ -s "$HOME/chaos/experience.md" ] || { echo "Le fichier ~/chaos/experience.md (hypothèse) est absent ou vide."; exit 1; }
grep -qi 'hypoth' "$HOME/chaos/experience.md" || { echo "Le fichier experience.md doit contenir votre hypothèse."; exit 1; }
echo "OK : 3 pods Running, Service opérationnel, hypothèse écrite."
exit 0
