# Étape 1 : déployer Backstage avec un premier catalogue

## A. Décrire trois entités

Un fichier `catalog-info.yaml` peut contenir **plusieurs entités** séparées par `---`. On décrit une **équipe** (`Group`), un **système** et un **composant** (`Component`), et leurs liens.

```bash
mkdir -p ~/backstage-lab && cd ~/backstage-lab
cat > catalog-info.yaml <<'EOF'
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: equipe-boutique
  description: Équipe responsable de la boutique en ligne
spec:
  type: team
  children: []
---
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: boutique
  description: Système de la boutique en ligne
spec:
  owner: equipe-boutique
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: boutique-api
  description: API REST de la boutique
  tags: [api, java]
spec:
  type: service
  lifecycle: production
  owner: equipe-boutique
  system: boutique
EOF
kubectl create namespace backstage
kubectl -n backstage create configmap catalogue --from-file=catalog-info.yaml
kubectl -n backstage get configmap catalogue
```{{exec}}

Le **ConfigMap** `catalogue` sera monté dans le pod (dossier `/catalog`) : Backstage y lira le fichier.

## B. Installer Helm et déployer Backstage

On configure Backstage par un fichier de valeurs : titre, URL, **location de type `file`** pointant vers notre fichier, et désactivation de PostgreSQL (SQLite en mémoire suffit ici). L'option `dangerouslyDisableDefaultAuthPolicy` **autorise les appels à l'API sans jeton** : **uniquement** pour l'atelier.

```bash
command -v helm >/dev/null 2>&1 || {
  curl -fsSL -o /tmp/get-helm-3.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 /tmp/get-helm-3.sh && /tmp/get-helm-3.sh --version v3.16.3
}
helm version --short
cd ~/backstage-lab
cat > values-backstage.yaml <<'EOF'
backstage:
  appConfig:
    app:
      title: Portail Worketyamo
      baseUrl: http://localhost:7007
    backend:
      baseUrl: http://localhost:7007
      cors:
        origin: http://localhost:7007
      auth:
        dangerouslyDisableDefaultAuthPolicy: true
    auth:
      environment: development
      providers:
        guest: {}
    catalog:
      rules:
        - allow: [Component, System, API, Resource, Location, Group, User, Domain]
      locations:
        - type: file
          target: /catalog/catalog-info.yaml
  extraVolumes:
    - name: catalogue
      configMap:
        name: catalogue
  extraVolumeMounts:
    - name: catalogue
      mountPath: /catalog
postgresql:
  enabled: false
EOF
helm repo add backstage https://backstage.github.io/charts
helm repo update
helm install backstage backstage/backstage --namespace backstage -f values-backstage.yaml --wait --timeout 10m
helm list -n backstage
kubectl -n backstage get pods
```{{exec}}

Si l'installation dépasse le délai ou si le pod redémarre, regardez les journaux :

```bash
kubectl -n backstage get pods
kubectl -n backstage logs -l app.kubernetes.io/name=backstage --tail=40
kubectl -n backstage describe pod -l app.kubernetes.io/name=backstage | tail -n 20
```{{exec}}

## C. Interroger le catalogue

L'API du catalogue répond depuis **l'intérieur** du pod (aucun port-forward nécessaire). On liste les entités avec leurs **relations** :

```bash
POD=$(kubectl -n backstage get pod -l app.kubernetes.io/name=backstage -o name | head -n1)
kubectl -n backstage exec "$POD" -- node -e "fetch('http://localhost:7007/api/catalog/entities').then(r=>r.json()).then(e=>e.forEach(x=>console.log(x.kind+'/'+x.metadata.name+' -> '+(x.relations||[]).map(y=>y.type+':'+y.targetRef).join(', '))))"
```{{exec}}

Vous devez voir `Component/boutique-api` avec les relations **`ownedBy`** (équipe-boutique) et **`partOf`** (système boutique) : Backstage a **déduit** le graphe à partir des champs `owner` et `system`.

Pour **voir l'interface web** (meilleur effort) :

```bash
nohup kubectl -n backstage port-forward svc/backstage --address 0.0.0.0 7007:7007 > /tmp/port-forward.log 2>&1 &
sleep 3
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:7007/
```{{exec}}

> L'interface est configurée pour l'adresse `http://localhost:7007`. Sur Killercoda, l'accès par le menu **Traffic / Ports** utilise une **autre URL** : la page peut s'afficher mais les appels à l'API peuvent être refusés (CORS). L'**API en ligne de commande** ci-dessus est la vérification fiable.

## Questions

- Pourquoi `owner: equipe-boutique` suffit-il à créer la relation `ownedBy` ? *(Backstage résout la référence vers l'entité `Group` du même nom ; le catalogue construit le graphe.)*
- Que perd-on si le pod redémarre ? *(La base SQLite en mémoire ; le catalogue est reconstruit depuis le fichier monté au démarrage.)*

Cliquez sur **Vérifier**.
