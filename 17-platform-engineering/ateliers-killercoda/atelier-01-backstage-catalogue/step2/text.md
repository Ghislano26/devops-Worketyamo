# Étape 2 : ajouter une entité au catalogue

Un second composant, **`boutique-web`** (le site), **dépend de** l'API. On l'ajoute au fichier, on met à jour le ConfigMap et on **redémarre** Backstage pour qu'il relise le catalogue (en production, le catalogue se **rafraîchit tout seul** à intervalles réguliers et lit les fichiers **dans les dépôts Git**).

```bash
cd ~/backstage-lab
cat >> catalog-info.yaml <<'EOF'
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: boutique-web
  description: Site web de la boutique
  tags: [web, react]
spec:
  type: website
  lifecycle: experimental
  owner: equipe-boutique
  system: boutique
  dependsOn:
    - component:boutique-api
EOF
kubectl -n backstage create configmap catalogue --from-file=catalog-info.yaml --dry-run=client -o yaml | kubectl apply -f -
kubectl -n backstage rollout restart deployment -l app.kubernetes.io/name=backstage
kubectl -n backstage rollout status deployment -l app.kubernetes.io/name=backstage --timeout=300s
```{{exec}}

> Attendez la fin du redémarrage (1 à 3 minutes) : l'application doit relire le catalogue au démarrage.

Listez de nouveau les entités et leurs relations :

```bash
POD=$(kubectl -n backstage get pod -l app.kubernetes.io/name=backstage -o name | head -n1)
sleep 30
kubectl -n backstage exec "$POD" -- node -e "fetch('http://localhost:7007/api/catalog/entities').then(r=>r.json()).then(e=>e.forEach(x=>console.log(x.kind+'/'+x.metadata.name+' -> '+(x.relations||[]).map(y=>y.type+':'+y.targetRef).join(', '))))"
```{{exec}}

Vous devez voir `Component/boutique-web` avec **`dependsOn:component:default/boutique-api`**, et `Component/boutique-api` avec la relation inverse **`dependencyOf`** : le catalogue crée **les deux sens** d'une relation.

Interrogez le graphe pour répondre à une question réelle : « **qui dépend de l'API ?** »

```bash
POD=$(kubectl -n backstage get pod -l app.kubernetes.io/name=backstage -o name | head -n1)
kubectl -n backstage exec "$POD" -- node -e "fetch('http://localhost:7007/api/catalog/entities/by-name/component/default/boutique-api').then(r=>r.json()).then(x=>console.log((x.relations||[]).filter(y=>y.type==='dependencyOf').map(y=>y.targetRef).join(', ')))"
```{{exec}}

Dans l'interface web (page *Catalog*), la page de `boutique-api` affiche aussi un **graphe de relations** et l'onglet des dépendances.

## Questions

- Dans quel dépôt vivrait **réellement** le `catalog-info.yaml` de `boutique-web` ? *(Dans le dépôt du service lui-même, relu par Backstage ; ainsi la description évolue avec le code.)*
- Que fait-on contre un catalogue qui **se périme** ? *(Alimentation automatique : modèles de création, découverte GitHub, et mesure de complétude : [cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/03-backstage-portal.md).)*

Cliquez sur **Vérifier**.
