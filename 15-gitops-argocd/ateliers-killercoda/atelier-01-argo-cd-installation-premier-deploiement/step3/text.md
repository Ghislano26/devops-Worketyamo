# Étape 3 : déployer une première Application

On déclare une **`Application`** qui pointe vers le dossier `guestbook` du dépôt d'exemples officiel d'Argo CD. L'`Application` est elle-même un **objet Kubernetes** (dans le namespace `argocd`) : c'est le principe GitOps appliqué à Argo CD lui-même.

```bash
cat > guestbook-app.yaml <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
EOF
kubectl apply -f guestbook-app.yaml
kubectl -n argocd get application guestbook
```{{exec}}

Sans `syncPolicy.automated`, la synchronisation est **manuelle** : l'application est **`OutOfSync`** (Argo CD a lu Git, mais n'a **rien appliqué**). Constatez-le, puis synchronisez :

```bash
argocd app get guestbook
argocd app diff guestbook | head -n 20
argocd app sync guestbook
argocd app wait guestbook --health --timeout 300
```{{exec}}

Vérifiez le résultat côté Kubernetes et côté Argo CD :

```bash
kubectl -n guestbook get deploy,svc,pods
kubectl -n argocd get application guestbook
argocd app get guestbook
```{{exec}}

Vous devez lire **`Synced`** et **`Healthy`**.

## Questions

- Quelle différence entre **Synced** et **Healthy** ? *(Synced : conforme à Git ; Healthy : les ressources fonctionnent.)*
- Que se passerait-il si vous modifiiez le Deployment à la main, sans `selfHeal` ? *(Argo CD le signalerait `OutOfSync` sans le corriger : c'est l'objet de l'[atelier 2](https://github.com/Ghislano26/devops-Worketyamo/tree/main/15-gitops-argocd/ateliers-killercoda/atelier-02-selfheal-et-prune).)*

Cliquez sur **Vérifier**.
