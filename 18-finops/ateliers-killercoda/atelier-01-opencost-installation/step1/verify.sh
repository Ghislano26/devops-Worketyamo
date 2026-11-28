#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 est introuvable."; exit 1; }
API="/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute"
alloc() { kubectl get --raw "$API?window=$1&aggregate=${2:-namespace}&accumulate=true" 2>/dev/null; }
dep_ok() { d=$(kubectl -n "$1" get deployment "$2" -o jsonpath='{.status.availableReplicas}' 2>/dev/null); [ "${d:-0}" -ge 1 ]; }
dep_ok prometheus-system prometheus-server || { echo "Le Deployment « prometheus-server » (namespace prometheus-system) n'est pas prêt (étape d'installation)."; exit 1; }
dep_ok opencost opencost || { echo "Le Deployment « opencost » (namespace opencost) n'est pas prêt (kubectl -n opencost get pods)."; exit 1; }

d="$HOME/finops-lab"
[ -x "$d/couts.py" ] || { echo "Le script $d/couts.py est absent ou non exécutable."; exit 1; }
sortie=$(alloc 30m namespace)
[ -n "$sortie" ] || { echo "L'API OpenCost ne répond pas (kubectl -n opencost get pods ; port 9003 du Service « opencost »)."; exit 1; }
echo "$sortie" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin).get("data") or []
except Exception:
    sys.exit(2)
if not d or not d[0]:
    sys.exit(3)
n = sum(1 for k, v in d[0].items() if not k.startswith("__") and v.get("totalCost", 0) > 0)
sys.exit(0 if n >= 3 else 4)
'
rc=$?
case $rc in
  0) ;;
  3) echo "OpenCost n'a pas encore de données : patientez quelques minutes (Prometheus collecte toutes les minutes)."; exit 1;;
  4) echo "Moins de 3 namespaces avec un coût : la collecte est incomplète, patientez ou vérifiez Prometheus (kubectl -n prometheus-system get pods)."; exit 1;;
  *) echo "Réponse inattendue de l'API OpenCost."; exit 1;;
esac
echo "OK : Prometheus et OpenCost prêts, l'API d'allocation renvoie des coûts par namespace."
exit 0
