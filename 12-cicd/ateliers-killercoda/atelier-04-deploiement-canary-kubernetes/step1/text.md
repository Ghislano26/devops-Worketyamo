# Étape 1 : deux Deployments, un Service

Le principe du **canari par nombre de pods** ([cours 7](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/07-strategies-de-deploiement.md)) : un Service sélectionne les pods par un **label partagé** (`app: web`) ; la proportion de trafic de chaque version dépend du **nombre de pods** de chacune.

| Deployment | Image | Réplicas | Part de trafic attendue |
|---|---|---|---|
| `app-v1` (stable) | `nginx:1.24` | 4 | ~80 % |
| `app-v2` (canari) | `nginx:1.25` | 1 | ~20 % |

```bash
mkdir -p ~/canary && cd ~/canary
cat > app-v1.yml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
spec:
  replicas: 4
  selector:
    matchLabels: { app: web, version: v1 }
  template:
    metadata:
      labels: { app: web, version: v1 }
    spec:
      containers:
        - name: nginx
          image: nginx:1.24
          ports: [{ containerPort: 80 }]
          readinessProbe: { httpGet: { path: /, port: 80 } }
EOF
cat > app-v2.yml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
spec:
  replicas: 1
  selector:
    matchLabels: { app: web, version: v2 }
  template:
    metadata:
      labels: { app: web, version: v2 }
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          readinessProbe: { httpGet: { path: /, port: 80 } }
EOF
cat > service.yml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web            # label PARTAGÉ : sélectionne v1 ET v2
  ports:
    - port: 80
      targetPort: 80
EOF
kubectl apply -f app-v1.yml -f app-v2.yml -f service.yml
kubectl rollout status deployment/app-v1
kubectl rollout status deployment/app-v2
kubectl get pods -l app=web --show-labels
kubectl get endpoints web
```{{exec}}

Le Service `web` doit lister **5 adresses** (4 + 1).

## Mesurer la répartition

Chaque version de nginx annonce son numéro dans l'en-tête `Server`. Envoyez 50 requêtes depuis un pod client et comptez :

```bash
kubectl run client --rm -i --restart=Never --image=curlimages/curl --command -- \
  sh -c 'for i in $(seq 1 50); do curl -sI http://web | grep -i "^server"; done | sort | uniq -c' 2>/dev/null
```{{exec}}

Vous obtenez environ **40 réponses `nginx/1.24.x` et 10 réponses `nginx/1.25.x`** : le hasard fait varier les nombres, pas l'ordre de grandeur.

> Avec ce procédé, la précision est faible (granularité d'un pod, pas de pondération fine) : pour des paliers réguliers (1 %, 5 %…) et une analyse automatique des métriques, on utilise **Argo Rollouts** ou **Flagger** ([cours 7](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/07-strategies-de-deploiement.md)).

Cliquez sur **Vérifier**.
