#!/bin/bash
# Étape 1 : ~/scripts/sante.sh existe, exécutable, shebang, mode strict, s'exécute avec succès
f="$HOME/scripts/sante.sh"
[ -f "$f" ] || { echo "$f n'existe pas."; exit 1; }
[ -x "$f" ] || { echo "$f n'est pas exécutable (chmod +x)."; exit 1; }
head -n 1 "$f" | grep -qE '^#!(/usr/bin/env bash|/bin/bash)' || { echo "La première ligne doit être un shebang bash."; exit 1; }
grep -q 'set -euo pipefail' "$f" || { echo "Le script doit contenir « set -euo pipefail »."; exit 1; }
bash -n "$f" || { echo "Erreur de syntaxe."; exit 1; }
sortie=$("$f" 2>&1)
code=$?
[ "$code" -eq 0 ] || { echo "Le script doit se terminer avec le code 0 (code obtenu : $code)."; exit 1; }
echo "$sortie" | grep -q '^Serveur : ' || { echo "La sortie doit contenir une ligne « Serveur : … »."; exit 1; }
echo "$sortie" | grep -q '^Disque / : [0-9]*%' || { echo "La sortie doit contenir une ligne « Disque / : NN% »."; exit 1; }
echo "OK : script robuste."
exit 0
