#!/bin/bash
command -v trivy >/dev/null 2>&1 || { echo "trivy n'est pas installé (voir l'introduction)."; exit 1; }
r="$HOME/sec/rapport-trivy.json"
[ -s "$r" ] || { echo "Le rapport $r est absent : lancez « trivy image --format json --output ~/sec/rapport-trivy.json alpine:3.10 »."; exit 1; }
if ! sortie=$(python3 - "$r" <<'EOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print("JSON invalide :", e); sys.exit(1)
if "Results" not in d:
    print("Le rapport ne contient pas la clé « Results »."); sys.exit(1)
if "alpine" not in str(d.get("ArtifactName", "")):
    print("Le rapport ne concerne pas l'image alpine."); sys.exit(1)
n = sum(len(x.get("Vulnerabilities") or []) for x in d["Results"])
if n < 1:
    print("Le rapport ne contient aucune vulnérabilité."); sys.exit(1)
print(n)
EOF
); then
  echo "Rapport Trivy invalide : $sortie"
  exit 1
fi
g="$HOME/sec/gate.txt"
[ -s "$g" ] || { echo "Le fichier $g est absent : enregistrez le code de retour du seuil bloquant (partie B)."; exit 1; }
grep -qE '^code=[0-9]+$' "$g" || { echo "gate.txt doit contenir une ligne « code=N »."; exit 1; }
echo "OK : rapport Trivy valide ($sortie vulnérabilités) et seuil bloquant évalué ($(cat "$g"))."
exit 0
