# Bravo !

Vous avez fait le travail d'une équipe plateforme avec Crossplane :

| Notion | Ce que vous avez vu |
|---|---|
| **Provider** | `provider-kubernetes` + `ProviderConfig` (identité du pod) + droits RBAC |
| **Managed Resource** | Un `Object` qui crée **réellement** un ConfigMap |
| **XRD** | Une **nouvelle API** `XWebApp` avec schéma, valeurs par défaut et **bornes** |
| **Composition** | La **recette** en pipeline : `Deployment` + `Service` à partir de 3 paramètres |
| **Composite (XR)** | La **demande** ; statut `Ready` / `Synced` ; réconciliation quand on la modifie |

## Défi bonus

1. Ajoutez à la Composition une **troisième ressource** (un `PodDisruptionBudget` ou une `NetworkPolicy`) : la XR existante est-elle mise à jour sans que vous touchiez à `xwebapp.yaml` ?
2. Ajoutez un paramètre `taille: petite | moyenne | grande` (avec `enum`) et traduisez-le en requests / limits via une table de transformation (`type: map` dans un patch).
3. Créez une **seconde XR** (`blog`) : deux applications, une seule recette.
4. **Provider AWS** (sur votre propre machine) : démarrez **LocalStack** ([module Cloud AWS](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/ateliers-killercoda/README.md)), installez `provider-aws-s3` avec un `ProviderConfig` pointant vers `http://localhost:4566` et créez un `Bucket` ; comparez avec l'`Object` de cet atelier.
5. Combinez avec **Argo CD** ([module GitOps](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/README.md)) : stockez `xwebapp.yaml` dans Git et laissez Argo CD le synchroniser.

## Pour aller plus loin

- [Crossplane](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/04-crossplane-control-plane.md) · [Golden paths](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/05-golden-paths-et-templates.md) · [La plateforme interne (IDP)](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/02-internal-developer-platform.md).
- Retour au [module 17](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/README.md).
