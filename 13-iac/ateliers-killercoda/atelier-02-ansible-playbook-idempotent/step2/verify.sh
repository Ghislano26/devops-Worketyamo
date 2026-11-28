#!/bin/bash
export ANSIBLE_NOCOLOR=1
d="$HOME/ansible-nginx"
command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible n'est pas installé."; exit 1; }
[ -s "$d/site.yml" ] || { echo "Le projet $d est absent : refaites l'étape 1."; exit 1; }
cd "$d" || exit 1
if ! sortie=$(ansible-playbook site.yml 2>&1); then
  echo "Le playbook échoue :"
  echo "$sortie" | tail -n 12
  exit 1
fi
recap=$(echo "$sortie" | grep -E '^localhost +:')
if ! echo "$recap" | grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0'; then
  echo "Le playbook n'est pas idempotent ou a échoué : « $recap » (attendu : changed=0, failed=0)."
  echo "Relancez-le encore une fois, ou corrigez la tâche qui est « changed » à chaque passage."
  exit 1
fi
[ -s run2.log ] || { echo "Le fichier run2.log est absent : lancez « ansible-playbook site.yml | tee run2.log » (partie A)."; exit 1; }
grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' run2.log || { echo "run2.log ne montre pas changed=0 : relancez la partie A."; exit 1; }
[ -s run-final.log ] || { echo "Le fichier run-final.log est absent : lancez la partie B jusqu'au bout."; exit 1; }
grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' run-final.log || { echo "run-final.log ne montre pas changed=0."; exit 1; }
grep -q 'listen 8080' /etc/nginx/conf.d/atelier.conf || { echo "La configuration n'est pas revenue à « listen 8080 » : relancez le playbook."; exit 1; }
curl -fs --max-time 5 http://localhost:8080 | grep -q 'Atelier Ansible' || { echo "Le port 8080 ne sert pas la page attendue."; exit 1; }
echo "OK : second passage à changed=0 (idempotence prouvée), dérive corrigée, service opérationnel."
exit 0
