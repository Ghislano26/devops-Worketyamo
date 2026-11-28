# Bravo !

Vous avez fait tourner un **AWS local** :

| Étape | Ce que vous avez vu |
|---|---|
| LocalStack | Un émulateur d'API AWS dans un conteneur Docker (`localhost:4566`) |
| `awscli` | Un client qui ne fait qu'appeler l'API ; `endpoint_url` le dirige vers l'émulateur |
| S3 | `mb`, `cp`, `ls`, et l'API bas niveau `s3api` |
| Limites | Données éphémères, fonctions avancées absentes : **un émulateur n'est pas AWS** |

## Défi bonus

1. Créez un second bucket `mon-site-statique`, envoyez un `index.html`, puis lancez `aws s3 sync ./site s3://mon-site-statique --delete`.
2. Générez une **URL présignée** : `aws s3 presign s3://mon-premier-bucket/bonjour.txt --expires-in 300`, puis ouvrez-la avec `curl` (le chemin passe par LocalStack).
3. Redémarrez LocalStack (`docker restart localstack`) et constatez ce qui persiste (rien, sauf configuration).
4. Pointez **Terraform** vers LocalStack (`endpoints { s3 = "http://localhost:4566" }` dans le provider `aws`) et décrivez le bucket en code : voir le [module IaC](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/README.md).

## Pour aller plus loin

- [Fondamentaux du cloud](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/01-fondamentaux-cloud.md) · [S3, EBS et EFS](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/05-aws-stockage-s3-ebs-efs.md).
- Suite : [atelier 2 — S3 avec awscli](https://github.com/Ghislano26/devops-Worketyamo/tree/main/14-cloud-aws/ateliers-killercoda/atelier-02-s3-avec-awscli) (versioning, restauration, cycle de vie).
