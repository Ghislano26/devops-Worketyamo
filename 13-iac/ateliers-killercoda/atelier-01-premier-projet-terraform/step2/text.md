# Étape 2 : modifier, détecter une dérive, détruire

## A. Modifier une variable

Donnez une valeur à la variable `nom` **dans un fichier** (chargé automatiquement) :

```bash
cd ~/tf-premier
echo 'nom = "Worketyamo"' > terraform.tfvars
terraform plan
```{{exec}}

Remarquez le symbole **`-/+`** : pour `local_file`, un changement de contenu impose de **détruire puis recréer** la ressource (« must be replaced »). **Lisez toujours le plan** : sur une vraie base de données, ce symbole signifie *perte de données*.

```bash
terraform apply -auto-approve
cat sortie/bienvenue.txt
```{{exec}}

## B. Provoquer et détecter une dérive

Quelqu'un modifie le fichier **à la main**, hors de Terraform :

```bash
echo "modifié à la main" > sortie/bienvenue.txt
terraform plan -no-color | tee plan-derive.txt
```{{exec}}

Terraform **compare le code, le state et la réalité** : il voit l'écart et propose de **corriger**. Appliquez pour revenir à l'état décrit par le code :

```bash
terraform apply -auto-approve
cat sortie/bienvenue.txt
```{{exec}}

> Si le plan annonce « No changes » alors que vous avez modifié le fichier, vérifiez que vous avez bien écrit dans `~/tf-premier/sortie/bienvenue.txt`.

## C. Détruire

```bash
terraform destroy -auto-approve
ls sortie/
terraform state list
```{{exec}}

Le fichier a disparu et le state est vide. Le fichier `terraform.tfstate.backup` garde l'état **avant** la dernière opération.

## Questions

- Pourquoi un changement manuel « juste pour tester » est-il dangereux ? *(Dérive : le prochain `apply` l'annulera, ou personne n'osera plus relancer l'outil.)*
- Dans quel cas la **vraie** destruction (`destroy`) d'une ressource est-elle protégée ? *(`lifecycle { prevent_destroy = true }` : voir le [cours avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/03-terraform-avance.md).)*

Cliquez sur **Vérifier**.
