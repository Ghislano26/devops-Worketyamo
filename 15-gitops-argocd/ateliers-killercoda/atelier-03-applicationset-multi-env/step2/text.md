# Étape 2 : ajouter un environnement, constater la propriété

## A. Ajouter `qa` à la liste

Ajouter un environnement = **ajouter un élément** dans le générateur. On réapplique l'`ApplicationSet` avec un 4ᵉ élément :

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
          - env: qa
            replicas: "1"
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
sleep 20
kubectl -n argocd get applications
```{{exec}}

Une 4ᵉ `Application`, **`guestbook-qa`**, est apparue, avec son namespace `guestbook-qa` : aucun YAML d'`Application` n'a été écrit pour elle.

## B. L'ApplicationSet reste propriétaire

Supprimez à la main l'`Application` `guestbook-dev` : l'`ApplicationSet` la **recrée**.

```bash
kubectl -n argocd delete application guestbook-dev --wait=true
sleep 20
kubectl -n argocd get applications
kubectl -n argocd get application guestbook-dev -o jsonpath='{.metadata.creationTimestamp}{"\n"}'
```{{exec}}

*(Le finalizer a aussi supprimé les ressources de dev ; l'application recréée les redéploie.)* Attendez de nouveau que les **quatre** applications soient `Synced` et `Healthy` :

```bash
kubectl -n argocd get applications -w
```{{exec}}

*(Ctrl+C pour quitter.)* Puis vérifiez les quatre namespaces :

```bash
kubectl get namespaces | grep guestbook
```{{exec}}

## Questions

- Pourquoi l'`Application` supprimée à la main revient-elle ? *(L'`ApplicationSet` réconcilie ses `Application` comme un contrôleur réconcilie ses objets.)*
- Quel risque comporte un générateur qui **s'élargit** tout seul (dossier Git, nouveau cluster) ? *(Création immédiate d'applications, éventuellement en `automated` + `prune` : voir le [cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/04-applicationsets-multi-env.md).)*

Cliquez sur **Vérifier**.
