# Étape 1 : écrire et lancer le playbook

Créez le projet : un **inventaire** (la machine locale), une petite **configuration** et le **playbook**.

```bash
cd ~/ansible-nginx
cat > inventaire.ini <<'EOF'
localhost ansible_connection=local
EOF
cat > ansible.cfg <<'EOF'
[defaults]
inventory = inventaire.ini
host_key_checking = False
retry_files_enabled = False
interpreter_python = auto_silent
nocows = 1
EOF
cat > site.yml <<'EOF'
---
- name: Serveur web nginx
  hosts: localhost
  connection: local
  vars:
    port_http: 8080
    racine: /var/www/atelier

  tasks:
    - name: Installer nginx
      ansible.builtin.apt:
        name: nginx
        state: present
        update_cache: true
        cache_valid_time: 3600

    - name: Créer le dossier du site
      ansible.builtin.file:
        path: "{{ racine }}"
        state: directory
        mode: "0755"

    - name: Déposer la page d'accueil
      ansible.builtin.copy:
        dest: "{{ racine }}/index.html"
        content: "<h1>Atelier Ansible</h1>\n"
        mode: "0644"

    - name: Déposer la configuration du site
      ansible.builtin.copy:
        dest: /etc/nginx/conf.d/atelier.conf
        content: |
          server {
              listen {{ port_http }};
              root {{ racine }};
              index index.html;
          }
        mode: "0644"
      notify: Recharger nginx

    - name: Démarrer et activer nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true

  handlers:
    - name: Recharger nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
EOF
ansible all -m ping
ansible-playbook site.yml --syntax-check
```{{exec}}

Lancez le playbook **une première fois** :

```bash
ansible-playbook site.yml
```{{exec}}

Lisez le déroulé : chaque tâche affiche `ok` ou **`changed`**, et le **handler** « Recharger nginx » ne s'exécute que parce que la configuration vient d'être modifiée. Le `PLAY RECAP` final compte les résultats.

Vérifiez que le service répond sur le port **8080** défini dans la configuration :

```bash
curl -s http://localhost:8080
systemctl is-active nginx
cat /etc/nginx/conf.d/atelier.conf
```{{exec}}

## Questions

- Pourquoi les tâches utilisent-elles des **modules** (`apt`, `copy`, `service`) plutôt que des commandes `apt install` et `echo >` ? *(Les modules décrivent un **état**, sont idempotents et rapportent `ok` / `changed`.)*
- À quoi sert `notify: Recharger nginx` ? *(Recharger nginx **uniquement si** le fichier a réellement changé.)*

Cliquez sur **Vérifier**.
