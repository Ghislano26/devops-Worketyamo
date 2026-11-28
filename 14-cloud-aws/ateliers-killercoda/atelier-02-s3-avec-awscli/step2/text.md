# Étape 2 : restaurer une version précédente, puis une suppression

## A. Restaurer la version 1

On **télécharge** l'ancienne version (par son identifiant), puis on la **renvoie** : elle devient la **nouvelle version courante**. L'historique n'est jamais réécrit.

```bash
cd ~/s3-versions && source versions.env
aws s3api get-object --bucket archives-worketyamo --key rapport.txt --version-id "$V1" ancienne.txt
cat ancienne.txt
aws s3 cp ancienne.txt s3://archives-worketyamo/rapport.txt
aws s3 cp s3://archives-worketyamo/rapport.txt -
aws s3api list-object-versions --bucket archives-worketyamo --prefix rapport.txt \
  --query 'Versions[].[VersionId,IsLatest]' --output table
```{{exec}}

Il y a maintenant **trois** versions : la 1, la 2 (erronée) et une **troisième** qui a le contenu de la 1.

## B. Supprimer, puis récupérer

Avec le versioning, `rm` **ne détruit rien** : il ajoute un **marqueur de suppression**.

```bash
aws s3 rm s3://archives-worketyamo/rapport.txt
aws s3 ls s3://archives-worketyamo/ || echo "(le bucket paraît vide)"
aws s3api list-object-versions --bucket archives-worketyamo --prefix rapport.txt \
  --query 'DeleteMarkers[].[VersionId,IsLatest]' --output table
```{{exec}}

L'objet « a disparu », mais toutes ses versions sont là. **Supprimez le marqueur** pour le faire réapparaître :

```bash
M=$(aws s3api list-object-versions --bucket archives-worketyamo --prefix rapport.txt \
      --query 'DeleteMarkers[?IsLatest].VersionId | [0]' --output text)
echo "Marqueur à retirer : $M"
aws s3api delete-object --bucket archives-worketyamo --key rapport.txt --version-id "$M"
aws s3 cp s3://archives-worketyamo/rapport.txt -
```{{exec}}

## Questions

- Pourquoi dit-on que le versioning protège d'une **erreur humaine** et de certains **rançongiciels** ? *(L'écrasement et la suppression ne détruisent pas les données.)*
- Comment supprimer **définitivement** un objet versionné ? *(En supprimant **chaque version** par son identifiant.)*

Cliquez sur **Vérifier**.
