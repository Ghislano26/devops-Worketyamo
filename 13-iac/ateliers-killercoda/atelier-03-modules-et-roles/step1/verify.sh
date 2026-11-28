#!/bin/bash
export ANSIBLE_NOCOLOR=1
d="$HOME/ansible-roles"
command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible n'est pas installé (voir l'introduction)."; exit 1; }
cd "$d" 2>/dev/null || { echo "Le dossier $d n'existe pas (voir l'introduction)."; exit 1; }
for f in roles/webserver/tasks/main.yml roles/webserver/handlers/main.yml roles/webserver/defaults/main.yml roles/webserver/templates/webserver.conf.j2 roles/webserver/templates/index.html.j2 site.yml; do
  [ -s "$f" ] || { echo "Le fichier $d/$f est absent ou vide."; exit 1; }
done
grep -q 'webserver_port' roles/webserver/defaults/main.yml || { echo "defaults/main.yml doit définir webserver_port."; exit 1; }
grep -q 'webserver_port' roles/webserver/templates/webserver.conf.j2 || { echo "Le modèle webserver.conf.j2 doit utiliser la variable webserver_port."; exit 1; }
grep -q 'notify' roles/webserver/tasks/main.yml || { echo "tasks/main.yml : une tâche doit notifier le handler (notify: Recharger nginx)."; exit 1; }
grep -q 'Recharger nginx' roles/webserver/handlers/main.yml || { echo "handlers/main.yml doit définir le handler « Recharger nginx »."; exit 1; }
grep -q 'webserver' site.yml || { echo "site.yml doit appeler le rôle webserver."; exit 1; }
if ! sortie=$(ansible-playbook site.yml --syntax-check 2>&1); then
  echo "Erreur de syntaxe :"; echo "$sortie" | tail -n 8; exit 1
fi
systemctl is-active --quiet nginx || { echo "nginx n'est pas démarré : lancez « ansible-playbook site.yml »."; exit 1; }
page=$(curl -fs --max-time 5 http://localhost:8080) || { echo "Aucune réponse sur http://localhost:8080 : lancez « ansible-playbook site.yml »."; exit 1; }
echo "$page" | grep -q 'Atelier rôles' || { echo "La page ne contient pas le titre « Atelier rôles » (variable webserver_titre surchargée dans site.yml)."; exit 1; }
echo "OK : rôle webserver complet, appliqué avec succès, page servie avec le titre surchargé."
exit 0
