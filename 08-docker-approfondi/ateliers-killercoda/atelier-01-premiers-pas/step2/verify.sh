#!/bin/bash
# Étape 2 : le volume « donnees » existe et contient note.txt, relu depuis un NOUVEAU conteneur
if ! docker volume inspect donnees >/dev/null 2>&1; then
  echo "Le volume « donnees » n'existe pas (docker volume create donnees)."
  exit 1
fi
contenu=$(docker run --rm -v donnees:/data ubuntu cat /data/note.txt 2>/dev/null)
if [ "$contenu" != "je persiste" ]; then
  echo "Le fichier /data/note.txt du volume ne contient pas « je persiste »."
  exit 1
fi
echo "OK : les données du volume survivent à la recréation des conteneurs."
exit 0
