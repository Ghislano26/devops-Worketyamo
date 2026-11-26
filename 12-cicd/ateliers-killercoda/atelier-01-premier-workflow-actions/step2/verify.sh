#!/bin/bash
d="$HOME/ci-actions"
f="$d/.github/workflows/ci.yml"
[ -s "$f" ] || { echo "Le fichier $f est absent ou vide."; exit 1; }
grep -qE '^ +matrix:' "$f" || { echo "ci.yml : la section « matrix » est absente."; exit 1; }
grep -qE '^ +needs: *test' "$f" || { echo "ci.yml : le job build doit contenir « needs: test »."; exit 1; }
grep -qE '^ +build:' "$f" || { echo "ci.yml : le job « build » est absent."; exit 1; }
log="$d/act-ci.log"
[ -s "$log" ] || { echo "Le journal $log est absent : lancez « act -W .github/workflows/ci.yml 2>&1 | tee ~/ci-actions/act-ci.log »."; exit 1; }
nb=$(grep -c 'Job succeeded' "$log")
if [ "$nb" -lt 4 ]; then
  echo "Le journal doit contenir au moins 4 « Job succeeded » (3 tests de la matrice + build) — trouvé : $nb."
  exit 1
fi
for v in 1 2 3; do
  grep -q "Test avec la version $v" "$log" || { echo "Le journal ne montre pas l'exécution de la version $v de la matrice."; exit 1; }
done
echo "OK : matrice (3 versions) et dépendance « needs » exécutées avec succès ($nb jobs réussis)."
exit 0
