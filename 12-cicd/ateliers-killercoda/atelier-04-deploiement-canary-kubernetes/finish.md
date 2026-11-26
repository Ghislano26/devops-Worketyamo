# Bravo !

Vous avez réalisé un déploiement progressif complet :

| Étape | Ce que vous avez fait |
|---|---|
| Canari | 1 pod v2 à côté de 4 pods v1, derrière le même Service |
| Mesure | Répartition observée avec l'en-tête `Server` |
| Palier | 50 % de trafic sur la v2 |
| Promotion | 4 pods v2, v1 réduit à 0 |
| Rollback (prévu) | `kubectl scale deployment app-v2 --replicas=0` |

## Défi bonus : automatiser la décision

1. Installez **Argo Rollouts** et convertissez `app-v1`/`app-v2` en un seul objet `Rollout` avec des paliers `setWeight: 20` → `50` → `100` et des `pause`.
2. Ajoutez une analyse automatique (`AnalysisTemplate`) qui interroge **Prometheus** (taux d'erreur < 1 %) et annule si le seuil est dépassé : voir le [module Monitoring](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/README.md).
3. Déclarez le tout dans un dépôt Git et synchronisez-le avec **Argo CD** ([cours 8, GitOps](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/08-gitops-et-deploiement-declaratif.md)).

## Pour aller plus loin

- [Stratégies de déploiement](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/07-strategies-de-deploiement.md) · [GitOps et déploiement déclaratif](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/08-gitops-et-deploiement-declaratif.md).
- Retour au [module 12](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/README.md).
