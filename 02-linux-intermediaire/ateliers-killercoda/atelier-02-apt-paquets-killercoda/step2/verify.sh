#!/bin/bash
# Étape 2 : nginx purgé après être passé par l'état « rc »
if [ ! -f /tmp/etat-nginx.txt ] || ! head -n 1 /tmp/etat-nginx.txt | grep -q '^rc'; then
  echo "/tmp/etat-nginx.txt doit contenir la ligne de dpkg -l commençant par « rc » (état après apt-get remove, avant purge)."
  exit 1
fi
if dpkg -s nginx 2>/dev/null | grep -q '^Status: install ok installed'; then
  echo "nginx est toujours installé."
  exit 1
fi
if [ -e /etc/nginx ]; then
  echo "/etc/nginx existe encore : utilisez apt-get purge nginx."
  exit 1
fi
if ! grep -q 'Purge:.*nginx' /var/log/apt/history.log 2>/dev/null; then
  echo "L'historique APT ne montre pas de purge de nginx (apt-get purge nginx)."
  exit 1
fi
echo "OK : remove (rc) puis purge réalisés."
exit 0
