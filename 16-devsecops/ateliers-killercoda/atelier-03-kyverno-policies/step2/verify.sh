#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
kubectl get clusterpolicy interdire-latest >/dev/null 2>&1 || { echo "La ClusterPolicy « interdire-latest » est absente."; exit 1; }
action=$(kubectl get clusterpolicy interdire-latest -o jsonpath='{.spec.validationFailureAction}')
case "$action" in Enforce|enforce) ;; *) echo "La politique doit être revenue en mode Enforce (actuel : ${action:-vide}) : partie D."; exit 1;; esac
phase=$(kubectl get pod web-ok -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$phase" = "Running" ] || { echo "Le pod conforme « web-ok » doit être Running (phase : ${phase:-absent}) : kubectl run web-ok --image=nginx:1.27-alpine."; exit 1; }
img=$(kubectl get pod web-ok -o jsonpath='{.spec.containers[0].image}')
[ "$img" = "nginx:1.27-alpine" ] || { echo "web-ok doit utiliser nginx:1.27-alpine (trouvé : $img)."; exit 1; }
for p in web-latest web-notag audit-latest; do
  if kubectl get pod "$p" >/dev/null 2>&1; then echo "Le pod « $p » ne devrait pas exister (refusé en Enforce, ou à supprimer après la partie C)."; exit 1; fi
done
sortie=$(kubectl run verif-latest --image=nginx:latest --dry-run=server 2>&1); rc=$?
[ "$rc" -ne 0 ] || { echo "Un pod nginx:latest est ACCEPTÉ : la politique n'est pas appliquée. Attendez quelques secondes ou vérifiez Kyverno."; exit 1; }
echo "$sortie" | grep -q 'interdire-latest' || { echo "Le refus ne cite pas la politique interdire-latest : $sortie"; exit 1; }
kubectl run verif-notag --image=nginx --dry-run=server >/dev/null 2>&1; rc2=$?
[ "$rc2" -ne 0 ] || { echo "Un pod sans tag est ACCEPTÉ : la règle tag-obligatoire n'est pas appliquée."; exit 1; }
echo "OK : web-ok (nginx:1.27-alpine) Running ; nginx:latest et nginx sans tag REFUSÉS par interdire-latest en mode Enforce."
exit 0
