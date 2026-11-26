# Étape 2 : passer à un Deployment

Un **Deployment** gère des **ReplicaSets**, qui gèrent des **Pods** : il les recrée s'ils disparaissent et permet les mises à jour progressives.

Supprimez d'abord le pod isolé, puis créez le Deployment **`web`** avec **3 réplicas** :

```bash
kubectl delete pod nginx
kubectl create deployment web --image=nginx:1.27 --replicas=3
```{{exec}}

Attendez que les réplicas soient disponibles, puis observez la hiérarchie :

```bash
kubectl rollout status deployment/web
kubectl get deployment,replicaset,pods -l app=web
```{{exec}}

Remarquez les noms : `web-<hash du ReplicaSet>-<suffixe aléatoire du pod>`.

## Auto-réparation

Supprimez un pod du Deployment et regardez le ReplicaSet le **recréer** immédiatement :

```bash
kubectl delete pod $(kubectl get pods -l app=web -o name | head -n 1)
kubectl get pods -l app=web
```{{exec}}

Repérez l'**âge** (AGE) des pods : l'un est tout neuf. Voici la **boucle de réconciliation** : état désiré (3 réplicas) contre état réel (2) → création d'un pod.

Examinez le ReplicaSet et le Deployment en YAML :

```bash
kubectl get deployment web -o yaml | grep -E "replicas|strategy|maxSurge|maxUnavailable|type:" 
kubectl get rs -l app=web
```{{exec}}

Cliquez sur **Vérifier** quand les 3 réplicas sont disponibles.
