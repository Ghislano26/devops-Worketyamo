# Module 17 — Platform Engineering (IDP, Backstage, Crossplane)

> 🎓 **Module senior.** Ce module s'adresse à des profils **DevOps confirmés** qui évoluent vers la **conception de plateformes** internes. Il mobilise presque tout le cursus (Kubernetes, CI/CD, GitOps, IaC, DevSecOps) et il est **facultatif** pour un parcours d'administrateur ou de développeur : on peut passer directement au Monitoring (10) et au SRE (11).

## Pourquoi ce module ?

Vous savez livrer, provisionner, déployer en continu et sécuriser. Mais **chaque équipe de développement ne peut pas tout maîtriser** : la charge cognitive de la chaîne complète (conteneurs, Kubernetes, CI, GitOps, secrets, politiques, observabilité) ralentit tout le monde. Le **Platform Engineering** construit une **plateforme interne** qui offre ces capacités **en libre-service**, avec les bonnes pratiques **déjà intégrées**, et la traite **comme un produit** dont les développeurs sont les clients. Ce module couvre le **pourquoi** (produit, métriques, organisation), le **quoi** (composants d'une IDP, golden paths), et deux outils phares : **Backstage** (portail et catalogue) et **Crossplane** (plan de contrôle d'infrastructure).

> 🗺️ **Place dans le parcours.** Ce module porte le **numéro 17** mais se lit **après le DevSecOps (16)** et **avant le Monitoring (10) et le SRE (11)** : on livre (12), on provisionne (13, 14), on déploie en continu (15), on sécurise (16), **on en fait une plateforme en libre-service (17)**, puis on observe (10) et on fiabilise (11). La numérotation des dossiers est gelée ; l'ordre pédagogique est expliqué dans le [README principal](../README.md).

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [09 Kubernetes](../09-kubernetes-approfondi/README.md) | CRD, contrôleurs, RBAC : Crossplane et Backstage s'y appuient |
| [12 CI/CD](../12-cicd/README.md) | Chaîne de livraison que les golden paths encapsulent |
| [15 GitOps](../15-gitops-argocd/README.md) | Livraison par réconciliation : le moteur de déploiement de la plateforme |
| [16 DevSecOps](../16-devsecops/README.md) | Politiques, signature, secrets : les garde-fous de la plateforme |
| [13 IaC](../13-iac/README.md) et [14 Cloud AWS](../14-cloud-aws/README.md) (recommandés) | Provisionnement ; comparaison Terraform / Crossplane |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Introduction au Platform Engineering](cours/01-introduction-platform-engineering.md) | ⭐⭐ | Définition, DevOps / SRE / plateforme, plateforme **comme produit**, métriques d'adoption et de livraison |
| 2 | [La plateforme interne (IDP)](cours/02-internal-developer-platform.md) | ⭐⭐⭐ | Composants d'une IDP, construire / acheter / assembler, anti-patterns, plateforme minimale viable |
| 3 | [Backstage, le portail développeur](cours/03-backstage-portal.md) | ⭐⭐⭐ | Architecture, catalogue (entités, relations), scaffolder, TechDocs, plugins |
| 4 | [Crossplane, le plan de contrôle](cours/04-crossplane-control-plane.md) | ⭐⭐⭐⭐ | Providers, XRD, Compositions, composites, réconciliation, comparaison avec Terraform |
| 5 | [Golden paths et modèles](cours/05-golden-paths-et-templates.md) | ⭐⭐⭐⭐ | Chemin recommandé, modèles de service, scaffolding, garde-fous, libre-service |
| 6 | [Team Topologies, culture et DevEx](cours/06-team-topologies-et-culture.md) | ⭐⭐⭐ | Types d'équipes, modes d'interaction, charge cognitive, plateforme-produit, expérience développeur |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — Catalogue Backstage](ateliers-killercoda/atelier-01-backstage-catalogue/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 3 |
| [Atelier 02 — Premier composite Crossplane](ateliers-killercoda/atelier-02-crossplane-premier-composite/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 4, 5 |

Procédure de publication : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

> 💡 **Conseil** : l'atelier 2 utilise **`provider-kubernetes`** et non `provider-aws` : un provider cloud demande des identifiants et créerait de vraies ressources facturables, impossible sur Killercoda. Les mécanismes (XRD, Composition, composite, réconciliation) sont **les mêmes**. Les cours 1, 2, 5 et 6 sont **conceptuels** : ils se mettent en pratique dans votre organisation (entretiens avec les développeurs, première plateforme minimale).

## Parcours recommandé

```text
Cours 01 → Cours 02 → Cours 03 → Atelier 01 (Backstage)
        → Cours 04 → Atelier 02 (Crossplane)
        → Cours 05 → Cours 06
```

## Ce que vous saurez faire à la fin

- Expliquer le **Platform Engineering** et le situer par rapport à DevOps et au SRE ; défendre une **plateforme comme produit** avec des **métriques**.
- Décrire les **composants d'une IDP**, décider **construire / assembler / acheter** et éviter les **anti-patterns** (plateforme goulot).
- Décrire des services dans un **catalogue Backstage**, comprendre scaffolder, TechDocs et plugins.
- Définir une **API de plateforme** avec **Crossplane** (XRD, Composition) et la comparer à Terraform.
- Concevoir un **golden path** avec **garde-fous** et libre-service.
- Organiser des équipes avec **Team Topologies** et mesurer l'**expérience développeur**.

## Navigation

- [← Module 16 — DevSecOps](../16-devsecops/README.md)
- [→ Module 18 — FinOps](../18-finops/README.md) (module senior, facultatif) puis [Module 10 — Monitoring et observabilité](../10-monitoring-observabilite/README.md)
- [← README principal](../README.md)
