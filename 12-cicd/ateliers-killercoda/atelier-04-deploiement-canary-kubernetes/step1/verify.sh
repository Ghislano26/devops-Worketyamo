#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
for dep in app-v1 app-v2; do
  kubectl get deployment "$dep" >/dev/null 2>&1 || { echo "Le Deployment « $dep » est absent."; exit 1; }
done
img1=$(kubectl get deployment app-v1 -o jsonpath='{.spec.template.spec.containers[0].image}')
img2=$(kubectl get deployment app-v2 -o jsonpath='{.spec.template.spec.containers[0].image}')
[ "$img1" = "nginx:1.24" ] || { echo "app-v1 doit utiliser l'image nginx:1.24 (actuel : $img1)."; exit 1; }
[ "$img2" = "nginx:1.25" ] || { echo "app-v2 doit utiliser l'image nginx:1.25 (actuel : $img2)."; exit 1; }
d1=$(kubectl get deployment app-v1 -o jsonpath='{.status.availableReplicas}')
d2=$(kubectl get deployment app-v2 -o jsonpath='{.status.availableReplicas}')
[ "${d1:-0}" = "4" ] || { echo "app-v1 doit avoir 4 réplicas disponibles (actuel : ${d1:-0})."; exit 1; }
[ "${d2:-0}" = "1" ] || { echo "app-v2 doit avoir 1 réplica disponible (actuel : ${d2:-0})."; exit 1; }
sel=$(kubectl get service web -o jsonpath='{.spec.selector}' 2>/dev/null)
[ -n "$sel" ] || { echo "Le Service « web » est absent."; exit 1; }
if echo "$sel" | grep -q 'version'; then
  echo "Le sélecteur du Service ne doit pas contenir « version » : il doit cibler les deux versions via le label app=web."
  exit 1
fi
adresses=$(kubectl get endpoints web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
[ "$adresses" = "5" ] || { echo "Le Service web doit pointer vers 5 pods (4 + 1) — trouvé : $adresses."; exit 1; }
echo "OK : app-v1 (4 pods, nginx:1.24) et app-v2 (1 pod, nginx:1.25) derrière le Service web (5 endpoints)."
exit 0
