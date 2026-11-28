# OpenCost : installation et lecture des coûts

**Durée : ~30 minutes.** Compétence travaillée : installer **OpenCost** (et Prometheus) avec Helm, accéder à l'interface, **identifier les namespaces les plus coûteux** et repérer les charges **inefficaces** (réservé mais inutilisé).

Rappel du [cours OpenCost et Kubecost](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/03-kubecost-opencost.md) :

```text
Prometheus (requests, usage)  +  prix  ──►  OpenCost  ──►  coût par namespace / pod / label
                                                     └──►  efficience = utilisé ÷ demandé
```

Cet atelier s'exécute sur un **cluster Kubernetes d'un nœud, déjà prêt** :

```bash
kubectl get nodes
```{{exec}}

> 🌐 **Réseau et durée** : le scénario installe **Prometheus** (chart `prometheus-community/prometheus`, avec kube-state-metrics et node-exporter) puis **OpenCost** (chart `opencost/opencost`) avec **Helm**. Comptez **4 à 8 minutes** (images, démarrage), puis **quelques minutes de collecte** avant d'avoir des chiffres. Les versions des charts **ne sont pas épinglées** (relevez-les avec `helm list -A`).

> 💲 **Prix fictifs.** Il n'y a **pas de facture cloud** ici : OpenCost utilise des **tarifs personnalisés fictifs** (`CPU 0,03 $/cœur·h`, `RAM 0,004 $/Go·h`). Les montants sont **proportionnels et comparables**, mais **ne correspondent à aucune facture réelle** ([cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/03-kubecost-opencost.md)).
