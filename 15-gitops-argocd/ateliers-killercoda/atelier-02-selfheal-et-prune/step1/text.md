# Étape 1 : un dépôt Git, une Application automatique, et le self-heal

## A. Le serveur Git local et le dépôt de configuration

```bash
mkdir -p /srv/git && git init -q --bare /srv/git/repo.git
git -C /srv/git/repo.git symbolic-ref HEAD refs/heads/main
printf '#!/bin/sh\nexec git update-server-info\n' > /srv/git/repo.git/hooks/post-update
chmod +x /srv/git/repo.git/hooks/post-update
cat > git-server.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: gitserver
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitserver
  namespace: gitserver
spec:
  replicas: 1
  selector:
    matchLabels: { app: gitserver }
  template:
    metadata:
      labels: { app: gitserver }
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports: [{ containerPort: 80 }]
          volumeMounts:
            - { name: git, mountPath: /usr/share/nginx/html, readOnly: true }
      volumes:
        - name: git
          hostPath: { path: /srv/git, type: Directory }
---
apiVersion: v1
kind: Service
metadata:
  name: gitserver
  namespace: gitserver
spec:
  selector: { app: gitserver }
  ports: [{ port: 80, targetPort: 80 }]
EOF
kubectl apply -f git-server.yaml
kubectl -n gitserver rollout status deployment/gitserver --timeout=120s
```{{exec}}

Le hook `post-update` exécute `git update-server-info` après chaque `git push` : c'est ce qui permet de **servir le dépôt en HTTP « simple »** avec un nginx ordinaire.

Créez maintenant le **dépôt de travail** avec trois ressources : un Deployment `web` (**2 réplicas**), son Service et un Deployment `legacy` que nous supprimerons à l'étape 2.

```bash
git clone -q /srv/git/repo.git ~/gitops-repo 2>/dev/null; cd ~/gitops-repo
git config user.name "Etudiant"; git config user.email "etudiant@example.org"
git checkout -q -b main
mkdir -p apps/web
cat > apps/web/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
  selector:
    matchLabels: { app: web }
  template:
    metadata:
      labels: { app: web }
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports: [{ containerPort: 80 }]
EOF
cat > apps/web/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector: { app: web }
  ports: [{ port: 80, targetPort: 80 }]
EOF
cat > apps/web/legacy.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy
spec:
  replicas: 1
  selector:
    matchLabels: { app: legacy }
  template:
    metadata:
      labels: { app: legacy }
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
EOF
git add . && git commit -qm "Etat initial : web (2 réplicas), service, legacy" && git push -q origin main
git log --oneline
```{{exec}}

## B. L'Application automatique

```bash
cat > ~/app-web.yaml <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitserver.gitserver.svc.cluster.local/repo.git
    targetRevision: main
    path: apps/web
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
kubectl apply -f ~/app-web.yaml
sleep 20
kubectl -n argocd get application web
kubectl -n demo get deploy
```{{exec}}

Attendez **Synced / Healthy** (quelques dizaines de secondes). Si l'état reste `Unknown`, consultez la cause : `kubectl -n argocd get application web -o jsonpath='{.status.conditions}'`.

## C. Observer le self-heal

On **triche** : on met 5 réplicas **directement dans le cluster**, hors de Git.

```bash
kubectl -n demo scale deployment web --replicas=5
kubectl -n demo get deployment web
sleep 10
kubectl -n demo get deployment web
kubectl -n demo get events --sort-by=.lastTimestamp | tail -n 8
```{{exec}}

En quelques secondes, Argo CD détecte la **dérive** (`OutOfSync`) et **ramène à 2** (le Deployment est redimensionné par le contrôleur). Pour voir la correction en direct, relancez `kubectl -n demo get deployment web -w` après le `scale`.

## Questions

- Que se passerait-il **sans** `selfHeal` ? *(L'application passerait `OutOfSync` et resterait à 5 réplicas jusqu'au prochain changement dans Git.)*
- Pourquoi le dépôt contient-il `replicas: 2` et non `5` ? *(Git est la **source de vérité** ; le cluster s'y conforme.)*

Cliquez sur **Vérifier**.
