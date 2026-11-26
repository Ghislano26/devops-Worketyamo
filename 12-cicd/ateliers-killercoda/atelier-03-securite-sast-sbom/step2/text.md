# Étape 2 : l'inventaire des composants (SBOM)

Un **SBOM** liste tous les composants d'une image ; en cas de nouvelle faille, on y cherche immédiatement le paquet concerné ([cours 6, section SBOM](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/06-securite-dans-la-ci.md)).

## A. Générer le SBOM au format CycloneDX

```bash
cd ~/sec
syft alpine:3.10 -o cyclonedx-json="$HOME/sec/sbom.cdx.json"
ls -lh ~/sec/sbom.cdx.json
```{{exec}}

Inspectez-le :

```bash
python3 - <<'EOF'
import json, os
sbom = json.load(open(os.path.expanduser("~/sec/sbom.cdx.json")))
print("format :", sbom["bomFormat"], sbom.get("specVersion"))
print("composants :", len(sbom["components"]))
for c in sbom["components"][:8]:
    print(" -", c.get("name"), c.get("version"))
EOF
```{{exec}}

## B. Réutiliser le SBOM pour chercher des failles

Un SBOM permet de scanner **sans** réexaminer l'image : Trivy sait le lire.

```bash
trivy sbom --severity HIGH,CRITICAL --quiet ~/sec/sbom.cdx.json | tail -n 20
```{{exec}}

## Questions

- Quel intérêt de **conserver** le SBOM de chaque version déployée ? (Répondre en minutes à « sommes-nous touchés par cette CVE ? » sans reconstruire.)
- CycloneDX ou SPDX ? (CycloneDX est orienté sécurité, SPDX orienté licences.)

Cliquez sur **Vérifier**.
