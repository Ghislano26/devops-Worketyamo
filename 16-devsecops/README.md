# Module 16 — DevSecOps (supply chain, signature, policy as code)

## Pourquoi ce module ?

Le [cours « Sécurité dans la CI » du module 12](../12-cicd/cours/06-securite-dans-la-ci.md) a introduit SAST, SCA, SBOM et la gestion des secrets. Ce module les **approfondit** et couvre **toute la chaîne d'approvisionnement logicielle** : de la **dépendance** que l'on télécharge à l'**image** qui tourne en production. Vous apprendrez à **inventorier** (SBOM) et **scanner** ce que vous livrez, à **signer et prouver l'origine** d'un artefact (cosign, provenance SLSA), à **refuser à l'entrée du cluster** ce qui n'est pas conforme (policy as code), à **gérer les secrets** avec des coffres et des secrets dynamiques, et à **durcir** nœuds, runtime et pods (CIS, Pod Security Standards).

> 🗺️ **Place dans le parcours.** Ce module porte le **numéro 16** mais se lit **après le GitOps (15)** et **avant le Monitoring (10) et le SRE (11)** : on livre (12), on provisionne (13, 14), on déploie en continu (15), **on sécurise ce que l'on déploie (16)**, puis on observe (10) et on fiabilise (11). La numérotation des dossiers est gelée ; l'ordre pédagogique est expliqué dans le [README principal](../README.md).

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [08 Docker](../08-docker-approfondi/README.md) | Images, couches, registres, digests : ce que l'on signe et scanne |
| [09 Kubernetes](../09-kubernetes-approfondi/README.md) | Admission, RBAC, Pods : là où s'appliquent les politiques |
| [12 CI/CD](../12-cicd/README.md) | Pipelines et [sécurité dans la CI](../12-cicd/cours/06-securite-dans-la-ci.md) : le point de départ |
| [15 GitOps](../15-gitops-argocd/README.md) | Déploiement par réconciliation : l'admission est son dernier verrou |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Introduction au DevSecOps](cours/01-introduction-devsecops.md) | ⭐⭐ | *Shift left*, sécurité comme code, culture et rôles (security champion), les 4 piliers, pipeline sécurisé |
| 2 | [Sécurité de la chaîne d'approvisionnement](cours/02-supply-chain-security.md) | ⭐⭐⭐⭐ | SLSA, SBOM (SPDX et CycloneDX), SCA (Trivy, Dependabot…), confusion de dépendances, typosquatting, lockfiles, reproductibilité |
| 3 | [Signature et provenance](cours/03-signature-et-provenance.md) | ⭐⭐⭐⭐ | cosign (avec clé et keyless), Sigstore (Fulcio, Rekor), Notation, attestations in-toto, vérification à l'admission |
| 4 | [Policy as code pour Kubernetes](cours/04-policy-as-code-kubernetes.md) | ⭐⭐⭐⭐ | Kyverno, OPA Gatekeeper, ValidatingAdmissionPolicy, politiques courantes, tests, Audit vs Enforce |
| 5 | [Gestion des secrets](cours/05-secrets-management.md) | ⭐⭐⭐⭐ | Vault (architecture, secrets dynamiques, baux), External Secrets, AWS Secrets Manager, rotation, audit |
| 6 | [Durcissement et CIS Benchmarks](cours/06-hardening-et-cis-benchmarks.md) | ⭐⭐⭐ | CIS (Linux, Docker, Kubernetes), kube-bench, Lynis, SELinux / AppArmor / seccomp, Pod Security Standards |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — SBOM et scan de vulnérabilités](ateliers-killercoda/atelier-01-sbom-et-scan-vulnerabilites/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 2 |
| [Atelier 02 — Signature d'image avec cosign](ateliers-killercoda/atelier-02-signature-image-cosign/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 3 |
| [Atelier 03 — Politiques Kyverno](ateliers-killercoda/atelier-03-kyverno-policies/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐ | 4 |

Procédure de publication : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 (SBOM et scan)
        → Cours 03 → Atelier 02 (cosign)
        → Cours 04 → Atelier 03 (Kyverno)
        → Cours 05 → Cours 06
```

> 💡 **Conseil** : les ateliers 1 et 2 s'enchaînent bien : la SBOM produite à l'atelier 1 peut être **attestée** à l'atelier 2 (défi bonus). L'atelier 2 **simule** l'admission par un script ; l'atelier 3 montre l'admission **réelle** avec Kyverno, et le [cours 3](cours/03-signature-et-provenance.md) explique comment lui faire vérifier des signatures (`verifyImages`).

## Ce que vous saurez faire à la fin

- Situer une pratique dans les **quatre piliers** (code, build, deploy, runtime) et décrire un **pipeline sécurisé**.
- Produire et exploiter une **SBOM**, **scanner** et **prioriser** les vulnérabilités (correctif disponible, exploitabilité).
- **Signer** une image, **vérifier** sa signature et comprendre keyless, Rekor et les **attestations**.
- Écrire, tester et déployer des **politiques d'admission** (Audit puis Enforce).
- Choisir une stratégie de **secrets** (Vault et secrets dynamiques, gestionnaires cloud, External Secrets).
- **Durcir** un nœud, un cluster et un pod (CIS, kube-bench, Pod Security Standards).

## Navigation

- [← Module 15 — GitOps avec Argo CD](../15-gitops-argocd/README.md)
- [→ Module 10 — Monitoring et observabilité](../10-monitoring-observabilite/README.md) (étape suivante du parcours)
- [← README principal](../README.md)
