# Étape 1 : une charge surdimensionnée et sa mesure

## A. Déployer la charge « gaspillage »

Trois réplicas de nginx **quasiment inactifs**, mais qui **demandent 250 m de CPU et 256 Mi de mémoire chacun** (soit **0,75 CPU et 768 Mi réservés**) :

```bash
kubectl create namespace finops-lab
cd ~/finops-lab
cat > gaspillage.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gaspillage
  namespace: finops-lab
  labels:
    team: demo
    environment: lab
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gaspillage
  template:
    metadata:
      labels:
        app: gaspillage
        team: demo
        environment: lab
    spec:
      containers:
        - name: web
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
EOF
kubectl apply -f gaspillage.yaml
kubectl -n finops-lab rollout status deployment/gaspillage --timeout=300s
kubectl -n finops-lab get pods
```{{exec}}

Le **scheduler** a réservé cette capacité : aucun autre pod ne peut l'utiliser, même si nginx n'en consomme presque rien.

```bash
kubectl -n finops-lab top pods 2>/dev/null || echo "(metrics-server absent : on lit l'usage dans OpenCost)"
```{{exec}}

## B. Laisser la collecte se faire, puis mesurer

Prometheus collecte **toutes les minutes** : attendez **6 minutes** pour avoir une fenêtre représentative de la charge (`window=5m`).

```bash
sleep 360
cd ~/finops-lab
./couts.py 5m namespace
```{{exec}}

Dans la ligne `finops-lab` :

- **cpu dem.** (CPU demandé) ≈ **0,75** ;
- **cpu util.** (CPU utilisé) ≈ **0,00x** ;
- **eff.cpu** ≈ **0 %** : on paie ce qui est réservé, pas ce qui est utilisé.

## C. Sauvegarder l'état « avant »

On garde la **réponse brute de l'API** pour comparer plus tard :

```bash
cd ~/finops-lab
kubectl get --raw "/api/v1/namespaces/opencost/services/opencost:9003/proxy/allocation/compute?window=5m&aggregate=namespace&accumulate=true" > avant.json
python3 -c '
import json
a = json.load(open("avant.json"))["data"][0]["finops-lab"]
print("coût sur 5 min :", round(a["totalCost"], 5), "$ | CPU demandé :", round(a["cpuCoreRequestAverage"], 3),
      "| CPU utilisé :", round(a["cpuCoreUsageAverage"], 4), "| efficience CPU :", round(a["cpuEfficiency"] * 100, 1), "%")
'
```{{exec}}

> Si `finops-lab` n'apparaît pas encore : attendez 2 minutes et recommencez. Si la ligne est là mais très basse en demandé, c'est que la fenêtre n'est pas encore remplie.

## Questions

- Pourquoi le coût d'OpenCost reflète-t-il surtout les **requests** ici ? *(Règle `max(demandé, utilisé)` : l'usage étant presque nul, le demandé l'emporte.)*
- Que se passerait-il sur un vrai cluster avec **20 services** configurés ainsi ? *(Il faudrait des **nœuds supplémentaires** pour réserver cette capacité inutile : coût direct sur la facture.)*

Cliquez sur **Vérifier**.
