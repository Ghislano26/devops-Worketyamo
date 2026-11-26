# Bravo !

Vous avez :

- créé un Service **ClusterIP** et vérifié que ses **endpoints** sont les pods du Deployment ;
- utilisé le **DNS du cluster** (`web` → `web.default.svc.cluster.local`) depuis un pod temporaire ;
- exposé le Service avec un **NodePort** et testé depuis le nœud.

## Nettoyage

```bash
kubectl delete svc web && kubectl delete deployment web
```{{exec}}

## Pour aller plus loin

- Changez volontairement le label du Service (`kubectl patch svc web -p '{"spec":{"selector":{"app":"autre"}}}'`) et constatez que les **endpoints** deviennent vides.
- Créez un **Service headless** (`clusterIP: None`) et comparez `nslookup`.
- Installez un Ingress controller (`ingress-nginx`) et routez par nom d'hôte.
- Passez à l'[atelier 3 : ConfigMap, Secret et RBAC](https://github.com/Ghislano26/devops-Worketyamo/tree/main/09-kubernetes-approfondi/ateliers-killercoda/atelier-03-configmap-secret-et-rbac).
