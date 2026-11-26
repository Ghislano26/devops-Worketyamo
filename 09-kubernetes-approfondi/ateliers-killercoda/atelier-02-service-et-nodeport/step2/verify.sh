#!/bin/bash
# Étape 2 : le Service « web » est de type NodePort et répond sur ce port
type=$(kubectl get svc web -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$type" != "NodePort" ]; then
  echo "Le Service « web » n'est pas de type NodePort (type actuel : ${type:-inexistant})."
  exit 1
fi
np=$(kubectl get svc web -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -z "$np" ]; then
  echo "Aucun nodePort attribué."
  exit 1
fi
node_ip=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
for hote in localhost "$node_ip"; do
  [ -z "$hote" ] && continue
  if curl -fsS --max-time 5 "http://$hote:$np" 2>/dev/null | grep -qi 'nginx'; then
    echo "OK : le NodePort $np répond (via $hote)."
    exit 0
  fi
done
echo "Le NodePort $np ne répond pas (curl localhost:$np)."
exit 1
