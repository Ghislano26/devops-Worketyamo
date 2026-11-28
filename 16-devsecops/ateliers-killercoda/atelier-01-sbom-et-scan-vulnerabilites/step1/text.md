# Étape 1 : générer des SBOM avec Syft

**Syft** analyse une image (paquets du système, bibliothèques de langages) et produit l'**inventaire** de ses composants. On génère **deux formats** : **CycloneDX** (orienté sécurité, OWASP) et **SPDX** (orienté conformité, Linux Foundation).

```bash
mkdir -p ~/sca && cd ~/sca
syft debian:10-slim -o cyclonedx-json=sbom-debian10.cdx.json -o spdx-json=sbom-debian10.spdx.json
ls -lh
```{{exec}}

Inspectez le contenu avec `jq` :

```bash
cd ~/sca
echo "--- CycloneDX"
jq '{format: .bomFormat, version: .specVersion, composants: (.components | length)}' sbom-debian10.cdx.json
jq -r '.components[] | select(.type=="library") | "\(.name) \(.version)"' sbom-debian10.cdx.json | head -n 10
echo "--- SPDX"
jq '{version: .spdxVersion, paquets: (.packages | length)}' sbom-debian10.spdx.json
```{{exec}}

Cherchez un composant précis, comme on le ferait à l'annonce d'une faille (« avons-nous `openssl` ? ») :

```bash
cd ~/sca
jq -r '.components[] | select(.name | test("openssl|libssl")) | "\(.name) \(.version)"' sbom-debian10.cdx.json
```{{exec}}

Produisez aussi la SBOM de l'image récente pour la comparaison de l'étape 2 :

```bash
cd ~/sca
syft alpine:3.20 -o cyclonedx-json=sbom-alpine320.cdx.json
jq '.components | length' sbom-alpine320.cdx.json sbom-debian10.cdx.json
```{{exec}}

## Questions

- Quelle image contient **le moins de composants** ? Quel intérêt pour la sécurité ? *(Moins de composants = moins de vulnérabilités potentielles : c'est l'argument des images minimales.)*
- Pourquoi deux formats ? *(SPDX est fort sur les licences et la conformité ; CycloneDX sur la sécurité ; les outils lisent les deux.)*

Cliquez sur **Vérifier**.
