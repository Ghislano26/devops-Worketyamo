# Bravo !

Vous avez mis en place la visibilité des coûts dans Kubernetes :

| Notion | Ce que vous avez vu |
|---|---|
| **Architecture** | Prometheus (métriques) → OpenCost (modèle de coût) → API et interface |
| **Prix** | Tarifs personnalisés fictifs : comparables, pas une facture |
| **Allocation** | Coût par namespace, avec **demandé**, **utilisé** et **efficience** |
| **Coût inactif** | `__idle__` : la capacité payée mais non réservée |
| **Recommandation manuelle** | Déduite de l'efficience (Kubecost l'automatise) |

## Défi bonus

1. Agrégez **par label** : créez des pods avec un label `team` et lancez `./couts.py 30m label:team`. C'est la base du **showback** par équipe ([cours 2](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/02-tagging-et-showback.md)).
2. Interrogez l'API **assets** : `kubectl get --raw "/api/v1/namespaces/opencost/services/opencost:9003/proxy/assets?window=1d"` : nœuds et disques.
3. Dans Prometheus, cherchez les métriques d'OpenCost (`node_total_hourly_cost`, `container_cpu_allocation`) : c'est ce que **Grafana** utiliserait pour un tableau de bord par équipe.
4. Changez les prix dans `opencost-values.yaml` (CPU `0.05`), faites `helm upgrade` et observez l'effet sur les montants.

## Pour aller plus loin

- [OpenCost et Kubecost](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/03-kubecost-opencost.md) · [Étiquetage et showback](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/02-tagging-et-showback.md).
- Suite : [atelier 2 — rightsizing des requests](https://github.com/Ghislano26/devops-Worketyamo/tree/main/18-finops/ateliers-killercoda/atelier-02-rightsizing-requests).
