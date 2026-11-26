#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }

f="$HOME/chaos/pod-supprime.txt"
[ -s "$f" ] || { echo "Le fichier ~/chaos/pod-supprime.txt est absent : notez-y le nom du pod supprimé."; exit 1; }
pod=$(tr -d ' \n' < "$f")
if kubectl get pod "$pod" >/dev/null 2>&1; then
  etat=$(kubectl get pod "$pod" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)
  if [ -z "$etat" ]; then
    echo "Le pod « $pod » existe toujours : il n'a pas été supprimé (kubectl delete pod $pod)."
    exit 1
  fi
  echo "Le pod « $pod » est encore en cours de suppression (Terminating) : patientez quelques secondes."
  exit 1
fi
for _ in 1 2 3 4 5 6; do
  dispo=$(kubectl get deployment web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "${dispo:-0}" = "3" ] && break
  sleep 5
done
if [ "${dispo:-0}" != "3" ]; then
  echo "Le Deployment « web » n'est pas revenu à 3 réplicas disponibles (actuel : ${dispo:-0})."
  exit 1
fi
if kubectl get pods -l app=web --no-headers 2>/dev/null | grep -q "^$pod "; then
  echo "Un pod nommé « $pod » existe : le pod supprimé aurait dû être REMPLACÉ par un pod au nom différent."
  exit 1
fi
echo "OK : le pod « $pod » a été supprimé puis remplacé ; le Deployment est revenu à 3 réplicas."
exit 0
