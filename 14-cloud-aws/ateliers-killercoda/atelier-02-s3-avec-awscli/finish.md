# Bravo !

Vous avez mis en place les protections de base d'un bucket S3 :

| Notion | Ce que vous avez fait |
|---|---|
| **Versioning** | Chaque écrasement ajoute une version |
| **Restauration** | Récupération d'une version précédente par son identifiant |
| **Marqueur de suppression** | `rm` ne détruit rien ; on retire le marqueur |
| **Cycle de vie** | Expiration, transitions de classe, purge des anciennes versions |

## Défi bonus

1. Ajoutez une **bucket policy** qui refuse tout accès non chiffré en transit (`aws:SecureTransport` = `false`) avec `aws s3api put-bucket-policy` ; relisez-la avec `get-bucket-policy`. *(LocalStack stocke la policy sans forcément l'appliquer.)*
2. Activez le chiffrement par défaut : `aws s3api put-bucket-encryption --bucket archives-worketyamo --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'`.
3. Ajoutez des **étiquettes** (`put-bucket-tagging` : `Equipe`, `Environnement`) et réfléchissez à leur rôle dans la [maîtrise des coûts](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/06-aws-couts-finops-intro.md).
4. Écrivez la même configuration en **Terraform** (`aws_s3_bucket_versioning`, `aws_s3_bucket_lifecycle_configuration`) : voir le [module IaC](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/README.md).

## Pour aller plus loin

- [Stockage : S3, EBS et EFS](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/05-aws-stockage-s3-ebs-efs.md) · [Coûts et FinOps](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/06-aws-couts-finops-intro.md).
- Suite : [atelier 3 — IAM et policies](https://github.com/Ghislano26/devops-Worketyamo/tree/main/14-cloud-aws/ateliers-killercoda/atelier-03-iam-policies).
