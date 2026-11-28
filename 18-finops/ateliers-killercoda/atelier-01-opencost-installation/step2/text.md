# Étape 2 : trouver les namespaces coûteux et les charges inefficaces

## A. L'interface web

```bash
nohup kubectl -n opencost port-forward svc/opencost 9090:9090 --address 0.0.0.0 > /tmp/opencost-ui.log 2>&1 &
sleep 3
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:9090/
```{{exec}}

Vous devez lire `HTTP 200`. Sur Killercoda, ouvrez le port `9090` via le menu **Traffic / Ports** : l'interface d'OpenCost affiche le coût par namespace, contrôleur, pod, avec des fenêtres de temps et des graphiques. (Si l'interface est vide, la collecte n'est pas encore assez longue : utilisez le script ci-dessous.)

## B. Le classement par namespace

```bash
cd ~/finops-lab
./couts.py 30m namespace
```{{exec}}

Colonnes : **coût** de la fenêtre, **CPU demandé** (requests) et **utilisé**, **efficience** CPU et mémoire. La ligne **`__idle__`** représente la **capacité des nœuds non réservée** : payée, mais attribuée à personne.

## C. Trouver les trois plus coûteux

Enregistrez les **trois namespaces les plus coûteux** (hors `__idle__`) :

```bash
cd ~/finops-lab
kubectl get --raw "/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute?window=30m&aggregate=namespace&accumulate=true" \
  | python3 -c '
import json, sys
d = json.load(sys.stdin)["data"][0]
top = sorted(((k, v.get("totalCost", 0)) for k, v in d.items() if not k.startswith("__")), key=lambda x: -x[1])[:3]
print("\n".join(k for k, _ in top))
' | tee top-namespaces.txt
```{{exec}}

## D. Repérer l'inefficience (les « recommandations »)

OpenCost **n'écrit pas** de recommandations automatiques (c'est une fonction de Kubecost) : on les **déduit** de l'efficience. On liste les **namespaces dont l'efficience CPU est inférieure à 50 %** (réservent bien plus qu'ils n'utilisent) :

```bash
cd ~/finops-lab
kubectl get --raw "/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute?window=30m&aggregate=namespace&accumulate=true" \
  | python3 -c '
import json, sys
d = json.load(sys.stdin)["data"][0]
for k, v in sorted(d.items(), key=lambda kv: kv[1].get("cpuEfficiency", 0)):
    if k.startswith("__") or v.get("cpuCoreRequestAverage", 0) < 0.01:
        continue
    if v.get("cpuEfficiency", 0) < 0.5:
        print(k)
' | tee inefficaces.txt
echo "--- Détail par pod dans le plus coûteux :"
./couts.py 30m pod | head -n 12
```{{exec}}

Pour un namespace de la liste, la **recommandation manuelle** est : *« ce pod demande X CPU et en utilise Y : ramener les requests près de Y plus une marge »* ; c'est exactement ce que vous ferez à l'[atelier 2](https://github.com/Ghislano26/devops-Worketyamo/tree/main/18-finops/ateliers-killercoda/atelier-02-rightsizing-requests).

> 💡 Les namespaces système (`kube-system`) ont souvent des requests **modestes** mais **réelles** ; les composants d'infrastructure ne se « rightsizent » pas à la légère. Concentrez-vous sur **vos applications**.

## Questions

- Que représente `__idle__` et pourquoi est-il important ? *(La capacité payée non réservée : c'est la cible de la consolidation de nœuds et de l'autoscaling.)*
- Pourquoi une efficience **très basse** n'est-elle pas forcément un problème **immédiat** à corriger ? *(Il faut regarder sur une période représentative (7 jours avec un pic) avant de réduire des requests.)*

Cliquez sur **Vérifier**.
