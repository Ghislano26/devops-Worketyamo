#!/bin/bash
d="$HOME/tf-premier"
command -v terraform >/dev/null 2>&1 || { echo "terraform n'est pas installé."; exit 1; }
[ -s "$d/main.tf" ] || { echo "Le projet $d est absent : refaites l'étape 1."; exit 1; }
cd "$d" || exit 1
[ -f terraform.tfvars ] || { echo "Le fichier terraform.tfvars est absent : créez-le avec « nom = \"Worketyamo\" » (étape 2, partie A)."; exit 1; }
grep -q 'Worketyamo' terraform.tfvars || { echo "terraform.tfvars doit contenir nom = \"Worketyamo\"."; exit 1; }
[ -s plan-derive.txt ] || { echo "Le fichier plan-derive.txt est absent : lancez « terraform plan -no-color | tee plan-derive.txt » après avoir modifié le fichier à la main (partie B)."; exit 1; }
grep -q 'local_file.bienvenue' plan-derive.txt || { echo "plan-derive.txt ne mentionne pas local_file.bienvenue : le plan a-t-il été lancé dans ~/tf-premier ?"; exit 1; }
if [ -e sortie/bienvenue.txt ]; then
  echo "Le fichier sortie/bienvenue.txt existe encore : lancez « terraform destroy -auto-approve » (partie C)."
  exit 1
fi
reste=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
[ "$reste" = "0" ] || { echo "Le state contient encore $reste ressource(s) : lancez « terraform destroy -auto-approve »."; exit 1; }
if [ -f terraform.tfstate.backup ] && ! grep -q 'Worketyamo' terraform.tfstate.backup; then
  echo "L'état précédent ne contient pas « Worketyamo » : refaites la partie A (terraform.tfvars) avant la destruction."
  exit 1
fi
echo "OK : variable modifiée, dérive détectée (plan-derive.txt), ressource détruite et state vide."
exit 0
