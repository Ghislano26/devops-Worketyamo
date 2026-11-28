# Étape 1 : créer le rôle `webserver`

On part du même besoin qu'à l'atelier précédent (nginx + une page + une configuration), mais organisé **en rôle**. Créez l'arborescence puis les fichiers :

```bash
cd ~/ansible-roles
mkdir -p roles/webserver/{tasks,handlers,templates,defaults}
cat > roles/webserver/defaults/main.yml <<'EOF'
---
webserver_port: 8080
webserver_racine: /var/www/webserver
webserver_titre: "Mon site"
EOF
cat > roles/webserver/tasks/main.yml <<'EOF'
---
- name: Installer nginx
  ansible.builtin.apt:
    name: nginx
    state: present
    update_cache: true
    cache_valid_time: 3600

- name: Créer le dossier du site
  ansible.builtin.file:
    path: "{{ webserver_racine }}"
    state: directory
    mode: "0755"

- name: Générer la page d'accueil
  ansible.builtin.template:
    src: index.html.j2
    dest: "{{ webserver_racine }}/index.html"
    mode: "0644"

- name: Générer la configuration du site
  ansible.builtin.template:
    src: webserver.conf.j2
    dest: /etc/nginx/conf.d/webserver.conf
    mode: "0644"
  notify: Recharger nginx

- name: Démarrer et activer nginx
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true
EOF
cat > roles/webserver/handlers/main.yml <<'EOF'
---
- name: Recharger nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded
EOF
cat > roles/webserver/templates/webserver.conf.j2 <<'EOF'
# {{ ansible_managed }}
server {
    listen {{ webserver_port }};
    root {{ webserver_racine }};
    index index.html;
}
EOF
cat > roles/webserver/templates/index.html.j2 <<'EOF'
<h1>{{ webserver_titre }}</h1>
<p>Serveur : {{ inventory_hostname }} — port {{ webserver_port }}</p>
EOF
find roles -type f | sort
```{{exec}}

Remarquez que les **paramètres** (port, dossier, titre) sont des **variables préfixées** par le nom du rôle (`webserver_port`…) et définies dans `defaults/` : n'importe quel playbook peut les **surcharger**.

Le **playbook** devient minuscule : il se contente d'**appeler** le rôle.

```bash
cat > site.yml <<'EOF'
---
- name: Serveur web via le rôle webserver
  hosts: localhost
  connection: local
  roles:
    - role: webserver
      vars:
        webserver_titre: "Atelier rôles"
EOF
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml
curl -s http://localhost:8080
```{{exec}}

## Questions

- Pourquoi mettre les variables dans **`defaults/`** plutôt que dans `vars/` ? *(Priorité la plus basse : faciles à surcharger.)*
- Que fait `{{ ansible_managed }}` en tête du modèle ? *(Marque le fichier comme géré par Ansible.)*

Cliquez sur **Vérifier**.
