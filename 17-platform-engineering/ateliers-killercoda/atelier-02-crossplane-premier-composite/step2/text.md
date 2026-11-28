# Étape 2 : définir une API (XRD), une Composition et créer un composite

Vous passez du côté **équipe plateforme** : on définit une **API de plus haut niveau**, `XWebApp`, où le développeur ne précise que **le nom, l'image et le nombre de réplicas**. La **Composition** traduit cela en un `Deployment` **et** un `Service`.

## A. L'API (XRD) et la recette (Composition)

```bash
cd ~/crossplane-lab
cat > xrd.yaml <<'EOF'
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xwebapps.platform.worketyamo.org
spec:
  group: platform.worketyamo.org
  names:
    kind: XWebApp
    plural: xwebapps
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                parameters:
                  type: object
                  properties:
                    name:
                      type: string
                    image:
                      type: string
                    replicas:
                      type: integer
                      default: 1
                      minimum: 1
                      maximum: 5
                  required: [name, image]
              required: [parameters]
EOF
cat > composition.yaml <<'EOF'
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: webapp-kubernetes
spec:
  compositeTypeRef:
    apiVersion: platform.worketyamo.org/v1alpha1
    kind: XWebApp
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: deployment
            base:
              apiVersion: kubernetes.crossplane.io/v1alpha2
              kind: Object
              spec:
                providerConfigRef:
                  name: default
                forProvider:
                  manifest:
                    apiVersion: apps/v1
                    kind: Deployment
                    metadata:
                      namespace: apps-plateforme
                    spec:
                      replicas: 1
                      selector:
                        matchLabels: {}
                      template:
                        metadata:
                          labels: {}
                        spec:
                          containers:
                            - name: app
                              image: placeholder
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.name
                toFieldPath: spec.forProvider.manifest.metadata.name
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.name
                toFieldPath: spec.forProvider.manifest.spec.selector.matchLabels.app
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.name
                toFieldPath: spec.forProvider.manifest.spec.template.metadata.labels.app
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.replicas
                toFieldPath: spec.forProvider.manifest.spec.replicas
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.image
                toFieldPath: spec.forProvider.manifest.spec.template.spec.containers[0].image
          - name: service
            base:
              apiVersion: kubernetes.crossplane.io/v1alpha2
              kind: Object
              spec:
                providerConfigRef:
                  name: default
                forProvider:
                  manifest:
                    apiVersion: v1
                    kind: Service
                    metadata:
                      namespace: apps-plateforme
                    spec:
                      selector: {}
                      ports:
                        - port: 80
                          targetPort: 80
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.name
                toFieldPath: spec.forProvider.manifest.metadata.name
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.name
                toFieldPath: spec.forProvider.manifest.spec.selector.app
EOF
kubectl apply -f xrd.yaml
kubectl wait xrd/xwebapps.platform.worketyamo.org --for=condition=Established --timeout=120s
kubectl apply -f composition.yaml
kubectl get xrd,composition
```{{exec}}

Le XRD a créé un **nouveau type d'objet** Kubernetes : `kubectl api-resources | grep worketyamo` le confirme. Notez dans le schéma la **borne** `maximum: 5` sur `replicas` : la plateforme impose ses limites.

```bash
kubectl api-resources | grep worketyamo
```{{exec}}

## B. La demande (ressource composite)

```bash
cd ~/crossplane-lab
cat > xwebapp.yaml <<'EOF'
apiVersion: platform.worketyamo.org/v1alpha1
kind: XWebApp
metadata:
  name: boutique
spec:
  parameters:
    name: boutique
    image: nginx:1.27-alpine
    replicas: 2
EOF
kubectl apply -f xwebapp.yaml
kubectl wait xwebapp/boutique --for=condition=Ready --timeout=300s
kubectl get xwebapp
kubectl get object
```{{exec}}

La ressource composite est **`Synced`** et **`Ready`** ; deux `Object` ont été créés par la Composition. Vérifiez les **ressources réelles** :

```bash
kubectl -n apps-plateforme get deployment,service,pods
kubectl -n apps-plateforme get deployment boutique -o jsonpath='{.spec.replicas} réplicas, image {.spec.template.spec.containers[0].image}{"\n"}'
kubectl describe xwebapp boutique | tail -n 25
```{{exec}}

## C. La réconciliation : changer la demande

On modifie la **demande** (pas le Deployment) : `replicas: 3`. Crossplane répercute le changement.

```bash
kubectl patch xwebapp boutique --type merge -p '{"spec":{"parameters":{"replicas":3}}}'
sleep 15
kubectl -n apps-plateforme get deployment boutique -o jsonpath='{.spec.replicas}{" réplicas\n"}'
kubectl -n apps-plateforme get pods
```{{exec}}

Essayez ensuite de dépasser la **borne** imposée par l'API :

```bash
kubectl patch xwebapp boutique --type merge -p '{"spec":{"parameters":{"replicas":9}}}'; echo "code de sortie : $?"
```{{exec}}

Le serveur d'API **refuse** (`should be less than or equal to 5`) : la plateforme **garantit** ses limites **avant** toute création.

> ⚠️ **Attention** : une fois la borne testée, **laissez `replicas` à 3** pour la vérification.

## Questions

- Qui décide de **la façon** de créer le Deployment : le développeur ou la plateforme ? *(La plateforme : le développeur ne connaît que l'API `XWebApp`.)*
- Quel avantage de changer la Composition plus tard (ajouter un `PodDisruptionBudget`, une `NetworkPolicy`) ? *(Toutes les XR existantes sont **réconciliées** vers la nouvelle recette : changement de plateforme en un seul endroit.)*

Cliquez sur **Vérifier**.
