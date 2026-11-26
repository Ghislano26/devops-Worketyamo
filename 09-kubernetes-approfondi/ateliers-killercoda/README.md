# Ateliers Killercoda — Kubernetes approfondi

Ces trois scénarios s'exécutent sur **[Killercoda](https://killercoda.com/)** : un vrai cluster Kubernetes, prêt en quelques secondes, dans le navigateur.
Rien à installer, rien à casser sur votre ordinateur.

| Scénario | Durée | Notions | Cours associés |
|---|---|---|---|
| [`atelier-01-premier-pod-et-deployment`](atelier-01-premier-pod-et-deployment/) | ~25 min | Pod, Deployment, ReplicaSet, scale, RollingUpdate, historique, rollback | [01](../cours/01-architecture-et-composants.md), [02](../cours/02-pods-et-workloads.md) |
| [`atelier-02-service-et-nodeport`](atelier-02-service-et-nodeport/) | ~20 min | Service ClusterIP, endpoints, DNS interne, NodePort | [03](../cours/03-services-et-reseau-kubernetes.md) |
| [`atelier-03-configmap-secret-et-rbac`](atelier-03-configmap-secret-et-rbac/) | ~25 min | ConfigMap, Secret (env et fichiers), ServiceAccount, Role, RoleBinding, `auth can-i` | [05](../cours/05-configuration-et-secrets.md), [07](../cours/07-securite-rbac-et-networkpolicies.md) |

**Lisez le cours associé avant chaque atelier** : l'atelier vérifie vos acquis, il ne réexplique pas la théorie. Les notions de Docker (conteneurs, images, réseau) sont supposées
acquises : voir le [module 08](../../08-docker-approfondi/README.md).

## Environnement

Les trois scénarios utilisent le backend **`kubernetes-kubeadm-1node`** (`"backend": {"imageid": "kubernetes-kubeadm-1node"}` dans `index.json`) : un cluster **kubeadm à un nœud**
(control plane et worker sur la même machine), `kubectl` configuré, accès Internet pour télécharger les images (`nginx`, `busybox`).
Patientez quelques instants à l'ouverture jusqu'à ce que `kubectl get nodes` affiche `Ready`.

## Structure d'un scénario

Chaque dossier suit le format imposé par Killercoda :

```text
atelier-0X-nom/
├── index.json          # métadonnées : titre, étapes, image de l'environnement
├── intro.md            # page d'accueil du scénario
├── step1/
│   ├── text.md         # énoncé de l'étape (Markdown)
│   └── verify.sh       # script de vérification (code retour 0 = étape réussie)
├── step2/ …            # (l'atelier 1 comporte trois étapes)
└── finish.md           # page de fin
```

Éléments de syntaxe Killercoda utilisés dans les `text.md` :

| Syntaxe | Effet |
|---|---|
| ` ```bash … ```{{exec}} ` | Un clic **exécute** le bloc dans le terminal |
| ` ```bash … ```{{copy}} ` | Un clic **copie** le bloc |

Le bouton **Vérifier** exécute `verify.sh` : un **code de retour 0** passe à l'étape suivante ; sinon, le message affiché indique ce qu'il manque.

## Publier ces scénarios sur Killercoda

1. Créez un compte sur <https://killercoda.com/> (connexion GitHub possible), puis ouvrez votre profil → **Creator**.
2. **Liez ce dépôt GitHub** à votre profil Killercoda (dépôt public, ou accès accordé via la GitHub App de Killercoda). Killercoda lit les scénarios dans le dépôt et se met à jour à chaque *push*.
3. L'image de l'environnement est choisie dans `index.json` : **`kubernetes-kubeadm-1node`** pour Kubernetes (`ubuntu` pour le [module 08 — Docker](../../08-docker-approfondi/ateliers-killercoda/README.md)).
4. Lancez le scénario depuis votre page Creator ; vous pouvez **prévisualiser** vos modifications avant publication.

> ⚠️ **Attention** : Killercoda détecte les scénarios selon la **structure du dépôt** (dossiers contenant un `index.json`, éventuellement déclarés par un `structure.json`). Ces scénarios sont rangés sous
> `09-kubernetes-approfondi/ateliers-killercoda/`. Si la plateforme ne les trouve pas à cet emplacement, consultez la documentation « Creators » (<https://killercoda.com/creators>) : il faudra peut-être déclarer ces chemins dans un `structure.json` ou placer les dossiers `atelier-0X-*` à la racine d'un dépôt dédié.

## Suivre les ateliers sans Killercoda

Les commandes sont des commandes `kubectl` standard. Sur votre propre cluster de test (**kind**, **minikube**, **k3s**, Docker Desktop), vous pouvez suivre les `text.md` à la main et lancer les vérifications :

```bash
bash atelier-01-premier-pod-et-deployment/step1/verify.sh ; echo "code retour = $?"
```

> ⚠️ **Attention** : ne le faites **jamais** sur un cluster de production. Les ateliers créent et suppriment des namespaces, des Deployments et des ServiceAccounts, et utilisent le namespace `default`.

## Rappel du module

[← Retour au module 09](../README.md)
