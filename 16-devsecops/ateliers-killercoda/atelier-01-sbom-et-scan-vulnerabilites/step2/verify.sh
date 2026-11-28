#!/bin/bash
d="$HOME/sca"
command -v trivy >/dev/null 2>&1 || { echo "Trivy n'est pas installé (voir la mise en place)."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq n'est pas installé."; exit 1; }
for f in trivy-image-debian10.json trivy-sbom-debian10.json trivy-image-alpine320.json; do
  [ -s "$d/$f" ] || { echo "Le rapport $d/$f est absent (étape 2 A)."; exit 1; }
  jq -e '.SchemaVersion' "$d/$f" >/dev/null 2>&1 || { echo "$f n'est pas un rapport JSON Trivy valide."; exit 1; }
done
nb=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$d/trivy-image-debian10.json")
[ "${nb:-0}" -ge 1 ] || { echo "Le rapport de debian:10-slim ne contient aucune vulnérabilité : le scan a-t-il bien été fait sur cette image ?"; exit 1; }
[ -s "$d/cve-a-etudier.txt" ] || { echo "Le fichier $d/cve-a-etudier.txt est absent (étape 2 C)."; exit 1; }
cve=$(tr -d ' \n\r' < "$d/cve-a-etudier.txt")
echo "$cve" | grep -Eq '^CVE-[0-9]{4}-[0-9]+$' || { echo "cve-a-etudier.txt doit contenir un identifiant CVE (trouvé : « $cve »)."; exit 1; }
jq -e --arg c "$cve" '[.Results[]?.Vulnerabilities[]?.VulnerabilityID] | index($c) != null' "$d/trivy-image-debian10.json" >/dev/null 2>&1 || { echo "$cve n'apparaît pas dans le rapport trivy-image-debian10.json."; exit 1; }
na=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$d/trivy-image-alpine320.json")
echo "OK : rapports Trivy valides. debian:10-slim : $nb vulnérabilités ; alpine:3.20 : ${na:-0} ; CVE étudiée : $cve."
exit 0
