#!/bin/bash
# Étape 2 : sshd_config.work modifié, .bak intact, fichier sans commentaires
d=/tmp/luc
[ -f "$d/sshd_config.work" ] || { echo "sshd_config.work est absent."; exit 1; }
grep -qx 'PermitRootLogin no' "$d/sshd_config.work" || { echo "sshd_config.work doit contenir « PermitRootLogin no »."; exit 1; }
grep -qx 'PasswordAuthentication no' "$d/sshd_config.work" || { echo "sshd_config.work doit contenir « PasswordAuthentication no »."; exit 1; }
[ -f "$d/sshd_config.work.bak" ] || { echo "La sauvegarde sshd_config.work.bak est absente (utilisez sed -i.bak)."; exit 1; }
grep -qx 'PermitRootLogin yes' "$d/sshd_config.work.bak" || { echo "sshd_config.work.bak doit rester l'original (PermitRootLogin yes)."; exit 1; }
[ -s "$d/sans-commentaires.txt" ] || { echo "sans-commentaires.txt est absent ou vide."; exit 1; }
if grep -q '^#' "$d/sans-commentaires.txt" || grep -q '^$' "$d/sans-commentaires.txt"; then
  echo "sans-commentaires.txt ne doit contenir ni commentaire ni ligne vide."
  exit 1
fi
grep -qx 'Port 22' "$d/sans-commentaires.txt" || { echo "sans-commentaires.txt doit conserver la ligne « Port 22 »."; exit 1; }
echo "OK : sed appliqué avec sauvegarde."
exit 0
