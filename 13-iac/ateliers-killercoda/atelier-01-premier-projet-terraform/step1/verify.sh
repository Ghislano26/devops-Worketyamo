#!/bin/bash
d="$HOME/tf-premier"
command -v terraform >/dev/null 2>&1 || { echo "terraform n'est pas installé (voir l'introduction)."; exit 1; }
[ -s "$d/main.tf" ] || { echo "Le fichier $d/main.tf est absent ou vide."; exit 1; }
grep -q 'resource "local_file" "bienvenue"' "$d/main.tf" || { echo "main.tf : la ressource local_file.bienvenue est absente."; exit 1; }
[ -d "$d/.terraform" ] || { echo "Le dossier .terraform est absent : lancez « terraform init »."; exit 1; }
[ -f "$d/terraform.tfstate" ] || { echo "Le fichier d'état terraform.tfstate est absent : lancez « terraform apply -auto-approve »."; exit 1; }
cd "$d" || exit 1
etat=$(terraform state list 2>/dev/null)
echo "$etat" | grep -qx 'local_file.bienvenue' || { echo "La ressource local_file.bienvenue n'est pas dans le state (terraform state list)."; exit 1; }
[ -f "$d/sortie/bienvenue.txt" ] || { echo "Le fichier sortie/bienvenue.txt n'existe pas."; exit 1; }
grep -q '^Bonjour .* !$' "$d/sortie/bienvenue.txt" || { echo "Le contenu de bienvenue.txt n'est pas celui attendu (« Bonjour … ! »)."; exit 1; }
terraform plan -detailed-exitcode -input=false >/dev/null 2>&1
code=$?
if [ "$code" -ne 0 ]; then
  echo "Le plan prévoit encore des changements (code $code) : l'infrastructure n'est pas conforme au code. Relancez « terraform apply -auto-approve »."
  exit 1
fi
echo "OK : projet initialisé, ressource créée, state cohérent et plan sans changement."
exit 0
