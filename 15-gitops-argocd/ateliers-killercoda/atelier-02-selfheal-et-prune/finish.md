# Bravo !

Vous avez vu les deux réflexes qui font la différence entre « Git décrit » et « Git gouverne » :

| Option | Ce que vous avez observé |
|---|---|
| **`selfHeal`** | Un `kubectl scale` manuel est **annulé** : le cluster revient à Git |
| **`prune`** | Une ressource **retirée de Git** est **supprimée** du cluster |
| **Sans `prune`** | La ressource reste, l'application devient `OutOfSync` : Argo CD **signale** sans supprimer |
| **Git local** | Un dépôt HTTP « simple » suffit à Argo CD (hook `update-server-info`) |

## Défi bonus

1. Ajoutez un **HPA** sur `web` : observez le combat avec `selfHeal`, puis résolvez-le avec `ignoreDifferences` sur `/spec/replicas` et `RespectIgnoreDifferences=true` ([cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/03-application-et-sync-policies.md)).
2. Modifiez `replicas: 3` **dans Git** : combien de temps avant que le cluster suive ? Comparez avec un rafraîchissement forcé.
3. Annotez le Service `web` avec `argocd.argoproj.io/sync-options: Prune=false`, retirez-le de Git : que se passe-t-il ?
4. Faites un `git revert` du commit de retrait de `legacy` : le Deployment **réapparaît**. C'est le retour arrière GitOps.

## Pour aller plus loin

- [Application et sync policies](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/03-application-et-sync-policies.md) · [Principes GitOps avancés](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/01-principes-gitops-avances.md).
- Suite : [atelier 3 — ApplicationSet multi-environnements](https://github.com/Ghislano26/devops-Worketyamo/tree/main/15-gitops-argocd/ateliers-killercoda/atelier-03-applicationset-multi-env).
