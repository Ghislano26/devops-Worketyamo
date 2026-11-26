#!/bin/bash
# Étape 2 : état final conforme
b=/tmp/devops
[ -f "$b/config/app.conf" ]      || { echo "config/app.conf est manquant."; exit 1; }
[ -f "$b/config/app.conf.bak" ]  || { echo "config/app.conf.bak est manquant (cp)."; exit 1; }
cmp -s "$b/config/app.conf" "$b/config/app.conf.bak" || { echo "app.conf et app.conf.bak diffèrent."; exit 1; }
[ -f "$b/scripts/deploy-v1.sh" ] || { echo "scripts/deploy-v1.sh est manquant (mv pour renommer)."; exit 1; }
[ ! -e "$b/scripts/deploy.sh" ]  || { echo "scripts/deploy.sh ne devrait plus exister (renommé)."; exit 1; }
[ -f "$b/archive/app.log" ]      || { echo "archive/app.log est manquant (mv)."; exit 1; }
[ ! -e "$b/logs" ]               || { echo "Le dossier logs/ devrait avoir été supprimé (rmdir)."; exit 1; }
grep -q 'ERROR' "$b/archive/app.log" || { echo "archive/app.log a perdu son contenu."; exit 1; }
echo "OK : état final conforme."
exit 0
