# Module 15 — GitOps avec Argo CD (approfondissement)

## Pourquoi ce module ?

Le [cours GitOps du module 12](../12-cicd/cours/08-gitops-et-deploiement-declaratif.md) a présenté l'idée et un premier aperçu d'Argo CD. Ce module en est l'**approfondissement** : les **principes** qui rendent GitOps robuste, l'**architecture** d'Argo CD (composants, RBAC, SSO, notifications), les **politiques de synchronisation** (`selfHeal`, `prune`, vagues, hooks), les **ApplicationSets** pour le multi-environnement et le multi-cluster, **Kustomize et Helm** avec Argo CD, les **secrets** dans un monde où tout est dans Git, et **Flux CD** comme alternative.

> 🗺️ **Place dans le parcours.** Ce module porte le **numéro 15** mais se lit **après le CI/CD (12), l'IaC (13) et le Cloud AWS (14)**, et **avant le Monitoring (10) et le SRE (11)**. La numérotation des dossiers est gelée ; l'ordre pédagogique est expliqué dans le [README principal](../README.md). La logique : **on livre (12), on provisionne (13, 14), on déploie en continu par GitOps (15), puis on observe (10) et on fiabilise (11)**.

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [09 Kubernetes](../09-kubernetes-approfondi/README.md) | Deployments, Services, RBAC, CRD : ce qu'Argo CD réconcilie |
| [12 CI/CD](../12-cicd/README.md) | Pipelines, artefacts, et surtout le [cours GitOps](../12-cicd/cours/08-gitops-et-deploiement-declaratif.md) |
| [13 IaC](../13-iac/README.md) | État désiré, dérive, idempotence ; Terraform crée les clusters que GitOps remplit |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Principes GitOps avancés](cours/01-principes-gitops-avances.md) | ⭐⭐⭐ | Les 4 principes OpenGitOps, pull vs push, boucle de réconciliation, dérive, GitOps vs CI/CD, niveaux de maturité |
| 2 | [Argo CD : architecture](cours/02-argo-cd-architecture.md) | ⭐⭐⭐ | Composants, installation (manifestes, Helm, HA), AppProject et RBAC, SSO OIDC, notifications |
| 3 | [Application et politiques de synchronisation](cours/03-application-et-sync-policies.md) | ⭐⭐⭐⭐ | `syncPolicy`, `prune`, `selfHeal`, `syncOptions`, vagues, hooks, santé personnalisée |
| 4 | [ApplicationSets et multi-environnements](cours/04-applicationsets-multi-env.md) | ⭐⭐⭐⭐ | Générateurs (List, Cluster, Git, Matrix, Merge), gabarits, multi-env, multi-cluster, progressive sync |
| 5 | [Kustomize et Helm avec Argo CD](cours/05-kustomize-et-helm-avec-argo.md) | ⭐⭐⭐⭐ | Base/overlays, valeurs par environnement, multi-source, `helm template` vs Argo CD |
| 6 | [Secrets dans GitOps](cours/06-secrets-dans-gitops.md) | ⭐⭐⭐⭐ | Sealed Secrets, SOPS + age, External Secrets Operator, Vault, comparaison |
| 7 | [Flux CD et alternatives](cours/07-flux-cd-et-alternatives.md) | ⭐⭐⭐ | Flux (GitRepository, Kustomization, HelmRelease), Argo CD vs Flux, Rancher Fleet, Jenkins X |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — Installation d'Argo CD et premier déploiement](ateliers-killercoda/atelier-01-argo-cd-installation-premier-deploiement/intro.md) (3 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐ | 1, 2 |
| [Atelier 02 — Self-heal et prune](ateliers-killercoda/atelier-02-selfheal-et-prune/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐ | 3 |
| [Atelier 03 — ApplicationSet multi-environnements](ateliers-killercoda/atelier-03-applicationset-multi-env/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 4, 5 |

Procédure de publication : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 (installer Argo CD)
        → Cours 03 → Atelier 02 (self-heal et prune)
        → Cours 04 → Cours 05 → Atelier 03 (ApplicationSet)
        → Cours 06 → Cours 07
```

> 💡 **Conseil** : chaque atelier **réinstalle** Argo CD sur un cluster neuf (2 à 4 minutes) : ils sont indépendants. L'atelier 2 monte un **petit serveur Git local** dans le cluster pour que vous puissiez **modifier Git** (impossible sur un dépôt GitHub public) ; les ateliers 1 et 3 utilisent le dépôt public `argoproj/argocd-example-apps`.

## Ce que vous saurez faire à la fin

- Énoncer les **quatre principes OpenGitOps** et situer une organisation sur l'échelle de maturité.
- **Installer et sécuriser Argo CD** (projets, RBAC, SSO, notifications) et expliquer le rôle de chaque composant.
- Régler une **politique de synchronisation** (automatique, `prune`, `selfHeal`, vagues, hooks) sans se tirer une balle dans le pied.
- Générer des dizaines d'applications avec un **ApplicationSet** (multi-environnement, multi-cluster).
- Structurer un dépôt avec **Kustomize et Helm** et comprendre ce qu'Argo CD rend.
- **Gérer les secrets** sans jamais les commiter en clair, et comparer **Argo CD et Flux**.

## Navigation

- [← Module 14 — Cloud AWS](../14-cloud-aws/README.md)
- [→ Module 10 — Monitoring et observabilité](../10-monitoring-observabilite/README.md) (étape suivante du parcours)
- [← README principal](../README.md)
