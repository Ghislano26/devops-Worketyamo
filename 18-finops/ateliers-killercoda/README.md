# Ateliers Killercoda — FinOps (OpenCost)

Deux scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** avec le backend **`kubernetes-kubeadm-1node`** : un **cluster Kubernetes d'un nœud, déjà prêt**. **Helm, Prometheus et OpenCost sont installés par chaque scénario.**

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-opencost-installation`](atelier-01-opencost-installation/) | `kubernetes-kubeadm-1node` | ~30 min | ⭐⭐⭐⭐ | Prometheus + **OpenCost** (Helm), API d'allocation, coût par namespace, **efficience**, coût inactif (`__idle__`), interface web | [3](../cours/03-kubecost-opencost.md) |
| [`atelier-02-rightsizing-requests`](atelier-02-rightsizing-requests/) | `kubernetes-kubeadm-1node` | ~40 min | ⭐⭐⭐⭐ | Charge **surdimensionnée** (requests 250 m / 256 Mi × 3), mesure du gaspillage, `kubectl set resources`, comparaison **avant / après** | [3](../cours/03-kubecost-opencost.md), [4](../cours/04-rightsizing-et-optimisation.md) |

**Lisez le cours associé avant chaque atelier.** Les cours 1, 2 et 5 (principes, étiquetage, gouvernance) sont conceptuels et se mettent en pratique dans votre organisation.

## Ce que fait chaque scénario sur le cluster

| Atelier | Installe / crée | Vérification (`verify.sh`) |
|---|---|---|
| 1 | Helm `v3.16.3` ; `prometheus` (namespace `prometheus-system`, avec kube-state-metrics et node-exporter) ; `opencost` (namespace `opencost`, **prix fictifs**) ; `~/finops-lab/` : valeurs Helm, `couts.py`, `top-namespaces.txt`, `inefficaces.txt` | **Deployments prêts** ; **API d'allocation interrogée via le proxy de l'API Kubernetes** (≥ 3 namespaces avec un coût) ; interface sur le port 9090 (HTTP 200) ; fichiers de résultats **cohérents avec les données d'OpenCost** |
| 2 | Idem + namespace `finops-lab`, Deployment `gaspillage` (3 réplicas) ; `avant.json`, `apres.json`, `bilan.txt` | Requests **250 m / 256 Mi** puis **réduites** (≤ 50 m, ≤ 64 Mi, avec marge) ; **3 réplicas disponibles** ; mesures OpenCost : **CPU demandé** `avant` ≥ 0,5 puis `après` < 50 % de `avant`, **coût en baisse**, efficience initiale très basse |

Les vérifications **lisent l'état réel du cluster et les données d'OpenCost** (pas seulement des fichiers).

## Limites assumées

- **Prix fictifs** : sans facture cloud, OpenCost utilise des **tarifs personnalisés** (`CPU 0,03 $/cœur·h`, `RAM 0,004 $/Go·h`). Les montants servent à **comparer et mesurer des progrès**, pas à budgéter.
- **Temps de collecte** : Prometheus collecte **toutes les minutes** ; il faut **quelques minutes** avant d'avoir des chiffres (atelier 1) et **6 puis 7 minutes** d'attente dans l'atelier 2 (fenêtres de 5 minutes propres). Les `verify.sh` échouent avec un message explicite tant que les données ne sont pas prêtes.
- **Pas de recommandations automatiques** : elles sont une fonction de **Kubecost** ; l'atelier les **déduit manuellement** de l'efficience.
- **Charts non épinglés** : `prometheus-community/prometheus` et `opencost/opencost` (relevez les versions avec `helm list -A`) ; les noms de champs de l'API d'allocation (`cpuCoreRequestAverage`, `cpuEfficiency`, `totalCost`…) sont ceux d'OpenCost et peuvent évoluer.
- **Ressources du nœud** : la charge de l'atelier 2 réserve 0,75 CPU et 768 Mi ; sur un nœud très chargé, des pods peuvent rester `Pending` (voir `kubectl -n finops-lab describe pods`).

## Prérequis réseau et durée

| Téléchargement | Source | Indication |
|---|---|---|
| Helm (script officiel) | `raw.githubusercontent.com` | quelques Mo |
| Charts et images Prometheus, kube-state-metrics, node-exporter | `prometheus-community.github.io`, `quay.io`, registres publics | ~300 Mo |
| Chart et images OpenCost (exporteur, interface) | `opencost.github.io`, `ghcr.io` | ~200 Mo |
| Image `nginx:1.27-alpine` (atelier 2) | Docker Hub | quelques dizaines de Mo |

Installation : **4 à 8 minutes** par scénario. Chaque scénario est **indépendant** : il installe sa propre pile sur un cluster neuf.

## Publier sur Killercoda

Procédure complète (dépôt GitHub, `structure.json`, mises à jour, tests) dans [**`KILLERCODA.md`**](../../KILLERCODA.md). Contrôle local avant de pousser :

```bash
python3 scripts/check-killercoda.py
```

> ⚠️ **Attention** : ces scénarios installent Prometheus et OpenCost sur un cluster **jetable**. Ne les exécutez pas tels quels sur un cluster de production (volumes non persistants, ressources non dimensionnées).

[← Retour au module 18](../README.md)
