# Étape 1 : versioning et deux versions d'un fichier

Créez le bucket, **activez le versioning**, puis envoyez **deux versions** du même fichier. On garde l'identifiant de chaque version.

```bash
mkdir -p ~/s3-versions && cd ~/s3-versions
aws s3 mb s3://archives-worketyamo
aws s3api put-bucket-versioning --bucket archives-worketyamo --versioning-configuration Status=Enabled
aws s3api get-bucket-versioning --bucket archives-worketyamo

echo "rapport version 1" > rapport.txt
V1=$(aws s3api put-object --bucket archives-worketyamo --key rapport.txt --body rapport.txt --query VersionId --output text)
echo "rapport version 2 (avec une erreur)" > rapport.txt
V2=$(aws s3api put-object --bucket archives-worketyamo --key rapport.txt --body rapport.txt --query VersionId --output text)
echo "V1=$V1"; echo "V2=$V2"
echo "export V1=$V1 V2=$V2" > versions.env
```{{exec}}

Observez les **deux versions** et la version **courante** :

```bash
aws s3api list-object-versions --bucket archives-worketyamo --prefix rapport.txt \
  --query 'Versions[].[VersionId,IsLatest,Size]' --output table
aws s3 cp s3://archives-worketyamo/rapport.txt -          # lit la version COURANTE (la 2)
```{{exec}}

La version 2 contient une **erreur** : dans la vraie vie, quelqu'un vient d'écraser le bon rapport.

## Questions

- Que serait devenue la version 1 **sans** versioning ? *(Écrasée, définitivement perdue.)*
- Qui paie les anciennes versions ? *(Vous : chaque version est facturée ; d'où les règles de cycle de vie, étape 3.)*

Cliquez sur **Vérifier**.
