# Argo CD : ApplicationSet multi-environnements

**Durée : ~25 minutes.** Compétence travaillée : générer **plusieurs `Application`** (dev, staging, prod) à partir d'**un seul `ApplicationSet`** avec le générateur **List**, et constater que chaque environnement a son **namespace** et sa configuration.

Rappel du [cours ApplicationSets](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/04-applicationsets-multi-env.md) :

```text
ApplicationSet = générateur (liste d'environnements) + gabarit d'Application
        ├─► Application guestbook-dev      → namespace guestbook-dev      (1 réplica)
        ├─► Application guestbook-staging  → namespace guestbook-staging  (2 réplicas)
        └─► Application guestbook-prod     → namespace guestbook-prod     (3 réplicas)
```

Les trois environnements s'exécutent ici sur **le même cluster** (un namespace chacun) : c'est la manière la plus simple de pratiquer ; en vrai, la production serait un autre cluster (`destination.server` différent).

## Mise en place : installer Argo CD

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

> 🌐 **Réseau** : le scénario télécharge les manifestes d'Argo CD depuis GitHub et plusieurs images (`quay.io`, `ghcr.io`, registre public Redis). Comptez **2 à 4 minutes** pour l'installation au premier lancement.
