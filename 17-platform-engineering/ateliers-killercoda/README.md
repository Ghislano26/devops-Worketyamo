# Ateliers Killercoda — Platform Engineering

Deux scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** avec le backend **`kubernetes-kubeadm-1node`** : un **cluster Kubernetes d'un nœud, déjà prêt**. **Helm, Backstage, Crossplane et ses paquets sont installés par chaque scénario.**

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-backstage-catalogue`](atelier-01-backstage-catalogue/) | `kubernetes-kubeadm-1node` | ~35 min | ⭐⭐⭐⭐ | **Backstage** (chart Helm), `catalog-info.yaml` (Group, System, Component), relations `ownedBy` / `partOf` / `dependsOn`, API du catalogue | [3](../cours/03-backstage-portal.md) |
| [`atelier-02-crossplane-premier-composite`](atelier-02-crossplane-premier-composite/) | `kubernetes-kubeadm-1node` | ~35 min | ⭐⭐⭐⭐ | **Crossplane** (Helm), `provider-kubernetes`, ressource gérée, **XRD**, **Composition** (pipeline), **composite**, réconciliation | [4](../cours/04-crossplane-control-plane.md), [5](../cours/05-golden-paths-et-templates.md) |

**Lisez le cours associé avant chaque atelier.** Les cours 1, 2, 5 et 6 sont conceptuels (produit, composants, golden paths, équipes) et ne se pratiquent pas dans un scénario.

## Ce que fait chaque scénario sur le cluster

| Atelier | Installe / crée | Vérification (`verify.sh`) |
|---|---|---|
| 1 | Helm `v3.16.3` ; namespace `backstage` ; ConfigMap `catalogue` (monté dans `/catalog`) ; release Helm `backstage` (chart non épinglé) ; `~/backstage-lab/` | **Deployment prêt** ; **API du catalogue interrogée depuis le pod** (Component, System, Group présents) ; relations **`ownedBy`** puis **`dependsOn`** et **`dependencyOf`** après ajout d'un second composant |
| 2 | Helm ; **Crossplane `1.18.0`** ; `provider-kubernetes v0.15.0` ; `function-patch-and-transform v0.7.0` ; namespace `apps-plateforme` ; XRD `XWebApp`, Composition, XR `boutique` ; `~/crossplane-lab/` | **Provider et fonction `Healthy`** ; `ProviderConfig` et droits ; **ConfigMap réel** créé par une ressource gérée ; **XRD `Established`**, Composition en **Pipeline**, **XR `Ready` et `Synced`** ; **Deployment et Service réels** conformes à la demande (3 réplicas, image) |

Les vérifications **testent l'état réel du cluster** (CRD de Crossplane, ressources créées, API de Backstage), pas la présence de fichiers.

## Limites assumées

- **Backstage est lourd** : l'image de démonstration du chart pèse plusieurs centaines de Mo, démarre en **1 à 3 minutes** et consomme beaucoup de mémoire. La **base est en mémoire** et l'**authentification de l'API est désactivée** (`dangerouslyDisableDefaultAuthPolicy`) : **uniquement pour l'atelier**. Le **chart n'est pas épinglé** (relevez la version avec `helm list -n backstage`).
- **Interface web de Backstage** : configurée pour `http://localhost:7007`. Sur Killercoda, l'accès par le menu *Traffic / Ports* utilise une autre URL et peut être **incomplet** (CORS) ; la vérification repose sur l'**API en ligne de commande**.
- **Crossplane sans cloud** : `provider-kubernetes` remplace `provider-aws` (qui exigerait des identifiants et créerait de vraies ressources). Le provider reçoit **`cluster-admin`** pour l'atelier : en production, des droits **ciblés**.
- **Versions de Crossplane** : l'atelier suit l'API **1.x** (Compositions en pipeline, XRD v1) ; les séries **2.x** changent plusieurs mécanismes.
- **Dérive** : le délai de détection de dérive d'un `Object` (sondage du provider, 10 minutes par défaut) est trop long pour un atelier : on **modifie la demande** (la XR) plutôt que de supprimer la ressource réelle.

## Prérequis réseau et durée

| Téléchargement | Source | Indication |
|---|---|---|
| Helm (script officiel) | `raw.githubusercontent.com` | quelques Mo |
| Chart et image Backstage | `backstage.github.io`, `ghcr.io` | **plusieurs centaines de Mo** ; 3 à 10 minutes selon la connexion |
| Chart et images Crossplane | `charts.crossplane.io`, `xpkg.upbound.io` | ~300 Mo ; **3 à 5 minutes** |
| Paquets `provider-kubernetes`, `function-patch-and-transform` | `xpkg.upbound.io` | quelques dizaines de Mo chacun |
| Image `nginx:1.27-alpine` (atelier 2) | Docker Hub | quelques dizaines de Mo |

Chaque scénario est **indépendant** : il installe ses propres composants sur un cluster neuf.

## Publier sur Killercoda

Procédure complète (dépôt GitHub, `structure.json`, mises à jour, tests) dans [**`KILLERCODA.md`**](../../KILLERCODA.md). Contrôle local avant de pousser :

```bash
python3 scripts/check-killercoda.py
```

> ⚠️ **Attention** : ces scénarios installent des composants avec des droits étendus (`cluster-admin` pour le provider, authentification désactivée pour Backstage) sur un cluster **jetable**. Ne les exécutez pas tels quels sur un cluster que vous voulez conserver.

[← Retour au module 17](../README.md)
