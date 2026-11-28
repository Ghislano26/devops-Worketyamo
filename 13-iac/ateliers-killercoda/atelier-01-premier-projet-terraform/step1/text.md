# Étape 1 : écrire, planifier, appliquer

Créez le projet dans `~/tf-premier` :

```bash
cd ~/tf-premier
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.5"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "nom" {
  type        = string
  description = "Nom à saluer"
  default     = "Kamer Logistics"
}

resource "local_file" "bienvenue" {
  filename        = "${path.module}/sortie/bienvenue.txt"
  content         = "Bonjour ${var.nom} !\n"
  file_permission = "0644"
}

output "chemin" {
  value = local_file.bienvenue.filename
}
EOF
terraform fmt
```{{exec}}

Initialisez le projet : Terraform télécharge le **provider** `local` depuis le registre et crée le fichier de verrou `.terraform.lock.hcl`.

```bash
terraform init
terraform validate
```{{exec}}

Lisez le **plan** : rien n'est créé, mais Terraform annonce ce qui **va** l'être (`+` = créer).

```bash
terraform plan
```{{exec}}

Appliquez, puis observez le résultat et le **state** :

```bash
terraform apply -auto-approve
cat sortie/bienvenue.txt
terraform output
terraform state list
terraform state show local_file.bienvenue | head -n 12
ls -la
```{{exec}}

Terraform a créé `sortie/bienvenue.txt` **et** le fichier d'état `terraform.tfstate`, qui relie le bloc `local_file.bienvenue` au fichier réel.

Relancez le plan : l'infrastructure est conforme, il n'y a **rien** à faire (**idempotence**).

```bash
terraform plan
terraform plan -detailed-exitcode >/dev/null; echo "code de sortie : $?"    # 0 = aucun changement, 2 = changements prévus
```{{exec}}

## Questions

- Que contient `terraform.tfstate` ? Pourquoi **ne faut-il jamais** le commiter dans Git ? *(Il peut contenir des secrets en clair.)*
- Que signifie le code de sortie `0` de `plan -detailed-exitcode` ? *(Aucun écart : très utile pour détecter la dérive en CI.)*

Cliquez sur **Vérifier**.
