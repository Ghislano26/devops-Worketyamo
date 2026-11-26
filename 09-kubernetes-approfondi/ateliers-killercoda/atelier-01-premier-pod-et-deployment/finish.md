# Bravo !

Vous avez :

- lancé un **Pod** et lu sa chronologie (`describe`, évènements) ;
- constaté que le **Deployment** et son **ReplicaSet** recréent les pods supprimés (boucle de réconciliation) ;
- **scalé**, mis à jour l'image par **RollingUpdate** et **annulé** la mise à jour avec `rollout undo`.

## Nettoyage

```bash
kubectl delete deployment web
```{{exec}}

## Pour aller plus loin

- Ajoutez une `readinessProbe` et une stratégie `maxUnavailable: 0`, puis relancez un rollout.
- Essayez `strategy: Recreate` et observez la coupure.
- Cassez volontairement une mise à jour (`kubectl set image deployment/web nginx=nginx:inexistant`), observez `ImagePullBackOff` et le rollout bloqué, puis `rollout undo`.
- Continuez avec l'[atelier 2 : Service et NodePort](https://github.com/Ghislano26/devops-Worketyamo/tree/main/09-kubernetes-approfondi/ateliers-killercoda/atelier-02-service-et-nodeport).
