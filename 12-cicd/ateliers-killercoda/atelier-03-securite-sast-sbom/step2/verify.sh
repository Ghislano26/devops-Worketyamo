#!/bin/bash
command -v syft >/dev/null 2>&1 || { echo "syft n'est pas installé (voir l'introduction)."; exit 1; }
s="$HOME/sec/sbom.cdx.json"
[ -s "$s" ] || { echo "Le SBOM $s est absent : lancez « syft alpine:3.10 -o cyclonedx-json=\$HOME/sec/sbom.cdx.json »."; exit 1; }
if ! sortie=$(python3 - "$s" <<'EOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print("JSON invalide :", e); sys.exit(1)
if d.get("bomFormat") != "CycloneDX":
    print("bomFormat doit valoir « CycloneDX » (trouvé : %r)." % d.get("bomFormat")); sys.exit(1)
n = len(d.get("components") or [])
if n < 5:
    print("Le SBOM contient trop peu de composants (%d)." % n); sys.exit(1)
print(n)
EOF
); then
  echo "SBOM invalide : $sortie"
  exit 1
fi
echo "OK : SBOM CycloneDX valide ($sortie composants)."
exit 0
