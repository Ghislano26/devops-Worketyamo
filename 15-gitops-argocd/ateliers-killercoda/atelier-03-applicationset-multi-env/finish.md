# Bravo !

Vous avez remplacé trois (puis quatre) `Application` écrites à la main par **un seul objet** :

| Notion | Ce que vous avez vu |
|---|---|
| **Générateur List** | Des éléments (`env`, `replicas`) fournis **en dur** |
| **Gabarit** | Un modèle d'`Application` avec `{{env}}` et `{{replicas}}` |
| **Propriété** | L'`ApplicationSet` crée, met à jour, **recrée** et supprime ses `Application` |
| **Multi-environnement** | Un namespace et une configuration par environnement, une seule source de description |

## Défi bonus

1. Remplacez le générateur List par un générateur **Git `directories`** (un dossier par environnement dans un dépôt) : voir le [cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/04-applicationsets-multi-env.md).
2. Passez en **`goTemplate: true`** avec `missingkey=error` : que se passe-t-il si vous faites une faute dans `{{ .env }}` ?
3. Désactivez `automated` pour la production seule (indice : un paramètre `auto` dans la liste et un `goTemplate` conditionnel, ou deux ApplicationSets).
4. Ajoutez `preserveResourcesOnDeletion: true` dans `spec` : supprimer un élément ne supprime plus les ressources déployées.

## Pour aller plus loin

- [ApplicationSets et multi-environnements](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/04-applicationsets-multi-env.md) · [Kustomize et Helm avec Argo CD](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/05-kustomize-et-helm-avec-argo.md).
- Retour au [module 15](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/README.md).
