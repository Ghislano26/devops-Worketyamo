#!/bin/bash
# Étape 1 : Service ClusterIP « web » avec endpoints, joignable depuis un pod temporaire
type=$(kubectl get svc web -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$type" != "ClusterIP" ]; then
  echo "Le Service « web » de type ClusterIP n'existe pas (kubectl expose deployment web --port=80)."
  exit 1
fi
endpoints=$(kubectl get endpoints web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -z "$endpoints" ]; then
  echo "Le Service n'a aucun endpoint : le Deployment « web » a-t-il des pods prêts ?"
  exit 1
fi
nom="verif-$RANDOM"
if ! kubectl run "$nom" --rm -i --restart=Never --image=busybox:1.36 --command -- wget -qO- -T 5 http://web 2>/dev/null | grep -qi 'nginx'; then
  echo "Le test depuis un pod temporaire (wget http://web) a échoué."
  kubectl delete pod "$nom" --ignore-not-found >/dev/null 2>&1
  exit 1
fi
echo "OK : le Service web répond depuis le cluster."
exit 0
