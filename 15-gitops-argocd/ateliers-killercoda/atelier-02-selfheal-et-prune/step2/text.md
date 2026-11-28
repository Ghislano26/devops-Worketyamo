# Étape 2 : supprimer une ressource dans Git et observer le prune

Le Deployment `legacy` n'a plus d'utilité. **Dans un workflow GitOps, on le supprime de Git**, pas du cluster : c'est `prune` qui s'occupe du reste.

```bash
kubectl -n demo get deploy
cd ~/gitops-repo
git rm -q apps/web/legacy.yaml
git commit -qm "Retrait de legacy"
git push -q origin main
git log --oneline
```{{exec}}

Argo CD interroge Git toutes les **30 secondes** (réglage de l'atelier). Pour ne pas attendre, demandez un **rafraîchissement immédiat**, puis observez :

```bash
kubectl -n argocd annotate application web argocd.argoproj.io/refresh=hard --overwrite
sleep 15
kubectl -n argocd get application web
kubectl -n demo get deploy
```{{exec}}

Le Deployment `legacy` **disparaît** du cluster, et `web` reste intact.

## Que serait-il arrivé sans `prune` ?

Essayons : on **désactive** `prune`, on remet une ressource dans Git, on la retire, et on regarde.

```bash
kubectl -n argocd patch application web --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":false}}}}'
cd ~/gitops-repo
git show HEAD~1:apps/web/legacy.yaml > apps/web/legacy.yaml
git add . && git commit -qm "Retour de legacy (test)" && git push -q origin main
kubectl -n argocd annotate application web argocd.argoproj.io/refresh=hard --overwrite
sleep 20
kubectl -n demo get deploy
git rm -q apps/web/legacy.yaml && git commit -qm "Retrait de legacy (sans prune)" && git push -q origin main
kubectl -n argocd annotate application web argocd.argoproj.io/refresh=hard --overwrite
sleep 20
kubectl -n argocd get application web
kubectl -n demo get deploy
```{{exec}}

Sans `prune`, `legacy` **reste dans le cluster** alors qu'il n'est plus dans Git, et l'application est signalée **`OutOfSync`** : Argo CD vous prévient sans rien supprimer. **Réactivez `prune`** pour finir :

```bash
kubectl -n argocd patch application web --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true}}}}'
kubectl -n argocd annotate application web argocd.argoproj.io/refresh=hard --overwrite
sleep 20
kubectl -n demo get deploy
kubectl -n argocd get application web
```{{exec}}

> ⚠️ **Attention** : `prune` est puissant. Un mauvais `path` ou un dépôt vide peut supprimer **beaucoup** de ressources. Sur des données (PVC), ajoutez l'annotation `argocd.argoproj.io/sync-options: Prune=false` ([cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/03-application-et-sync-policies.md)).

## Questions

- Pourquoi l'état « sans prune » est-il **`OutOfSync`** et non `Synced` ? *(Le cluster contient une ressource que Git ne décrit plus.)*
- Quelle protection d'Argo CD empêche un `prune` total quand Git renvoie zéro ressource ? *(`allowEmpty: false`, valeur par défaut.)*

Cliquez sur **Vérifier**.
