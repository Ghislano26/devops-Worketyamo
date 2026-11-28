# Étape 2 : tester avec l'utilisateur, puis corriger la policy

## A. Donner des identifiants à `lecteur`

```bash
cd ~/iam-lab
read -r AKID SECRET <<< "$(aws iam create-access-key --user-name lecteur --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)"
aws configure set aws_access_key_id "$AKID" --profile lecteur
aws configure set aws_secret_access_key "$SECRET" --profile lecteur
aws configure set region eu-west-3 --profile lecteur
aws configure set endpoint_url http://localhost:4566 --profile lecteur
aws iam list-access-keys --user-name lecteur --query 'AccessKeyMetadata[].[AccessKeyId,Status]' --output table
```{{exec}}

> Sur un vrai compte, ces clés sont des **secrets durables** : à protéger, à faire tourner, et à éviter au profit de **rôles** ([cours IAM](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/02-aws-iam-et-securite.md)).

## B. Tester la lecture et l'écriture

```bash
cd ~/iam-lab
aws --profile lecteur s3 cp s3://donnees-worketyamo/rapport.txt -      # lecture : OK
echo "tentative d'écriture" > ecriture.txt
aws --profile lecteur s3 cp ecriture.txt s3://donnees-worketyamo/ecriture.txt \
  && echo ">>> écriture ACCEPTÉE par l'émulateur" || echo ">>> écriture refusée"
```{{exec}}

Sur le **vrai AWS**, la dernière commande échouerait avec `AccessDenied` (« no identity-based policy allows the s3:PutObject action »). Ici, **selon la version de LocalStack, l'écriture peut réussir** : l'édition communautaire n'applique pas les policies. **C'est la limite à retenir** : un émulateur ne prouve **pas** que vos permissions sont correctes. Votre **évaluateur** donne, lui, le verdict d'AWS :

```bash
cd ~/iam-lab
./evaluer-policy.py actuelle.json s3:PutObject arn:aws:s3:::donnees-worketyamo/ecriture.txt; echo "code de sortie : $?"
```{{exec}}

## C. Corriger la policy : écrire, mais seulement dans `uploads/`

Le besoin évolue : `lecteur` doit pouvoir **déposer** des fichiers, mais **uniquement** dans le préfixe `uploads/` (pas partout, pas de suppression). On **ne modifie pas** la policy : on crée une **nouvelle version** et on la rend **par défaut** (IAM garde jusqu'à 5 versions, ce qui permet un retour arrière).

```bash
cd ~/iam-lab
cat > politique-v2.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListerLeBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::donnees-worketyamo"
    },
    {
      "Sid": "LireLesObjets",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::donnees-worketyamo/*"
    },
    {
      "Sid": "EcrireSeulementDansUploads",
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::donnees-worketyamo/uploads/*"
    }
  ]
}
EOF
ARN=$(cat policy.arn)
aws iam create-policy-version --policy-arn "$ARN" --policy-document file://politique-v2.json --set-as-default
aws iam list-policy-versions --policy-arn "$ARN" --query 'Versions[].[VersionId,IsDefaultVersion]' --output table
aws iam get-policy-version --policy-arn "$ARN" --version-id v2 --query PolicyVersion.Document > actuelle-v2.json
```{{exec}}

Testez la **nouvelle** policy avec l'évaluateur :

```bash
cd ~/iam-lab
./evaluer-policy.py actuelle-v2.json s3:PutObject arn:aws:s3:::donnees-worketyamo/uploads/ok.txt   # ALLOW
./evaluer-policy.py actuelle-v2.json s3:PutObject arn:aws:s3:::donnees-worketyamo/ecriture.txt     # DENY (hors uploads/)
./evaluer-policy.py actuelle-v2.json s3:DeleteObject arn:aws:s3:::donnees-worketyamo/uploads/ok.txt # DENY
./evaluer-policy.py actuelle-v2.json s3:GetObject arn:aws:s3:::donnees-worketyamo/rapport.txt       # ALLOW
```{{exec}}

## Questions

- Pourquoi créer une **nouvelle version** plutôt que modifier la policy existante ? *(Traçabilité et retour arrière possible : `set-default-policy-version`.)*
- Pourquoi ne pas simplement attacher `AmazonS3FullAccess` ? *(Contraire du moindre privilège : l'utilisateur pourrait tout lire, écrire et supprimer dans **tous** les buckets du compte.)*

Cliquez sur **Vérifier**.
