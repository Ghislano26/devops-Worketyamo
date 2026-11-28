# Policy as code avec Kyverno

**Durée : ~25 minutes.** Compétence travaillée : installer **Kyverno** avec Helm, écrire une **`ClusterPolicy`** qui **interdit le tag `:latest`**, tester un pod **conforme** et des pods **non conformes**, et manipuler le mode **Audit** / **Enforce**.

Rappel du [cours Policy as code pour Kubernetes](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/04-policy-as-code-kubernetes.md) :

```text
kubectl run … ──► API server ──► Admission (webhook Kyverno) ──► ClusterPolicy
                                       ├─ conforme      → créé
                                       └─ non conforme  → REFUSÉ (Enforce) ou consigné (Audit)
```

Cet atelier s'exécute sur un **cluster Kubernetes d'un nœud, déjà prêt**.

```bash
kubectl get nodes
```{{exec}}

> 🌐 **Réseau et durée** : le scénario installe **Helm** (script officiel) puis le **chart Kyverno** (`3.3.4`) ; les images viennent de `reg.kyverno.io` / `ghcr.io`. Comptez **2 à 4 minutes** pour que tous les contrôleurs Kyverno soient prêts : l'admission ne fonctionne qu'**après** (sinon la politique est ignorée ou le webhook refuse tout).
