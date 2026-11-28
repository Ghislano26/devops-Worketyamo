#!/bin/bash
export ANSIBLE_NOCOLOR=1
d="$HOME/ansible-roles"
command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible n'est pas installé."; exit 1; }
cd "$d" 2>/dev/null || { echo "Le dossier $d n'existe pas : refaites l'étape 1."; exit 1; }
[ -s site.yml ] || { echo "site.yml est absent : refaites l'étape 1."; exit 1; }
if ! sortie=$(ansible-playbook site.yml -e webserver_port=9090 2>&1); then
  echo "Le playbook échoue :"; echo "$sortie" | tail -n 12; exit 1
fi
recap=$(echo "$sortie" | grep -E '^localhost +:')
if ! echo "$recap" | grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0'; then
  echo "Le rôle n'est pas idempotent avec webserver_port=9090 : « $recap » (attendu : changed=0)."
  exit 1
fi
curl -fs --max-time 5 http://localhost:9090 | grep -q 'Atelier rôles' || { echo "Le port 9090 ne sert pas la page attendue."; exit 1; }
grep -q 'listen 9090' /etc/nginx/conf.d/webserver.conf || { echo "La configuration de nginx n'écoute pas sur le port 9090."; exit 1; }
[ -s roles/webserver/README.md ] || { echo "Le fichier roles/webserver/README.md est absent (partie B)."; exit 1; }
for v in webserver_port webserver_racine webserver_titre; do
  grep -q "$v" roles/webserver/README.md || { echo "README.md du rôle : la variable $v n'est pas documentée."; exit 1; }
done
[ -s run-role.log ] || { echo "Le fichier run-role.log est absent : lancez « ansible-playbook site.yml -e webserver_port=9090 | tee run-role.log » (partie A)."; exit 1; }
grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' run-role.log || { echo "run-role.log ne montre pas changed=0."; exit 1; }
echo "OK : variable surchargée, second passage idempotent (changed=0), rôle documenté."
exit 0
