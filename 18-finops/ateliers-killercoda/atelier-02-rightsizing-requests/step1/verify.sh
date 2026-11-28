#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 est introuvable."; exit 1; }
API="/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute"
alloc() { kubectl get --raw "$API?window=$1&aggregate=${2:-namespace}&accumulate=true" 2>/dev/null; }
dep_ok() { d=$(kubectl -n "$1" get deployment "$2" -o jsonpath='{.status.availableReplicas}' 2>/dev/null); [ "${d:-0}" -ge 1 ]; }
dep_ok prometheus-system prometheus-server || { echo "Le Deployment « prometheus-server » (namespace prometheus-system) n'est pas prêt (étape d'installation)."; exit 1; }
dep_ok opencost opencost || { echo "Le Deployment « opencost » (namespace opencost) n'est pas prêt (kubectl -n opencost get pods)."; exit 1; }

d="$HOME/finops-lab"
kubectl get namespace finops-lab >/dev/null 2>&1 || { echo "Le namespace « finops-lab » est absent (partie A)."; exit 1; }
rep=$(kubectl -n finops-lab get deployment gaspillage -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${rep:-0}" = "3" ] || { echo "Le Deployment « gaspillage » doit avoir 3 réplicas disponibles (trouvé : ${rep:-0}). Pods Pending ? kubectl -n finops-lab describe pods"; exit 1; }
cpu=$(kubectl -n finops-lab get deployment gaspillage -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
mem=$(kubectl -n finops-lab get deployment gaspillage -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
[ "$cpu" = "250m" ] && [ "$mem" = "256Mi" ] || { echo "À ce stade, les requests doivent être cpu=250m et memory=256Mi (trouvé : cpu=$cpu memory=$mem) : la réduction se fait à l'étape 2."; exit 1; }
[ -s "$d/avant.json" ] || { echo "Le fichier $d/avant.json est absent (partie C)."; exit 1; }
python3 - "$d/avant.json" <<'PYEOF'
import json, sys
try:
    a = json.load(open(sys.argv[1]))["data"][0]["finops-lab"]
except Exception:
    print("avant.json ne contient pas d'allocation pour « finops-lab » : refaites la mesure après quelques minutes."); sys.exit(1)
if a.get("cpuCoreRequestAverage", 0) < 0.5:
    print("Le CPU demandé mesuré est %.3f (attendu ~0,75) : la fenêtre n'est pas encore remplie, patientez et refaites avant.json." % a.get("cpuCoreRequestAverage", 0)); sys.exit(1)
if a.get("cpuCoreUsageAverage", 1) > 0.1:
    print("Le CPU utilisé est élevé (%.3f) : la charge ne devrait pas consommer de CPU." % a.get("cpuCoreUsageAverage", 0)); sys.exit(1)
if a.get("cpuEfficiency", 1) > 0.2:
    print("L'efficience CPU est de %.0f %% : attendue très basse." % (a.get("cpuEfficiency", 0) * 100)); sys.exit(1)
PYEOF
[ $? -eq 0 ] || exit 1
echo "OK : Deployment « gaspillage » (3 × 250m / 256Mi) en place ; état « avant » mesuré (CPU demandé élevé, utilisé quasi nul, efficience très basse)."
exit 0
