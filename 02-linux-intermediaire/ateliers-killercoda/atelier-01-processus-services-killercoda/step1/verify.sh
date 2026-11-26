#!/bin/bash
# Étape 1 : /tmp/sleep.pid existe et le processus correspondant n'existe plus
f=/tmp/sleep.pid
[ -f "$f" ] || { echo "Le fichier $f n'existe pas (sleep 600 & puis echo \$! > $f)."; exit 1; }
pid=$(cat "$f")
case "$pid" in ''|*[!0-9]*) echo "Le fichier $f ne contient pas un PID valide."; exit 1 ;; esac
if kill -0 "$pid" 2>/dev/null; then
  echo "Le processus $pid tourne encore : arrêtez-le avec kill $pid."
  exit 1
fi
echo "OK : le processus $pid a été arrêté."
exit 0
