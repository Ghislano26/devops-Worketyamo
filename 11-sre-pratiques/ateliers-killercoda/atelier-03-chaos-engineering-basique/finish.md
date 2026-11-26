# Bravo !

Vous avez mené une expérience de chaos complète :

| Étape | Ce que vous avez fait |
|---|---|
| État stable | 3 pods Ready, Service qui répond |
| Hypothèse | Écrite **avant** l'injection |
| Injection | Suppression d'un pod (puis latence `tc netem`) |
| Observation | Réparation automatique par le ReplicaSet, évènements, sonde |
| Retour arrière | Retrait de la perturbation, 3 réplicas rétablis |

Leçon fréquente : même une panne « simple » révèle des détails (pod en `Terminating` encore joignable, latence de queue). C'est exactement ce que le chaos cherche.

## Défi bonus : refaire l'expérience avec Chaos Mesh

1. Installez Chaos Mesh :

```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org && helm repo update
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --create-namespace \
  --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock
```{{copy}}

2. Écrivez un manifeste `PodChaos` (`action: pod-kill`, `mode: one`, `selector` sur `app=web`) et appliquez-le.
3. Ajoutez un `NetworkChaos` de **latence** de 200 ms et comparez avec votre injection manuelle.
4. Planifiez l'expérience avec un `Schedule`, et définissez une **condition d'arrêt** (supprimez l'expérience si l'erreur dépasse 2 %).

## Pour aller plus loin

- [Chaos engineering](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/06-chaos-engineering.md) · [Patterns de fiabilité](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/07-patterns-fiabilite.md) · [Kubernetes : pods et workloads](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/02-pods-et-workloads.md).
- Organisez un **game day** avec votre équipe à partir d'un postmortem passé.
- Retour au [module 11](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/README.md).
