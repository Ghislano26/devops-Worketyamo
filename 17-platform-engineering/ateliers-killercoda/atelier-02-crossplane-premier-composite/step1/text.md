# Étape 1 : installer Crossplane, un provider et une première ressource gérée

## A. Installer Crossplane

```bash
command -v helm >/dev/null 2>&1 || {
  curl -fsSL -o /tmp/get-helm-3.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 /tmp/get-helm-3.sh && /tmp/get-helm-3.sh --version v3.16.3
}
helm version --short
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace --version 1.18.0 --wait --timeout 5m
kubectl -n crossplane-system get pods
```{{exec}}

Crossplane est un contrôleur ordinaire (plus un contrôleur RBAC) ; il n'a encore **aucun provider**.

## B. Installer le provider et la fonction

On installe `provider-kubernetes`, avec un **compte de service au nom fixe** (nécessaire pour lui donner des droits), et la fonction `function-patch-and-transform` que la Composition utilisera.

```bash
mkdir -p ~/crossplane-lab && cd ~/crossplane-lab
cat > packages.yaml <<'EOF'
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: provider-kubernetes
spec:
  serviceAccountTemplate:
    metadata:
      name: provider-kubernetes
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.15.0
  runtimeConfigRef:
    name: provider-kubernetes
---
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-patch-and-transform
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-patch-and-transform:v0.7.0
EOF
kubectl apply -f packages.yaml
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=300s
kubectl wait function.pkg.crossplane.io/function-patch-and-transform --for=condition=Healthy --timeout=300s
kubectl get providers,functions
```{{exec}}

> Si l'attente dépasse le délai : `kubectl describe provider provider-kubernetes` (erreur de téléchargement du paquet ? DNS ?) puis `kubectl -n crossplane-system get pods`.

## C. Droits et configuration du provider

Le provider crée des objets dans le cluster : il lui faut des **droits RBAC**. (Atelier : `cluster-admin` ; en production, des droits **ciblés**.) Puis un `ProviderConfig` qui dit « utilise l'**identité du pod** ».

```bash
cd ~/crossplane-lab
kubectl create clusterrolebinding provider-kubernetes-admin --clusterrole=cluster-admin --serviceaccount=crossplane-system:provider-kubernetes
kubectl create namespace apps-plateforme
cat > providerconfig.yaml <<'EOF'
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: InjectedIdentity
EOF
kubectl apply -f providerconfig.yaml
kubectl get providerconfig.kubernetes.crossplane.io
```{{exec}}

## D. Une ressource gérée (Managed Resource)

Avant de composer, essayons une **ressource gérée simple** : un `Object` qui **crée un ConfigMap**.

```bash
cd ~/crossplane-lab
cat > configmap-object.yaml <<'EOF'
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: bonjour
spec:
  providerConfigRef:
    name: default
  forProvider:
    manifest:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: bonjour
        namespace: apps-plateforme
      data:
        message: "Créé par Crossplane"
EOF
kubectl apply -f configmap-object.yaml
kubectl wait object.kubernetes.crossplane.io/bonjour --for=condition=Ready --timeout=120s
kubectl get object
kubectl -n apps-plateforme get configmap bonjour -o jsonpath='{.data.message}{"\n"}'
```{{exec}}

Le ConfigMap **existe réellement** : Crossplane l'a créé pour nous. C'est exactement ce que ferait un `Bucket` pour S3.

## Questions

- Pourquoi donner un **nom fixe** au compte de service du provider ? *(Pour y attacher un `ClusterRoleBinding` ; sinon le nom est généré avec un suffixe aléatoire.)*
- Que se passe-t-il si vous supprimez l'`Object` `bonjour` ? *(Crossplane supprime aussi le ConfigMap : `deletionPolicy: Delete` par défaut.)*

Cliquez sur **Vérifier**.
