# Étape 2 : créer un bucket S3 et y déposer un fichier

**S3** stocke des **objets** dans des **buckets** ([cours stockage](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/05-aws-stockage-s3-ebs-efs.md)). Créez-en un et envoyez-y un fichier :

```bash
mkdir -p ~/s3-premiers-pas && cd ~/s3-premiers-pas
echo "Bonjour depuis LocalStack" > bonjour.txt
aws s3 mb s3://mon-premier-bucket
aws s3 cp bonjour.txt s3://mon-premier-bucket/bonjour.txt
```{{exec}}

Listez, inspectez, puis relisez l'objet :

```bash
aws s3 ls
aws s3 ls s3://mon-premier-bucket/
aws s3api head-object --bucket mon-premier-bucket --key bonjour.txt
aws s3 cp s3://mon-premier-bucket/bonjour.txt -
```{{exec}}

Deux familles de commandes coexistent :

| Famille | Niveau | Exemples |
|---|---|---|
| **`aws s3`** | **Haut niveau**, pratique (`cp`, `ls`, `mb`, `rm`, `sync`) | `aws s3 cp fichier s3://bucket/` |
| **`aws s3api`** | **Bas niveau** : correspond **une à une** aux appels de l'API | `aws s3api put-bucket-versioning`, `list-objects-v2`, `head-object` |

Chaque `aws s3api …` correspond à **un appel d'API** documenté, utilisable dans n'importe quel SDK : c'est la même API que Terraform appelle.

```bash
aws s3api list-buckets --query 'Buckets[].Name' --output text
aws s3api list-objects-v2 --bucket mon-premier-bucket --query 'Contents[].[Key,Size]' --output table
```{{exec}}

## Questions

- Pourquoi les identifiants `test` ne sont-ils **pas** un problème ici, mais seraient une faute grave sur un vrai compte ? *(Aucun accès réel : l'émulateur ignore les clés ; un vrai compte exige des identifiants secrets.)*
- Que se passe-t-il pour le bucket si vous arrêtez le conteneur (`docker rm -f localstack`) ? *(Les données sont perdues : c'est un émulateur éphémère.)*

Cliquez sur **Vérifier**.
