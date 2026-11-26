#!/bin/bash
f="$HOME/postmortem/postmortem.md"
[ -s "$f" ] || { echo "Le fichier $f est absent ou vide."; exit 1; }
for s in "## Résumé" "## Impact" "## Chronologie" "## Causes" "## Actions"; do
  grep -qx "$s" "$f" || { echo "Section manquante : « $s » (titre de niveau 2, seul sur sa ligne)."; exit 1; }
done
nb_tl=$(grep -cE '^- [0-9]{2}:[0-9]{2} ' "$f")
if [ "$nb_tl" -lt 6 ]; then
  echo "La chronologie doit contenir au moins 6 lignes « - HH:MM  fait » (trouvé : $nb_tl)."
  exit 1
fi
nb_act=$(grep -cE '^- \[ \] .+\| *propri[ée]taire: *[^|]+\| *[ée]ch[ée]ance: *[0-9]{4}-[0-9]{2}-[0-9]{2}' "$f")
if [ "$nb_act" -lt 3 ]; then
  echo "Il faut au moins 3 actions au format « - [ ] action | propriétaire: … | échéance: AAAA-MM-JJ » (trouvé : $nb_act)."
  exit 1
fi
if grep -qiE '\b(Jean|Awa|Binta|Marc)\b' "$f"; then
  echo "Le postmortem contient un nom de personne (Jean, Awa, Binta, Marc) : utilisez des rôles (blameless)."
  exit 1
fi
if grep -qiE "a causé|est responsable|c'est la faute|par la faute" "$f"; then
  echo "Formulation accusatrice détectée (« a causé », « est responsable »…) : décrivez le système, pas la personne."
  exit 1
fi
echo "OK : postmortem structuré ($nb_tl lignes de chronologie, $nb_act actions, aucun nom propre)."
exit 0
