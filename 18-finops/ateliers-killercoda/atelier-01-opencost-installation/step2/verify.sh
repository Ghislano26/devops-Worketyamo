#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 est introuvable."; exit 1; }
API="/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute"
alloc() { kubectl get --raw "$API?window=$1&aggregate=${2:-namespace}&accumulate=true" 2>/dev/null; }
dep_ok() { d=$(kubectl -n "$1" get deployment "$2" -o jsonpath='{.status.availableReplicas}' 2>/dev/null); [ "${d:-0}" -ge 1 ]; }
dep_ok prometheus-system prometheus-server || { echo "Le Deployment « prometheus-server » (namespace prometheus-system) n'est pas prêt (étape d'installation)."; exit 1; }
dep_ok opencost opencost || { echo "Le Deployment « opencost » (namespace opencost) n'est pas prêt (kubectl -n opencost get pods)."; exit 1; }

d="$HOME/finops-lab"
code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' http://localhost:9090/ 2>/dev/null)
[ "$code" = "200" ] || { echo "L'interface d'OpenCost ne répond pas sur http://localhost:9090 (HTTP ${code:-aucun}) : le port-forward tourne-t-il ? (voir /tmp/opencost-ui.log)"; exit 1; }
[ -s "$d/top-namespaces.txt" ] || { echo "Le fichier $d/top-namespaces.txt est absent ou vide (partie C)."; exit 1; }
[ -f "$d/inefficaces.txt" ] || { echo "Le fichier $d/inefficaces.txt est absent (partie D)."; exit 1; }
sortie=$(alloc 30m namespace)
[ -n "$sortie" ] || { echo "L'API OpenCost ne répond pas."; exit 1; }
echo "$sortie" | python3 -c '
import json, os, sys
d = json.load(sys.stdin)["data"][0]
home = os.path.expanduser("~/finops-lab")
top = [l.strip() for l in open(home + "/top-namespaces.txt") if l.strip()]
classement = [k for k, v in sorted(d.items(), key=lambda kv: -kv[1].get("totalCost", 0)) if not k.startswith("__")]
if len(top) != 3:
    print("top-namespaces.txt doit contenir exactement 3 namespaces (trouvé : %d)." % len(top)); sys.exit(2)
for n in top:
    if n not in classement[:6]:
        print("« %s » ne figure pas parmi les namespaces les plus coûteux d OpenCost (top actuel : %s)." % (n, ", ".join(classement[:6]))); sys.exit(3)
ineff = [l.strip() for l in open(home + "/inefficaces.txt") if l.strip()]
for n in ineff:
    if n not in d:
        print("« %s » (inefficaces.txt) est inconnu d OpenCost." % n); sys.exit(4)
'
rc=$?
[ $rc -eq 0 ] || exit 1
echo "OK : interface joignable, trois namespaces les plus coûteux identifiés, liste des charges inefficaces établie."
exit 0
