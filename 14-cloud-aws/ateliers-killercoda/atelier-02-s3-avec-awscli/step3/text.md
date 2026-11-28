# Étape 3 : une règle de cycle de vie

Les anciennes versions, les journaux et les fichiers temporaires s'accumulent et coûtent cher. Les **règles de cycle de vie** automatisent leur sort (voir le [cours stockage](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/05-aws-stockage-s3-ebs-efs.md) et le [cours coûts](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/06-aws-couts-finops-intro.md)).

Écrivez trois règles :

| Règle | Effet |
|---|---|
| `expirer-tmp` | Supprime les objets du préfixe `tmp/` après **7 jours** |
| `archiver-logs` | Déplace `logs/` vers **STANDARD_IA** à 30 jours, puis **GLACIER** à 90 jours |
| `purger-anciennes-versions` | Supprime les versions **non courantes** après 30 jours |

```bash
cd ~/s3-versions
cat > lifecycle.json <<'EOF'
{
  "Rules": [
    {
      "ID": "expirer-tmp",
      "Status": "Enabled",
      "Filter": { "Prefix": "tmp/" },
      "Expiration": { "Days": 7 }
    },
    {
      "ID": "archiver-logs",
      "Status": "Enabled",
      "Filter": { "Prefix": "logs/" },
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" },
        { "Days": 90, "StorageClass": "GLACIER" }
      ]
    },
    {
      "ID": "purger-anciennes-versions",
      "Status": "Enabled",
      "Filter": { "Prefix": "" },
      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 }
    }
  ]
}
EOF
aws s3api put-bucket-lifecycle-configuration --bucket archives-worketyamo --lifecycle-configuration file://lifecycle.json
aws s3api get-bucket-lifecycle-configuration --bucket archives-worketyamo --query 'Rules[].[ID,Status]' --output table
```{{exec}}

> LocalStack **enregistre** la configuration mais n'**attend pas** 7, 30 ou 90 jours pour l'appliquer : on vérifie la **règle**, pas son exécution. Dans le vrai AWS, S3 l'applique de lui-même, une fois par jour environ.

Relisez la configuration complète :

```bash
aws s3api get-bucket-lifecycle-configuration --bucket archives-worketyamo
```{{exec}}

## Questions

- Pourquoi `Filter` avec un `Prefix` vide pour la purge des anciennes versions ? *(Elle s'applique à **tout** le bucket.)*
- Quel risque comporte une règle d'**expiration** mal ciblée ? *(Supprimer des données utiles : testez d'abord sur un préfixe isolé.)*

Cliquez sur **Vérifier**.
