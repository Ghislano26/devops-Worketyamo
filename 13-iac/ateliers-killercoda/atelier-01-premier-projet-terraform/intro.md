# Premier projet Terraform

**Durée : ~25 minutes.** Compétence travaillée : écrire, planifier, appliquer et détruire une infrastructure décrite en **HCL**, et comprendre le rôle du **state**.

Rappel du [cours Terraform : les fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/02-terraform-fondamentaux.md) :

```text
init → plan (toujours relu) → apply → state → destroy
```

L'infrastructure de cet atelier est volontairement **locale** : le provider `local` crée un **fichier** sur la machine. Aucun compte cloud n'est nécessaire, mais les mécanismes (plan, state, dérive) sont **exactement** ceux d'un vrai cloud.

## Mise en place : installer Terraform

```bash
apt-get update -qq && apt-get install -y -qq unzip curl >/dev/null
TF_VERSION=1.9.8
curl -fsSL -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
unzip -oq /tmp/terraform.zip -d /usr/local/bin
terraform version
mkdir -p ~/tf-premier
```{{exec}}

> Terraform est distribué sous licence **BSL**. Son fork libre **OpenTofu** (`tofu`) fonctionne de la même façon avec les mêmes fichiers `.tf` : voir le [cours Terraform avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/03-terraform-avance.md).
