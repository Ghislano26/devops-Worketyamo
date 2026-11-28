# Bravo !

Vous avez fait un cycle complet **mesurer → rightsizer → vérifier** :

| Étape | Ce que vous avez vu |
|---|---|
| **Mesure** | Efficience CPU ≈ 0 % : on payait la **réservation**, pas l'usage |
| **Action** | `kubectl set resources` : requests ramenées près de l'usage (avec marge) |
| **Vérification** | CPU demandé et coût **en forte baisse**, application toujours disponible |
| **Limite** | La capacité libérée devient du **coût inactif** tant que les nœuds restent : il faut **consolider** |

## Défi bonus

1. **Garde-fous** : créez un `LimitRange` avec `defaultRequest` (cpu `50m`, memory `64Mi`) dans `finops-lab` et déployez un pod **sans** requests : observez les valeurs appliquées ([cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/04-rightsizing-et-optimisation.md)).
2. Ajoutez un `ResourceQuota` (`requests.cpu: 500m`) et tentez de dépasser : le déploiement est **refusé**.
3. Installez **Goldilocks** ou le **VPA** en mode `Off` et comparez ses recommandations avec les valeurs que vous avez choisies.
4. Écrivez une **politique Kyverno** qui **exige** `requests` et `limits` ([DevSecOps](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/04-policy-as-code-kubernetes.md)).
5. Agrégez `./couts.py 5m label:team` : le coût apparaît-il sous `demo` ? C'est le **showback par équipe** ([cours 2](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/02-tagging-et-showback.md)).

## Pour aller plus loin

- [Rightsizing et optimisation](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/04-rightsizing-et-optimisation.md) · [Culture FinOps et gouvernance](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/05-culture-finops-et-gouvernance.md).
- Retour au [module 18](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/README.md).
