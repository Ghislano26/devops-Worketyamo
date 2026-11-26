# Étape 3 : scale, rollout et rollback

## 1. Mettre à l'échelle

```bash
kubectl scale deployment web --replicas=5
kubectl rollout status deployment/web
kubectl get pods -l app=web
```{{exec}}

Changer `replicas` **ne crée pas de nouvelle révision** : seule une modification du modèle de pod (`spec.template`) en crée une.

## 2. Mise à jour progressive vers nginx:alpine

Annotez le changement (il apparaîtra dans l'historique), puis changez l'image :

```bash
kubectl annotate deployment/web kubernetes.io/change-cause="passage à nginx:alpine" --overwrite
kubectl set image deployment/web nginx=nginx:alpine
```{{exec}}

Observez le **RollingUpdate** : un nouveau ReplicaSet monte pendant que l'ancien descend (`maxSurge` / `maxUnavailable`, voir le [cours 02](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/02-pods-et-workloads.md)).

```bash
kubectl rollout status deployment/web
kubectl get rs -l app=web
kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```{{exec}}

## 3. Historique

```bash
kubectl rollout history deployment/web
kubectl rollout history deployment/web --revision=2
```{{exec}}

## 4. Retour arrière (rollback)

Imaginons que `nginx:alpine` pose problème : revenez à la révision précédente.

```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl rollout history deployment/web
kubectl get rs -l app=web
```{{exec}}

L'image doit être revenue à `nginx:1.27`. Notez que l'**ancien ReplicaSet** a simplement été **remonté** : c'est pourquoi le rollback est quasi instantané.

## Questions

- Pourquoi l'historique contient-il maintenant les révisions 2 et 3, et plus la 1 ? (Le rollback **réutilise** le modèle de la révision 1 en la renumérotant.)
- Que se passe-t-il si vous définissez une `readinessProbe` ? Le rollout attend que chaque nouveau pod soit **prêt** avant de continuer.

Cliquez sur **Vérifier** : 5 réplicas disponibles, au moins deux révisions dans l'historique et l'image revenue à `nginx:1.27`.
