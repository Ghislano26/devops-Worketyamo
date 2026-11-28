#!/bin/bash
d="$HOME/sca"
command -v syft >/dev/null 2>&1 || { echo "Syft n'est pas installé (voir la mise en place)."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq n'est pas installé."; exit 1; }
for f in sbom-debian10.cdx.json sbom-debian10.spdx.json sbom-alpine320.cdx.json; do
  [ -s "$d/$f" ] || { echo "Le fichier $d/$f est absent ou vide (étape 1)."; exit 1; }
done
jq -e '.bomFormat=="CycloneDX" and (.components|length)>0' "$d/sbom-debian10.cdx.json" >/dev/null 2>&1 || { echo "sbom-debian10.cdx.json n'est pas une SBOM CycloneDX valide avec des composants."; exit 1; }
jq -e '(.spdxVersion|startswith("SPDX-")) and (.packages|length)>0' "$d/sbom-debian10.spdx.json" >/dev/null 2>&1 || { echo "sbom-debian10.spdx.json n'est pas une SBOM SPDX valide avec des paquets."; exit 1; }
jq -e '[.components[].name] | index("bash") != null' "$d/sbom-debian10.cdx.json" >/dev/null 2>&1 || { echo "La SBOM Debian devrait contenir le paquet « bash » : a-t-elle été générée depuis debian:10-slim ?"; exit 1; }
jq -e '[.components[].name] | index("musl") != null' "$d/sbom-alpine320.cdx.json" >/dev/null 2>&1 || { echo "La SBOM Alpine devrait contenir « musl » : a-t-elle été générée depuis alpine:3.20 ?"; exit 1; }
nd=$(jq '.components|length' "$d/sbom-debian10.cdx.json"); na=$(jq '.components|length' "$d/sbom-alpine320.cdx.json")
echo "OK : 3 SBOM valides (CycloneDX Debian : $nd composants ; SPDX Debian ; CycloneDX Alpine : $na composants)."
exit 0
