#!/bin/bash
# Étape 1 : preuves d'un namespace PID (PID 1, peu de processus) et UTS (hostname isolé)
[ "$(cat /tmp/ns-pid.txt 2>/dev/null)" = "1" ] || { echo "/tmp/ns-pid.txt doit contenir 1 (le shell est PID 1 dans son namespace)."; exit 1; }
[ -f /tmp/ns-ps.txt ] || { echo "/tmp/ns-ps.txt est absent."; exit 1; }
n=$(wc -l < /tmp/ns-ps.txt)
if [ "$n" -gt 6 ]; then
  echo "ps voyait $n lignes : il devait ne voir que les processus du namespace (option --mount-proc ?)."
  exit 1
fi
[ "$(cat /tmp/ns-host.txt 2>/dev/null)" = "prison" ] || { echo "/tmp/ns-host.txt doit contenir « prison »."; exit 1; }
if [ "$(hostname)" = "prison" ]; then
  echo "Le nom d'hôte de l'hôte a changé : l'option --uts n'a pas isolé le changement."
  exit 1
fi
echo "OK : namespaces PID, montage et UTS isolés."
exit 0
