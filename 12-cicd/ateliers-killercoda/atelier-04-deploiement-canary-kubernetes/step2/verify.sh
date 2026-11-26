#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
for _ in 1 2 3 4 5 6; do
  d2=$(kubectl get deployment app-v2 -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "${d2:-0}" = "4" ] && break
  sleep 5
done
[ "${d2:-0}" = "4" ] || { echo "app-v2 doit avoir 4 réplicas disponibles (actuel : ${d2:-0})."; exit 1; }
r1=$(kubectl get deployment app-v1 -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "${r1:-1}" = "0" ] || { echo "app-v1 doit être réduit à 0 réplica après la promotion (actuel : ${r1:-?})."; exit 1; }
v1pods=$(kubectl get pods -l app=web,version=v1 --no-headers 2>/dev/null | grep -vc Terminating)
[ "$v1pods" = "0" ] || { echo "Il reste $v1pods pod(s) de la v1 : patientez qu'ils se terminent."; exit 1; }
adresses=$(kubectl get endpoints web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
[ "$adresses" = "4" ] || { echo "Le Service web doit pointer vers 4 pods de la v2 — trouvé : $adresses."; exit 1; }
echo "OK : canari promu, tout le trafic est servi par la v2 (4 pods)."
exit 0
