#!/bin/bash
command -v kubectl >/dev/null 2>&1 || { echo "kubectl est introuvable."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 est introuvable."; exit 1; }
API="/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute"
alloc() { kubectl get --raw "$API?window=$1&aggregate=${2:-namespace}&accumulate=true" 2>/dev/null; }
dep_ok() { d=$(kubectl -n "$1" get deployment "$2" -o jsonpath='{.status.availableReplicas}' 2>/dev/null); [ "${d:-0}" -ge 1 ]; }
dep_ok prometheus-system prometheus-server || { echo "Le Deployment « prometheus-server » (namespace prometheus-system) n'est pas prêt (étape d'installation)."; exit 1; }
dep_ok opencost opencost || { echo "Le Deployment « opencost » (namespace opencost) n'est pas prêt (kubectl -n opencost get pods)."; exit 1; }

d="$HOME/finops-lab"
rep=$(kubectl -n finops-lab get deployment gaspillage -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "${rep:-0}" = "3" ] || { echo "Le Deployment « gaspillage » doit avoir 3 réplicas disponibles (trouvé : ${rep:-0}) : le rightsizing ne doit pas casser l'application."; exit 1; }
python3 - <<'PYEOF'
import subprocess, sys
def en_milli(v):
    return float(v[:-1]) if v.endswith("m") else float(v) * 1000
def en_mi(v):
    for suf, f in (("Gi", 1024), ("Mi", 1), ("Ki", 1 / 1024)):
        if v.endswith(suf):
            return float(v[:-len(suf)]) * f
    return float(v) / (1024 * 1024)
def jp(chemin):
    return subprocess.run(["kubectl", "-n", "finops-lab", "get", "deployment", "gaspillage", "-o", "jsonpath=" + chemin],
                          capture_output=True, text=True).stdout
cpu = jp("{.spec.template.spec.containers[0].resources.requests.cpu}")
mem = jp("{.spec.template.spec.containers[0].resources.requests.memory}")
if not cpu or not mem:
    print("Les requests du Deployment sont absentes."); sys.exit(1)
if en_milli(cpu) > 50:
    print("Les requests CPU sont encore élevées (%s) : réduisez-les (≤ 50m)." % cpu); sys.exit(1)
if en_mi(mem) > 64:
    print("Les requests mémoire sont encore élevées (%s) : réduisez-les (≤ 64Mi)." % mem); sys.exit(1)
if en_milli(cpu) < 1 or en_mi(mem) < 4:
    print("Les requests sont trop basses pour être réalistes (cpu=%s, memory=%s) : gardez une marge." % (cpu, mem)); sys.exit(1)
PYEOF
[ $? -eq 0 ] || exit 1
[ -s "$d/apres.json" ] || { echo "Le fichier $d/apres.json est absent (partie C)."; exit 1; }
[ -s "$d/avant.json" ] || { echo "Le fichier $d/avant.json (étape 1) est absent."; exit 1; }
python3 - "$d" <<'PYEOF'
import json, sys
d = sys.argv[1]
try:
    a = json.load(open(d + "/avant.json"))["data"][0]["finops-lab"]
    b = json.load(open(d + "/apres.json"))["data"][0]["finops-lab"]
except Exception:
    print("avant.json ou apres.json ne contient pas l'allocation de « finops-lab »."); sys.exit(1)
if b.get("cpuCoreRequestAverage", 9) > 0.15:
    print("Le CPU demandé mesuré « après » est %.3f : la fenêtre contient encore d'anciens pods. Attendez 7 minutes après le déploiement et refaites apres.json." % b.get("cpuCoreRequestAverage", 0)); sys.exit(1)
if b["cpuCoreRequestAverage"] > 0.5 * a["cpuCoreRequestAverage"]:
    print("Le CPU demandé n'a pas baissé d'au moins 50 %% (avant %.3f, après %.3f)." % (a["cpuCoreRequestAverage"], b["cpuCoreRequestAverage"])); sys.exit(1)
if b["totalCost"] >= a["totalCost"]:
    print("Le coût mesuré n'a pas diminué (avant %.5f, après %.5f)." % (a["totalCost"], b["totalCost"])); sys.exit(1)
PYEOF
[ $? -eq 0 ] || exit 1
grep -q '%' "$d/bilan.txt" 2>/dev/null || { echo "Le fichier $d/bilan.txt (comparaison avant / après) est absent ou vide (partie C)."; exit 1; }
echo "OK : requests réduites, application disponible (3 réplicas), CPU demandé et coût mesurés en baisse dans OpenCost, bilan établi."
exit 0
