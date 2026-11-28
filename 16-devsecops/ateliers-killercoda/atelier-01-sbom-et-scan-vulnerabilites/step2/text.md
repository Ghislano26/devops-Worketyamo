# Étape 2 : scanner avec Trivy et comparer

## A. Scanner l'image et la SBOM

**Trivy** compare les composants à une base de vulnérabilités. Le premier lancement **télécharge la base** (patientez). On scanne l'**image** puis la **SBOM** seule (sans l'image) :

```bash
cd ~/sca
trivy image --format json --output trivy-image-debian10.json debian:10-slim
trivy sbom --format json --output trivy-sbom-debian10.json sbom-debian10.cdx.json
trivy image --format json --output trivy-image-alpine320.json alpine:3.20
```{{exec}}

Comptez les vulnérabilités de chaque rapport :

```bash
cd ~/sca
for f in trivy-image-debian10.json trivy-sbom-debian10.json trivy-image-alpine320.json; do
  printf "%-32s " "$f"
  jq '[.Results[]?.Vulnerabilities[]?] | length' "$f"
done
echo "--- Par gravité (image debian:10-slim)"
jq -r '[.Results[]?.Vulnerabilities[]?.Severity] | group_by(.) | map("\(.[0]) : \(length)") | .[]' trivy-image-debian10.json
```{{exec}}

> Les deux rapports de `debian:10-slim` (image et SBOM) sont **proches mais pas forcément identiques** : la SBOM contient les paquets que Syft a vus, Trivy ajoute des informations (état du correctif) en lisant l'image. Retenez : **scanner la SBOM stockée** permet de réévaluer un artefact **sans le retélécharger**, quand une nouvelle CVE est publiée.

## B. Se concentrer sur ce qui est actionnable

Le bruit décourage : on filtre sur les failles **graves** et **corrigeables** (celles pour lesquelles une version corrigée existe) :

```bash
cd ~/sca
trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update debian:10-slim | head -n 40
jq -r '[.Results[]?.Vulnerabilities[]? | select(.FixedVersion != null)] | length' trivy-image-debian10.json
```{{exec}}

## C. Lire une CVE

Choisissez une vulnérabilité **corrigeable** et lisez sa fiche : composant, version installée, **version corrigée**, gravité, description.

```bash
cd ~/sca
jq -r '[.Results[]?.Vulnerabilities[]? | select(.FixedVersion != null)][0] | "\(.VulnerabilityID) | \(.PkgName) \(.InstalledVersion) -> \(.FixedVersion) | \(.Severity)\n\(.Title)\n\(.PrimaryURL)"' trivy-image-debian10.json
jq -r '[.Results[]?.Vulnerabilities[]? | select(.FixedVersion != null)][0].VulnerabilityID' trivy-image-debian10.json > cve-a-etudier.txt
cat cve-a-etudier.txt
```{{exec}}

Le fichier `~/sca/cve-a-etudier.txt` contient maintenant l'identifiant d'une CVE réelle de votre rapport. Pour la corriger, il faudrait **mettre à jour le paquet** (reconstruire l'image sur une base à jour), pas modifier l'application.

## D. Comparer avec l'image minimale

```bash
cd ~/sca
trivy image --skip-db-update alpine:3.20 | head -n 15
```{{exec}}

## Questions

- Que signifie `FixedVersion` vide ? *(Aucun correctif n'est disponible : on peut accepter le risque, isoler, ou changer de composant ; d'où l'option `--ignore-unfixed` en CI.)*
- Une CVE `CRITICAL` dans un paquet que votre application n'utilise pas est-elle urgente ? *(Moins qu'une faille activement exploitée et exposée ; voir EPSS et KEV dans le [cours 2](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/02-supply-chain-security.md).)*
- Pourquoi reconstruire l'image plutôt que patcher le conteneur en place ? *(L'image est **immuable** et versionnée ; on reconstruit, rescanne, signe et redéploie.)*

Cliquez sur **Vérifier**.
