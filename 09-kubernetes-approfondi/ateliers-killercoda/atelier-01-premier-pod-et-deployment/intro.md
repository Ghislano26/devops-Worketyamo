# Premier Pod et Deployment

Dans cet atelier, vous allez découvrir les objets de base de Kubernetes sur un **vrai cluster** (un nœud kubeadm, prêt à l'emploi) :

1. lancer un **Pod** et lire ses évènements ;
2. créer un **Deployment** de 3 réplicas et observer l'auto-réparation ;
3. **scaler**, **mettre à jour** l'image avec une mise à jour progressive, consulter l'**historique** et faire un **rollback**.

Cet atelier met en pratique les cours [Architecture et composants](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/01-architecture-et-composants.md) et [Pods et workloads](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/02-pods-et-workloads.md).

## Vérifions le cluster

```bash
kubectl get nodes
```{{exec}}

Le nœud doit être `Ready`. Regardez aussi les composants du control plane qui tournent en pods dans `kube-system` :

```bash
kubectl get pods -n kube-system
```{{exec}}

```bash
kubectl cluster-info
kubectl version
```{{exec}}

> Patientez quelques instants si le cluster est encore en cours de démarrage : relancez `kubectl get nodes` jusqu'à voir `Ready`.
