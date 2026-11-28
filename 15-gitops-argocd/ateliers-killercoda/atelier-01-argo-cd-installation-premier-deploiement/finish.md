# Bravo !

Vous avez installé et utilisé Argo CD de bout en bout :

| Étape | Ce que vous avez fait |
|---|---|
| Installation | Manifestes **épinglés**, `--server-side`, composants et CRD |
| Accès | Mot de passe initial, **port-forward**, CLI `argocd` |
| Application | Objet **`Application`** : source Git, destination, synchronisation **manuelle** |
| Statuts | **Synced** (conforme à Git) et **Healthy** (fonctionne) |

## Défi bonus

1. Dans l'interface web, ouvrez l'application `guestbook` et observez l'**arbre de ressources** (Deployment, ReplicaSet, Pod, Service).
2. Ajoutez `syncPolicy.automated: {}` à l'application et relancez `kubectl apply` : que change-t-il à l'état de l'application ?
3. Déployez de la même façon `helm-guestbook` ou `kustomize-guestbook` du même dépôt : Argo CD détecte **Helm** ou **Kustomize** tout seul ([cours 5](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/05-kustomize-et-helm-avec-argo.md)).
4. Supprimez l'`Application` : ses ressources restent-elles ? *(Sans finalizer `resources-finalizer`, oui.)* Voir le [cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/03-application-et-sync-policies.md).

## Pour aller plus loin

- [Principes GitOps avancés](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/01-principes-gitops-avances.md) · [Architecture d'Argo CD](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/02-argo-cd-architecture.md) · [GitOps du module 12](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/08-gitops-et-deploiement-declaratif.md).
- Suite : [atelier 2 — self-heal et prune](https://github.com/Ghislano26/devops-Worketyamo/tree/main/15-gitops-argocd/ateliers-killercoda/atelier-02-selfheal-et-prune).
