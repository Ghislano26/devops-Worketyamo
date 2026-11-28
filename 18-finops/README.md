# Module 18 — FinOps (OpenCost, rightsizing, gouvernance)

> 🎓 **Module senior.** Ce module s'adresse à des profils **DevOps et Platform Engineers confirmés** qui doivent **comprendre, répartir et réduire les coûts cloud**. Il est **facultatif** dans un premier parcours : on peut passer directement du module 16 (ou 17) au Monitoring (10) et au SRE (11).

## Pourquoi ce module ?

Dans le cloud, **chaque déploiement est une dépense** : un cluster surdimensionné, des `requests` Kubernetes trop généreuses, un volume oublié ou un transfert inter-régions suffisent à alourdir la facture sans que personne ne le voie. Le **FinOps** rapproche **ingénierie, finance et produit** pour **voir** les coûts, les **optimiser** et les **piloter** durablement, sans freiner la livraison. Le [cours FinOps du module AWS](../14-cloud-aws/cours/06-aws-couts-finops-intro.md) en a posé les bases ; ce module les **approfondit**, en particulier pour **Kubernetes** : allocation des coûts par équipe, **OpenCost**, **rightsizing** des requests, autoscaling, Spot, engagements, **gouvernance** et culture.

> 🗺️ **Place dans le parcours.** Ce module porte le **numéro 18** mais se lit **après la plateforme (17)** et **avant le Monitoring (10) et le SRE (11)** : on livre (12), on provisionne (13, 14), on déploie (15), on sécurise (16), on en fait une plateforme (17), **on maîtrise ses coûts (18)**, puis on observe (10) et on fiabilise (11). La numérotation des dossiers est gelée ; l'ordre pédagogique est expliqué dans le [README principal](../README.md).
>
> ℹ️ **À propos du module 10 (Monitoring).** Il figure dans les prérequis car OpenCost repose sur **Prometheus**. Par commodité de parcours, ce module est placé *avant* le 10 : **les ateliers installent eux-mêmes Prometheus**, ce qui permet de les suivre sans avoir lu le module 10. Si vous découvrez Prometheus, lisez le [module Monitoring](../10-monitoring-observabilite/README.md) **en parallèle** (au minimum ses cours sur les métriques et PromQL).

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [09 Kubernetes](../09-kubernetes-approfondi/README.md) | Requests, limits, namespaces, HPA : le vocabulaire du coût Kubernetes |
| [14 Cloud AWS](../14-cloud-aws/README.md) | Tarification, étiquettes, Savings Plans, Spot ([cours coûts](../14-cloud-aws/cours/06-aws-couts-finops-intro.md)) |
| [10 Monitoring](../10-monitoring-observabilite/README.md) (recommandé) | Prometheus : la source des données d'OpenCost (installé par les ateliers) |
| [17 Platform Engineering](../17-platform-engineering/README.md) (recommandé) | Plateforme interne, golden paths et garde-fous : où s'ancre le FinOps |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Introduction au FinOps](cours/01-introduction-finops.md) | ⭐⭐ | Définition, principes, phases Inform / Optimize / Operate, économie unitaire, cloud contre sur site, FOCUS |
| 2 | [Étiquetage, allocation et showback](cours/02-tagging-et-showback.md) | ⭐⭐⭐ | Stratégie d'étiquettes, Tag Policies / Azure Policy, coûts partagés, showback vs chargeback, budgets |
| 3 | [OpenCost et Kubecost](cours/03-kubecost-opencost.md) | ⭐⭐⭐⭐ | Modèle de coût Kubernetes (`max(demandé, utilisé)`), architecture, allocation, efficience, coût inactif |
| 4 | [Rightsizing et optimisation](cours/04-rightsizing-et-optimisation.md) | ⭐⭐⭐⭐ | Requests / limits, VPA, HPA, Karpenter, bin packing, Spot, Savings Plans, ordre des optimisations |
| 5 | [Culture FinOps et gouvernance](cours/05-culture-finops-et-gouvernance.md) | ⭐⭐⭐ | Rôles, gouvernance, budgets et alertes, formation, KPI (coût par transaction), reporting |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — Installer OpenCost](ateliers-killercoda/atelier-01-opencost-installation/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 3 |
| [Atelier 02 — Rightsizing des requests](ateliers-killercoda/atelier-02-rightsizing-requests/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 3, 4 |

Procédure de publication : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

> 💡 **Conseil** : les ateliers utilisent des **prix fictifs** (pas de compte cloud) : les montants sont **proportionnels et comparables**, mais **ne correspondent à aucune facture**. Les cours 1, 2 et 5 sont conceptuels : ils se mettent en pratique dans votre organisation (premier showback, premier budget, premier KPI de coût unitaire).

## Parcours recommandé

```text
Cours 01 → Cours 02 → Cours 03 → Atelier 01 (OpenCost)
        → Cours 04 → Atelier 02 (rightsizing)
        → Cours 05
```

## Ce que vous saurez faire à la fin

- Expliquer le **FinOps** (principes, cycle, économie unitaire) et le défendre auprès de la finance comme de l'ingénierie.
- Définir une **stratégie d'étiquetage** imposée par le code et les politiques, et mettre en place un **showback**.
- Installer **OpenCost**, lire l'allocation par namespace / pod / label, l'**efficience** et le **coût inactif**.
- **Rightsizer** des requests par paliers, choisir entre HPA, VPA, Karpenter, **Spot** et **engagements** dans le bon ordre.
- Instaurer une **gouvernance** (budgets, alertes, quotas, exceptions) et des **KPI** (coût par transaction, % alloué, efficience).

## Navigation

- [← Module 17 — Platform Engineering](../17-platform-engineering/README.md)
- [→ Module 10 — Monitoring et observabilité](../10-monitoring-observabilite/README.md) (étape suivante du parcours)
- [← README principal](../README.md)
