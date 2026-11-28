# Bravo !

Vous avez fait fonctionner le cœur d'un portail développeur :

| Notion | Ce que vous avez vu |
|---|---|
| **Déploiement** | Backstage par **Helm**, configuré par `app-config` (valeurs du chart) |
| **`catalog-info.yaml`** | Plusieurs entités dans un fichier : **Group**, **System**, **Component** |
| **Relations** | `ownedBy`, `partOf`, `dependsOn` et leurs **inverses**, **déduites** des champs |
| **API du catalogue** | Interroger le graphe (« qui dépend de l'API ? ») |
| **Limites** | Image de démonstration, base en mémoire, authentification désactivée : **pas pour la production** |

## Défi bonus

1. Ajoutez une entité **`API`** (`kind: API`, `type: openapi`) et reliez-la au composant avec `providesApis` / `consumesApis`.
2. Ajoutez une **`Resource`** (`boutique-db`, `type: database`) et un `dependsOn: [resource:boutique-db]`.
3. Écrivez un fichier `Template` (voir le [cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/03-backstage-portal.md) et le [cours 5](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/05-golden-paths-et-templates.md)) et enregistrez-le comme location ; observez la page *Create*.
4. Remplacez la location `file` par une location **`url`** vers un dépôt Git public contenant un `catalog-info.yaml`.
5. Listez les points à changer pour passer en production : **PostgreSQL**, **authentification OIDC**, **image construite par la CI**, **secrets**.

## Pour aller plus loin

- [La plateforme interne (IDP)](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/02-internal-developer-platform.md) · [Backstage](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/03-backstage-portal.md) · [Golden paths](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/05-golden-paths-et-templates.md).
- Suite : [atelier 2 — Crossplane](https://github.com/Ghislano26/devops-Worketyamo/tree/main/17-platform-engineering/ateliers-killercoda/atelier-02-crossplane-premier-composite).
