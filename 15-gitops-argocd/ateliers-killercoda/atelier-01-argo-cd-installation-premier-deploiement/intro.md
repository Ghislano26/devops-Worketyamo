# Argo CD : installation et premier déploiement

**Durée : ~25 minutes.** Compétence travaillée : **installer Argo CD** avec les manifestes officiels, se connecter (mot de passe, port-forward, CLI) et **déployer une première `Application`** depuis un dépôt Git public.

Rappel du [cours Architecture d'Argo CD](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/02-argo-cd-architecture.md) et du [cours Application et sync policies](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/03-application-et-sync-policies.md) :

```text
Dépôt Git public (argoproj/argocd-example-apps, dossier guestbook)
        │  clone + rendu (repo-server)
        ▼
Argo CD (application-controller) ── compare ──► Cluster (namespace guestbook)
        └─ statut attendu : Synced + Healthy
```

Cet atelier s'exécute sur un **cluster Kubernetes déjà prêt** (un nœud). Vérifions-le :

```bash
kubectl get nodes
```{{exec}}

Le nœud doit être `Ready`.

> 🌐 **Réseau** : le scénario télécharge les manifestes d'Argo CD depuis GitHub et plusieurs images (`quay.io`, `ghcr.io`, registre public Redis). Comptez **2 à 4 minutes** pour l'installation au premier lancement.
