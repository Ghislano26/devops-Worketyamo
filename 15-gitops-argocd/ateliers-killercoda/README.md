# Ateliers Killercoda — GitOps avec Argo CD

Trois scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** avec le backend **`kubernetes-kubeadm-1node`** : un **cluster Kubernetes d'un nœud, déjà prêt**. **Argo CD est installé par chaque scénario** (manifestes officiels, version épinglée `v2.13.3`).

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-argo-cd-installation-premier-deploiement`](atelier-01-argo-cd-installation-premier-deploiement/) | `kubernetes-kubeadm-1node` | ~25 min | ⭐⭐⭐ | Installation (`--server-side`), mot de passe admin, port-forward, CLI `argocd`, `Application`, Synced + Healthy | [1](../cours/01-principes-gitops-avances.md), [2](../cours/02-argo-cd-architecture.md) |
| [`atelier-02-selfheal-et-prune`](atelier-02-selfheal-et-prune/) | `kubernetes-kubeadm-1node` | ~25 min | ⭐⭐⭐ | `automated`, **`selfHeal`** (scale manuel annulé), **`prune`** (ressource retirée de Git), serveur Git local | [3](../cours/03-application-et-sync-policies.md) |
| [`atelier-03-applicationset-multi-env`](atelier-03-applicationset-multi-env/) | `kubernetes-kubeadm-1node` | ~25 min | ⭐⭐⭐⭐ | `ApplicationSet`, générateur **List**, dev/staging/prod, propriété des `Application` | [4](../cours/04-applicationsets-multi-env.md), [5](../cours/05-kustomize-et-helm-avec-argo.md) |

**Lisez le cours associé avant chaque atelier.** Les cours 6 (secrets) et 7 (Flux) ne sont pas pratiqués ici : ils demandent un coffre, un dépôt privé ou un second outil ; ils se mettent en pratique sur votre propre cluster.

## Ce que fait chaque scénario sur le cluster

| Atelier | Installe / crée | Vérification (`verify.sh`) |
|---|---|---|
| 1 | Namespace `argocd` ; CLI `argocd` ; `Application` `guestbook` (dépôt `argoproj/argocd-example-apps`, namespace `guestbook`) | **CRD, Deployments et StatefulSet Argo CD prêts** ; HTTP 200 sur le port-forward ; `argocd app list` ; **`Application` Synced + Healthy** et Deployment `guestbook-ui` disponible |
| 2 | Argo CD ; **serveur Git local** (pod nginx + dépôt nu dans `/srv/git`) ; `Application` `web` (namespace `demo`) | **`prune` et `selfHeal` actifs** ; Deployment `web` revenu à **2 réplicas** après `scale` à 5 ; **Git** (`legacy.yaml` retiré du dépôt) et **cluster** (`legacy` pruné) ; Synced + Healthy |
| 3 | Argo CD ; `ApplicationSet` `guestbook` (List : dev, staging, prod, puis qa) | **Applications générées et possédées par l'ApplicationSet**, Synced + Healthy ; **namespaces** `guestbook-<env>` ; **réplicas réels = paramètre de l'Application** ; recréation de l'`Application` supprimée |

Les vérifications **interrogent l'état réel du cluster** (`kubectl` sur les CRD d'Argo CD et sur les ressources déployées), pas la présence de fichiers.

## Prérequis réseau et durée

| Téléchargement | Source | Indication |
|---|---|---|
| Manifestes Argo CD `v2.13.3` | `raw.githubusercontent.com` | un fichier, ~2 Mo |
| Images Argo CD, Dex, Redis | `quay.io`, `ghcr.io`, registre public | quelques centaines de Mo ; **2 à 4 minutes** d'installation |
| CLI `argocd` (atelier 1) | Releases GitHub | ~170 Mo |
| Dépôt d'exemples (ateliers 1 et 3) | `github.com/argoproj/argocd-example-apps` | clone par Argo CD |
| Images `nginx:1.27-alpine`, `guestbook-ui` | Docker Hub, `gcr.io` | quelques dizaines de Mo |

Chaque scénario est **indépendant** : il installe sa propre instance d'Argo CD. L'atelier 2 abaisse `timeout.reconciliation` à **30 s** (3 minutes par défaut) pour que Git soit relu rapidement ; vous pouvez aussi forcer la relecture avec l'annotation `argocd.argoproj.io/refresh=hard`.

## Publier sur Killercoda

Procédure complète (dépôt GitHub, `structure.json`, mises à jour, tests) dans [**`KILLERCODA.md`**](../../KILLERCODA.md). Contrôle local avant de pousser :

```bash
python3 scripts/check-killercoda.py
```

> ⚠️ **Attention** : les scénarios installent Argo CD avec des droits `cluster-admin` sur le cluster **jetable** du scénario. Ne les exécutez pas tels quels sur un cluster que vous voulez conserver.

[← Retour au module 15](../README.md)
