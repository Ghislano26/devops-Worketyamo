# Service ClusterIP et NodePort

Les pods sont éphémères : leur IP change à chaque recréation. Un **Service** donne une adresse et un nom **stables** et répartit le trafic entre les pods prêts.

Dans cet atelier, vous allez :

1. déployer nginx et l'exposer par un Service **ClusterIP**, puis le tester depuis un **pod busybox temporaire** (DNS interne) ;
2. l'ouvrir vers l'extérieur avec un **NodePort**.

Rappel du [cours Services et réseau](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/03-services-et-reseau-kubernetes.md) :

| Type | Accessible depuis |
|---|---|
| **ClusterIP** | l'intérieur du cluster |
| **NodePort** | `IP-du-nœud:30000-32767` |
| **LoadBalancer** | une IP publique fournie par le cloud |
| **ExternalName** | alias DNS vers un nom externe |

Vérifions le cluster :

```bash
kubectl get nodes
```{{exec}}
