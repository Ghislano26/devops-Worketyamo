# Argo CD : self-heal et prune

**Durée : ~25 minutes.** Compétence travaillée : activer la synchronisation **automatique** avec **`selfHeal`** et **`prune`**, et **observer** Argo CD annuler une modification manuelle puis supprimer une ressource retirée de Git.

Rappel du [cours Application et sync policies](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/03-application-et-sync-policies.md) :

```text
selfHeal : on modifie le cluster à la main  → Argo CD revient à l'état de Git
prune    : on retire une ressource de Git   → Argo CD la supprime du cluster
```

Pour pouvoir **modifier Git** pendant l'atelier (impossible sur un dépôt GitHub public), on monte un **petit serveur Git local** dans le cluster : un dépôt « nu » sur le disque du nœud, servi en HTTP par un pod nginx. Pour Argo CD, c'est un dépôt Git comme un autre.

## Mise en place : installer Argo CD

Le bloc réduit aussi le délai de détection de Git à **30 secondes** (3 minutes par défaut) pour accélérer l'atelier.

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.3/manifests/install.yaml
for d in argocd-server argocd-repo-server argocd-redis argocd-applicationset-controller; do
  kubectl -n argocd rollout status deployment/$d --timeout=300s
done
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
kubectl -n argocd get pods
kubectl -n argocd patch configmap argocd-cm --type merge -p '{"data":{"timeout.reconciliation":"30s"}}'
kubectl -n argocd rollout restart statefulset/argocd-application-controller
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
```{{exec}}

> 🌐 **Réseau** : le scénario télécharge les manifestes d'Argo CD depuis GitHub et plusieurs images (`quay.io`, `ghcr.io`, registre public Redis). Comptez **2 à 4 minutes** pour l'installation au premier lancement.
