#!/bin/bash
# Étape 2 : ~/scripts/seuil.sh gère les 4 cas avec les bons codes de retour
f="$HOME/scripts/seuil.sh"
[ -x "$f" ] || { echo "$f doit exister et être exécutable."; exit 1; }
bash -n "$f" || { echo "Erreur de syntaxe."; exit 1; }
grep -q 'set -euo pipefail' "$f" || { echo "Le script doit contenir « set -euo pipefail »."; exit 1; }
verifie() {  # verifie <code attendu> <sortie attendue ou ''> args...
  local attendu="$1" sortie="$2"; shift 2
  local s c
  s=$("$f" "$@" 2>/dev/null); c=$?
  if [ "$c" -ne "$attendu" ]; then echo "seuil.sh $* : code attendu $attendu, obtenu $c."; exit 1; fi
  if [ -n "$sortie" ] && [ "$s" != "$sortie" ]; then echo "seuil.sh $* : sortie attendue « $sortie », obtenue « $s »."; exit 1; fi
}
verifie 0 OK 10
verifie 0 OK 79
verifie 1 ALERTE 80
verifie 1 ALERTE 95
verifie 2 ""
verifie 2 "" abc
if "$f" abc 2>&1 >/dev/null | grep -qi 'usage'; then :; else echo "Le message d'usage doit être écrit sur la sortie d'erreur (>&2)."; exit 1; fi
echo "OK : arguments validés et codes de retour corrects."
exit 0
