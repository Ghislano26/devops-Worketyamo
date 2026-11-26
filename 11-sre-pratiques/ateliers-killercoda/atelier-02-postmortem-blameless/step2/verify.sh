#!/bin/bash
d="$HOME/postmortem"
f="$d/facteurs-contributifs.md"
[ -s "$f" ] || { echo "Le fichier $f est absent ou vide."; exit 1; }
grep -qx "## Facteurs contributifs" "$f" || { echo "Le titre « ## Facteurs contributifs » est manquant."; exit 1; }
nb=$(grep -cE '^- \*\*[^*]+\*\* *: *.{15,}' "$f")
if [ "$nb" -lt 4 ]; then
  echo "Il faut au moins 4 facteurs au format « - **Catégorie** : description » (15 caractères minimum) — trouvé : $nb."
  exit 1
fi
if grep -qiE '\b(Jean|Awa|Binta|Marc)\b' "$f"; then
  echo "facteurs-contributifs.md contient un nom de personne : décrivez le système, pas les individus."
  exit 1
fi
r="$d/reformulation.txt"
[ -s "$r" ] || { echo "Le fichier $r est absent ou vide."; exit 1; }
if [ "$(wc -c < "$r")" -lt 40 ]; then
  echo "La reformulation est trop courte (40 caractères minimum)."
  exit 1
fi
if grep -qiE '\b(Jean|Awa|Binta|Marc)\b' "$r"; then
  echo "La reformulation contient un nom de personne (Jean, Awa, Binta, Marc)."
  exit 1
fi
if grep -qiE "a causé|est responsable|c'est la faute|par la faute|erreur de" "$r"; then
  echo "La reformulation contient encore une formulation accusatrice (« a causé », « est responsable », « erreur de »…)."
  exit 1
fi
if ! grep -qiE "système|pipeline|processus|garde-fou|automatis|documentation|runbook|alerte|test" "$r"; then
  echo "La reformulation doit décrire le système (pipeline, processus, garde-fou, documentation, alerte, test…)."
  exit 1
fi
echo "OK : $nb facteurs contributifs et une reformulation blameless."
exit 0
