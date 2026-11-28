# Ateliers Killercoda — DevSecOps

Trois scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** : deux sur un serveur **Ubuntu** (`ubuntu`), un sur un **cluster Kubernetes d'un nœud déjà prêt** (`kubernetes-kubeadm-1node`). Les outils (Syft, Trivy, cosign, Helm, Kyverno) sont **installés par l'introduction ou la première étape de chaque scénario**, en **versions épinglées**.

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-sbom-et-scan-vulnerabilites`](atelier-01-sbom-et-scan-vulnerabilites/) | `ubuntu` | ~25 min | ⭐⭐⭐ | **SBOM** CycloneDX et SPDX (Syft), scan d'image et de SBOM (Trivy), filtrage `--ignore-unfixed`, lecture d'une CVE | [2](../cours/02-supply-chain-security.md) |
| [`atelier-02-signature-image-cosign`](atelier-02-signature-image-cosign/) | `ubuntu` | ~25 min | ⭐⭐⭐ | **cosign** (paire de clés), registre local, signature du digest, vérification, tag réécrit, **admission simulée** | [3](../cours/03-signature-et-provenance.md) |
| [`atelier-03-kyverno-policies`](atelier-03-kyverno-policies/) | `kubernetes-kubeadm-1node` | ~25 min | ⭐⭐⭐ | **Kyverno** (Helm), `ClusterPolicy` interdisant `:latest`, pod conforme et non conformes, **Audit** puis **Enforce** | [4](../cours/04-policy-as-code-kubernetes.md) |

**Lisez le cours associé avant chaque atelier.** Les cours 1 (introduction), 5 (secrets) et 6 (durcissement) ne sont pas pratiqués ici : Vault et les benchmarks CIS demandent un environnement dédié ; ils se mettent en pratique sur votre propre infrastructure.

## Ce que fait chaque scénario

| Atelier | Installe / crée | Vérification (`verify.sh`) |
|---|---|---|
| 1 | `jq`, **Syft `v1.14.0`**, **Trivy `v0.57.0`** ; `~/sca/` : 3 SBOM, 3 rapports Trivy, `cve-a-etudier.txt` | **SBOM relues avec `jq`** (format CycloneDX/SPDX, présence de `bash` ou `musl`) ; **rapports Trivy valides** avec ≥ 1 vulnérabilité ; la CVE notée **existe dans le rapport** |
| 2 | **cosign `v2.4.1`**, `jq`, conteneur `registry` (`localhost:5000`), `~/cosign-lab/` : clés, `digest.txt`, `admission.sh` | **Registre actif**, images publiées, **tag `.sig` présent**, **`cosign verify`** réussi sur l'image signée et **en échec** sur l'image non signée, `admission.sh` **admet / refuse** correctement, digest conforme après restauration |
| 3 | **Helm `v3.16.3`**, **Kyverno** (chart `3.3.4`), `ClusterPolicy` `interdire-latest`, pod `web-ok` | **Contrôleur d'admission prêt**, **politique `Ready` en `Enforce`**, pod conforme **Running**, pods `:latest` et sans tag **absents**, **`--dry-run=server` refusé** avec le nom de la politique |

Les vérifications **testent l'état réel** (SBOM relues, signatures vérifiées, registre interrogé, admission Kubernetes réellement sollicitée), pas seulement la présence de fichiers.

## Limites assumées

- **Atelier 2** : mode **avec clé locale** et **sans journal Rekor** (`--tlog-upload=false`), faute de fournisseur d'identité interactif sur Killercoda. Le mode **keyless** est expliqué au [cours 3](../cours/03-signature-et-provenance.md) mais non pratiqué. L'**admission est simulée** par un script ; la vraie vérification de signature dans un cluster (`verifyImages` de Kyverno) est décrite au cours, pas exécutée.
- **Atelier 1** : les chiffres de vulnérabilités **évoluent chaque jour** avec la base de Trivy : les vérifications n'exigent jamais un nombre précis.
- **Atelier 3** : l'installation de Kyverno est en **mode non haute disponibilité** (un réplica de chaque contrôleur), adaptée à l'atelier, pas à la production.

## Prérequis réseau et durée

| Téléchargement | Source | Indication |
|---|---|---|
| Syft, Trivy (scripts d'installation et binaires) | `raw.githubusercontent.com`, releases GitHub | ~100 Mo au total |
| Base de vulnérabilités de Trivy (1ᵉʳ scan) | `ghcr.io` | quelques dizaines de Mo, **~1 minute** |
| Images `debian:10-slim`, `alpine:3.20` | Docker Hub | quelques dizaines de Mo |
| cosign, `registry:2`, `busybox`, `alpine` | Releases GitHub, Docker Hub | ~100 Mo |
| Helm, chart et images Kyverno | `raw.githubusercontent.com`, `kyverno.github.io`, `reg.kyverno.io` / `ghcr.io` | **2 à 4 minutes** d'installation |

Chaque scénario est **indépendant** : il installe ses propres outils sur une machine neuve.

## Publier sur Killercoda

Procédure complète (dépôt GitHub, `structure.json`, mises à jour, tests) dans [**`KILLERCODA.md`**](../../KILLERCODA.md). Contrôle local avant de pousser :

```bash
python3 scripts/check-killercoda.py
```

> ⚠️ **Attention** : les scénarios installent des outils et des services sur la machine ou le cluster **jetables** du scénario. Les clés générées à l'atelier 2 (mot de passe **vide**) sont **pédagogiques** : ne les réutilisez jamais ailleurs.

[← Retour au module 16](../README.md)
