# Étape 1 : lancer un Pod nginx

Un **Pod** est l'unité de base de Kubernetes ([cours 02](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/02-pods-et-workloads.md)). Lancez-en un nommé **`nginx`** :

```bash
kubectl run nginx --image=nginx:1.27
```{{exec}}

Suivez son démarrage jusqu'à l'état **Running** (Ctrl+C pour quitter la surveillance) :

```bash
kubectl get pod nginx -w
```{{exec}}

Affichez les détails : nœud choisi par le scheduler, IP du pod, et surtout la section **Events** (la chronologie : `Scheduled` → `Pulling` → `Pulled` → `Created` → `Started`).

```bash
kubectl describe pod nginx
```{{exec}}

```bash
kubectl get pod nginx -o wide
kubectl logs nginx
```{{exec}}

## Questions

- Quel composant a écrit `Scheduled` ? Et `Pulled` / `Started` ? (scheduler, puis kubelet : voir le [cours 01](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/01-architecture-et-composants.md).)
- Que se passe-t-il si vous supprimez ce pod (`kubectl delete pod nginx`) ? Il **disparaît pour de bon** : aucun contrôleur ne le recrée. C'est pourquoi on utilise des Deployments.

> Ne supprimez pas le pod pour l'instant : cliquez sur **Vérifier**.
