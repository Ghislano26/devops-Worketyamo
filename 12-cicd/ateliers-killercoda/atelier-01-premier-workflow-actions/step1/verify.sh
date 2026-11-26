#!/bin/bash
d="$HOME/ci-actions"
command -v act >/dev/null 2>&1 || { echo "act n'est pas installé (voir l'introduction)."; exit 1; }
f="$d/.github/workflows/hello.yml"
[ -s "$f" ] || { echo "Le fichier $f est absent ou vide."; exit 1; }
grep -qE '^ +hello:' "$f" || { echo "hello.yml : le job « hello » est absent."; exit 1; }
grep -q 'runs-on:' "$f" || { echo "hello.yml : « runs-on » est absent."; exit 1; }
nb=$(grep -cE '^ +- name:' "$f")
if [ "$nb" -lt 2 ]; then echo "hello.yml : il faut au moins 2 étapes nommées (trouvé : $nb)."; exit 1; fi
log="$d/act-hello.log"
[ -s "$log" ] || { echo "Le journal $log est absent : lancez « act -j hello 2>&1 | tee ~/ci-actions/act-hello.log »."; exit 1; }
grep -q 'Job succeeded' "$log" || { echo "Le journal ne contient pas « Job succeeded » : le job hello a-t-il réussi ?"; exit 1; }
grep -q 'Bonjour depuis le workflow' "$log" || { echo "Le journal ne contient pas la sortie attendue de l'étape « Dire bonjour »."; exit 1; }
echo "OK : workflow hello.yml valide et exécuté avec succès par act."
exit 0
