# Étape 1 : installer Kyverno et créer la politique

## A. Installer Helm et Kyverno

```bash
command -v helm >/dev/null 2>&1 || {
  curl -fsSL -o /tmp/get-helm-3.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 /tmp/get-helm-3.sh && /tmp/get-helm-3.sh --version v3.16.3
}
helm version --short
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace --version 3.3.4 --wait --timeout 8m
kubectl -n kyverno get pods
```{{exec}}

Kyverno installe **plusieurs contrôleurs** : `admission-controller` (le webhook qui valide les requêtes), `background-controller`, `cleanup-controller` et `reports-controller` (rapports de conformité). Attendez qu'ils soient tous prêts :

```bash
kubectl -n kyverno wait --for=condition=Available deployment --all --timeout=300s
kubectl get crd | grep kyverno.io | head -n 5
```{{exec}}

## B. La politique

On crée une `ClusterPolicy` avec **deux règles** : (1) l'image doit **avoir un tag** (sans tag, Docker utilise `latest` implicitement), (2) ce tag **ne doit pas être `latest`**. Le mode est **`Enforce`** : les pods non conformes sont **refusés**.

```bash
cat > interdire-latest.yaml <<'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: interdire-latest
  annotations:
    policies.kyverno.io/title: Interdire le tag latest
    policies.kyverno.io/severity: medium
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: tag-obligatoire
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "Une image sans tag est interdite : indiquez un tag précis."
        pattern:
          spec:
            containers:
              - image: "*:*"
    - name: pas-de-latest
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "Le tag ':latest' est interdit : utilisez une version précise ou un digest."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
EOF
kubectl apply -f interdire-latest.yaml
sleep 5
kubectl get clusterpolicy
```{{exec}}

La colonne **READY** doit passer à `True`. Examinez la politique telle que Kyverno la voit :

```bash
kubectl get clusterpolicy interdire-latest -o jsonpath='{.spec.validationFailureAction}{"\n"}'
kubectl describe clusterpolicy interdire-latest | tail -n 15
```{{exec}}

## Questions

- Pourquoi deux règles ? *(`nginx` sans tag équivaut à `nginx:latest` : il faut exiger un tag **et** interdire `latest`.)*
- Pourquoi `background: true` ? *(Kyverno contrôle aussi les ressources **déjà présentes** et alimente les rapports de conformité.)*

Cliquez sur **Vérifier**.
