#!/bin/bash
# Étape 1 : pod « demo » Running dans « atelier », variables et fichiers présents avec les bonnes valeurs
phase=$(kubectl get pod demo -n atelier -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" != "Running" ]; then
  echo "Le pod « demo » du namespace « atelier » n'est pas Running (phase : ${phase:-inexistant})."
  exit 1
fi
mode=$(kubectl exec -n atelier demo -- printenv APP_MODE 2>/dev/null)
if [ "$mode" != "prod" ]; then
  echo "La variable APP_MODE devrait valoir « prod » (valeur lue : « ${mode} »)."
  echo "Rappel : une variable d'environnement n'est lue qu'au démarrage du conteneur."
  exit 1
fi
mdp=$(kubectl exec -n atelier demo -- printenv DB_PASSWORD 2>/dev/null)
if [ "$mdp" != "MotDePasse123" ]; then
  echo "La variable DB_PASSWORD n'a pas la valeur attendue (issue du Secret app-secret)."
  exit 1
fi
if ! kubectl exec -n atelier demo -- test -f /etc/config/app.properties 2>/dev/null; then
  echo "Le fichier /etc/config/app.properties (ConfigMap monté) est absent."
  exit 1
fi
if ! kubectl exec -n atelier demo -- test -f /etc/secret/DB_PASSWORD 2>/dev/null; then
  echo "Le fichier /etc/secret/DB_PASSWORD (Secret monté) est absent."
  exit 1
fi
echo "OK : ConfigMap et Secret consommés en variables et en fichiers."
exit 0
