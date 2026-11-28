# Bravo !

Vous avez parcouru le cycle complet d'un projet Terraform :

| Étape | Commande | Ce que vous avez vu |
|---|---|---|
| Initialiser | `terraform init` | Téléchargement du provider, fichier de verrou |
| Prévoir | `terraform plan` | `+` créer, `-/+` remplacer ; **toujours relire** |
| Appliquer | `terraform apply` | Création de la ressource et du **state** |
| Idempotence | `plan` sans changement | Code de sortie `0` |
| Dérive | modification manuelle | Le plan détecte l'écart |
| Détruire | `terraform destroy` | Ressource supprimée, state vide |

## Défi bonus : plusieurs fichiers avec `for_each`

1. Ajoutez une variable `services` de type `map(string)` (`web = "80"`, `api = "8080"`, `db = "5432"`).
2. Créez **une ressource `local_file` par service** avec `for_each = var.services` et `filename = "${path.module}/sortie/${each.key}.conf"`.
3. Appliquez, puis **supprimez** `api` de la map : le plan doit détruire **uniquement** `api.conf` (c'est l'avantage de `for_each` sur `count`).
4. Ajoutez `lifecycle { prevent_destroy = true }` à une ressource et constatez que `terraform destroy` **refuse** de la détruire.

## Pour aller plus loin

- [Introduction à l'IaC](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/01-introduction-iac.md) · [Terraform : les fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/02-terraform-fondamentaux.md) · [Terraform avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/03-terraform-avance.md).
- Essayez **OpenTofu** : remplacez `terraform` par `tofu` (<https://opentofu.org/docs/intro/install/>).
- Suite : [atelier 2 — playbook Ansible idempotent](https://github.com/Ghislano26/devops-Worketyamo/tree/main/13-iac/ateliers-killercoda/atelier-02-ansible-playbook-idempotent).
