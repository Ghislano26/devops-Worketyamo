# Étape 1 : un ApplicationSet avec le générateur List

Le générateur **`list`** fournit trois jeux de paramètres (`env`, `replicas`). Le **gabarit** les utilise pour fabriquer **une `Application` par environnement**, à partir du chart `helm-guestbook` du dépôt d'exemples officiel. Les réplicas sont passés comme **paramètre Helm**.

```bash
cat > applicationset.yaml <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - env: dev
            replicas: "1"
          - env: staging
            replicas: "2"
          - env: prod
            replicas: "3"
  template:
    metadata:
      name: 'guestbook-{{env}}'
      labels:
        env: '{{env}}'
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: helm-guestbook
        helm:
          releaseName: guestbook
          parameters:
            - name: replicaCount
              value: '{{replicas}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'guestbook-{{env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF
kubectl apply -f applicationset.yaml
sleep 15
kubectl -n argocd get applicationset
kubectl -n argocd get applications
```{{exec}}

Attendez que les **trois** applications soient **Synced / Healthy** (une à deux minutes : chaque chart est rendu puis l'image est téléchargée) :

```bash
kubectl -n argocd get applications -w
```{{exec}}

*(Quittez avec Ctrl+C quand les trois sont `Synced` et `Healthy`.)*

Vérifiez les **trois namespaces** et le nombre de réplicas de chaque environnement :

```bash
kubectl get namespaces | grep guestbook
for e in dev staging prod; do
  echo "== $e"; kubectl -n guestbook-$e get deploy,svc
done
```{{exec}}

Les réplicas diffèrent : **1** en dev, **2** en staging, **3** en prod, alors qu'**un seul fichier** les décrit.

## Questions

- Qui est **propriétaire** des trois `Application` ? *(L'`ApplicationSet` : `kubectl -n argocd get application guestbook-dev -o jsonpath='{.metadata.ownerReferences[0].kind}'`.)*
- Que se passe-t-il si vous supprimez l'élément `staging` de la liste ? *(L'`Application` `guestbook-staging` est supprimée ; avec le finalizer, ses ressources aussi.)*

Cliquez sur **Vérifier**.
