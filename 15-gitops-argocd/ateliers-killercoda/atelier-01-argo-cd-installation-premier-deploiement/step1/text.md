# Étape 1 : installer Argo CD avec les manifestes officiels

On crée un namespace dédié puis on applique le manifeste **d'une version épinglée** (`v2.13.3`). L'option **`--server-side`** est indispensable : le CRD `ApplicationSet` est trop gros pour l'annotation de `kubectl apply` classique.

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.3/manifests/install.yaml
for d in argocd-server argocd-repo-server argocd-redis argocd-applicationset-controller; do
  kubectl -n argocd rollout status deployment/$d --timeout=300s
done
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
kubectl -n argocd get pods
```{{exec}}

> Si vous voyez `metadata.annotations: Too long` : vous avez oublié `--server-side`. Pour recommencer proprement : `kubectl delete namespace argocd`, puis relancez le bloc.

Observez ce que l'installation a créé : les **composants** du cours (server, repo-server, application-controller, redis, dex…) et les **CRD** `Application`, `ApplicationSet`, `AppProject` :

```bash
kubectl -n argocd get deploy,statefulset,svc
kubectl get crd | grep argoproj
```{{exec}}

## Questions

- Pourquoi l'**application-controller** est-il un `StatefulSet` et le **repo-server** un `Deployment` ? *(Le contrôleur est le seul à comparer et synchroniser, avec sharding par cluster ; le repo-server est sans état.)*
- Où Argo CD stocke-t-il l'état de ses applications ? *(Dans des **CRD** Kubernetes ; Redis n'est qu'un cache.)*

Cliquez sur **Vérifier**.
