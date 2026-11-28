# Étape 2 : réduire les requests et comparer

## A. Rightsizer

L'usage réel de nginx inactif est **de l'ordre de 1 m CPU et 5 Mi**. On ramène les requests **près de l'usage avec une marge** (10 m CPU, 16 Mi) et on pose des limits raisonnables. **En production**, on le ferait **à partir de 7 jours d'usage** (p95 / p99) et on reporterait la valeur **dans Git**, pas avec `kubectl` ([cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/04-rightsizing-et-optimisation.md)).

```bash
kubectl -n finops-lab set resources deployment gaspillage --requests=cpu=10m,memory=16Mi --limits=cpu=100m,memory=64Mi
kubectl -n finops-lab rollout status deployment/gaspillage --timeout=300s
kubectl -n finops-lab get pods
kubectl -n finops-lab get deployment gaspillage -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```{{exec}}

Le déploiement a été **redémarré progressivement** (rolling update) : l'application reste disponible.

## B. Attendre une fenêtre propre

La fenêtre `5m` ne doit contenir **que les nouveaux pods** : attendez **7 minutes** après le déploiement.

```bash
sleep 420
cd ~/finops-lab
./couts.py 5m namespace
```{{exec}}

## C. Sauvegarder « après » et comparer

```bash
cd ~/finops-lab
kubectl get --raw "/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute?window=5m&aggregate=namespace&accumulate=true" > apres.json
python3 - <<'EOF' | tee bilan.txt
import json
def lire(f):
    return json.load(open(f))["data"][0]["finops-lab"]
a, b = lire("avant.json"), lire("apres.json")
def pct(x, y):
    return 100 * (x - y) / x if x else 0
print("                      avant      après     évolution")
print(f"CPU demandé       {a['cpuCoreRequestAverage']:9.3f} {b['cpuCoreRequestAverage']:9.3f}   -{pct(a['cpuCoreRequestAverage'], b['cpuCoreRequestAverage']):.0f} %")
print(f"Efficience CPU    {a['cpuEfficiency']*100:8.1f}% {b['cpuEfficiency']*100:8.1f}%")
print(f"Coût sur 5 min    {a['totalCost']:9.5f} {b['totalCost']:9.5f}   -{pct(a['totalCost'], b['totalCost']):.0f} %")
mois = 12 * 24 * 30
print(f"Coût mensuel estimé (prix fictifs) : {a['totalCost']*mois:.2f} $ -> {b['totalCost']*mois:.2f} $ , économie {pct(a['totalCost'], b['totalCost']):.0f} %")
EOF
```{{exec}}

Vous devez constater : **CPU demandé divisé par ~25**, **coût en forte baisse**, application toujours **disponible** (3 pods `Running`). Notez que le coût ne tombe pas à zéro : il reste la part **mémoire**, les **minimums** et, selon l'implémentation, des composantes fixes.

> ⚠️ **Attention** : ici le gain est spectaculaire car la charge est **fictive** et inactive. Sur une vraie application, **réduire les requests trop fort** provoque **OOMKill** (mémoire) ou **throttling** (CPU) : procédez par paliers, **sur une période représentative**, avec des alertes ([cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/18-finops/cours/04-rightsizing-et-optimisation.md)).

## Questions

- Pourquoi le **coût inactif** (`__idle__`) du cluster **n'a-t-il pas** diminué pour autant ? *(La capacité libérée devient du coût inactif tant que les nœuds restent : l'économie réelle vient d'une **consolidation** / réduction de nœuds ou de l'autoscaling.)*
- Qu'est-ce qui rendrait cette optimisation **durable** ? *(Un `LimitRange` / politique qui impose des requests raisonnables, une revue régulière de l'efficience, et la valeur versionnée dans Git.)*

Cliquez sur **Vérifier**.
