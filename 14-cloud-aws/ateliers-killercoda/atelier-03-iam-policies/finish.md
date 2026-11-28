# Bravo !

Vous avez appliqué le **moindre privilège** de bout en bout :

| Étape | Ce que vous avez fait |
|---|---|
| Identité | Un utilisateur `lecteur` **sans aucun droit** au départ |
| Policy | JSON : **ListBucket** sur le bucket, **GetObject** sur les objets |
| Test | Un **évaluateur** reproduisant la logique d'AWS (refus par défaut, `Deny` explicite prioritaire) |
| Limite | Un émulateur **n'applique pas** forcément les policies : ne jamais s'y fier pour la sécurité |
| Correction | **Nouvelle version** de la policy : écriture **uniquement** dans `uploads/` |

## Défi bonus

1. Ajoutez à la policy un `Deny` **explicite** sur `s3:DeleteObject` pour `donnees-worketyamo/*` et vérifiez, avec l'évaluateur, qu'il **l'emporte** même si vous ajoutez ensuite un `Allow` plus large.
2. Créez un **rôle** (`aws iam create-role --assume-role-policy-document …` avec une **politique de confiance**) puis testez `aws sts assume-role` : observez les **identifiants temporaires**. Voir le [cours IAM](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/02-aws-iam-et-securite.md).
3. Ajoutez une **condition** (`aws:SecureTransport`, adresse IP) : l'évaluateur la refuse volontairement (« Non supporté ») ; réfléchissez à ce qu'il faudrait pour la gérer, ou utilisez le **Policy Simulator** d'un vrai compte.
4. Décrivez utilisateur, policy et attachement en **Terraform** (`aws_iam_user`, `aws_iam_policy`, `aws_iam_user_policy_attachment`) : voir le [module IaC](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/README.md).

## Pour aller plus loin

- [IAM et sécurité](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/02-aws-iam-et-securite.md) · [Sécurité dans la CI (OIDC)](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/06-securite-dans-la-ci.md).
- Sur un vrai compte : **IAM Access Analyzer** (générer une policy depuis l'activité réelle), `aws iam simulate-principal-policy`.
- Retour au [module 14](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/README.md).
