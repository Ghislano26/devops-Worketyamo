#!/bin/bash
export ANSIBLE_NOCOLOR=1
d="$HOME/ansible-nginx"
command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible n'est pas installé (voir l'introduction)."; exit 1; }
for f in inventaire.ini ansible.cfg site.yml; do
  [ -s "$d/$f" ] || { echo "Le fichier $d/$f est absent ou vide."; exit 1; }
done
cd "$d" || exit 1
if ! sortie=$(ansible-playbook site.yml --syntax-check 2>&1); then
  echo "Erreur de syntaxe dans site.yml :"
  echo "$sortie" | tail -n 8
  exit 1
fi
for mot in 'ansible.builtin.apt' 'ansible.builtin.service' 'notify:' 'handlers:'; do
  grep -q "$mot" site.yml || { echo "site.yml : « $mot » est absent (voir le modèle de l'énoncé)."; exit 1; }
done
dpkg -s nginx >/dev/null 2>&1 || { echo "nginx n'est pas installé : lancez « ansible-playbook site.yml »."; exit 1; }
systemctl is-active --quiet nginx || { echo "nginx n'est pas démarré."; exit 1; }
[ -f /etc/nginx/conf.d/atelier.conf ] || { echo "La configuration /etc/nginx/conf.d/atelier.conf est absente."; exit 1; }
page=$(curl -fs --max-time 5 http://localhost:8080) || { echo "Aucune réponse sur http://localhost:8080 : nginx est-il configuré sur le port 8080 ?"; exit 1; }
echo "$page" | grep -q 'Atelier Ansible' || { echo "La page servie sur le port 8080 ne contient pas « Atelier Ansible »."; exit 1; }
echo "OK : playbook valide, nginx installé, démarré et servant la page sur le port 8080."
exit 0
