#!/bin/bash
# Étape 2 : heartbeat actif, activé au démarrage, écrit dans le journal, avec redémarrage automatique
if [ "$(systemctl is-active heartbeat 2>/dev/null)" != "active" ]; then
  echo "Le service heartbeat n'est pas actif (systemctl enable --now heartbeat)."
  exit 1
fi
if [ "$(systemctl is-enabled heartbeat 2>/dev/null)" != "enabled" ]; then
  echo "Le service heartbeat n'est pas activé au démarrage."
  exit 1
fi
if [ "$(systemctl show -p Restart --value heartbeat)" != "always" ]; then
  echo "L'unité doit contenir Restart=always."
  exit 1
fi
avant=$(wc -l < /tmp/heartbeat.log 2>/dev/null || echo 0)
sleep 6
apres=$(wc -l < /tmp/heartbeat.log 2>/dev/null || echo 0)
if [ "$apres" -le "$avant" ]; then
  echo "/tmp/heartbeat.log ne grossit pas : le service n'écrit plus."
  exit 1
fi
echo "OK : service actif, activé, avec redémarrage automatique."
exit 0
