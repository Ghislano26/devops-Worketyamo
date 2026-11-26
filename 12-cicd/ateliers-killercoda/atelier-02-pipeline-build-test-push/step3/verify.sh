#!/bin/bash
catalogue=$(curl -fs http://localhost:5000/v2/_catalog) || { echo "Le registry ne répond pas sur http://localhost:5000."; exit 1; }
echo "$catalogue" | grep -q '"monapp"' || { echo "Le dépôt « monapp » est absent du registry : lancez « make push » dans ~/cicd-app."; exit 1; }
tags=$(curl -fs http://localhost:5000/v2/monapp/tags/list) || { echo "Impossible de lire les tags de monapp."; exit 1; }
echo "$tags" | grep -q '"1.0.0"' || { echo "Le tag 1.0.0 est absent du registry."; exit 1; }
echo "$tags" | grep -q '"latest"' || { echo "Le tag latest est absent du registry."; exit 1; }
echo "OK : monapp:1.0.0 et monapp:latest sont présents dans le registry."
exit 0
