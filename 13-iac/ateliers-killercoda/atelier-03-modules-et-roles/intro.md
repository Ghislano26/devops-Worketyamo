# Modules et rôles

**Durée : ~30 minutes.** Compétence travaillée : **refactoriser** un playbook en **rôle Ansible** réutilisable, avec **variables par défaut**, **templates Jinja2** et **handlers**.

Rappel du [cours Ansible avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/05-ansible-avance.md) :

```text
roles/webserver/
├── defaults/main.yml     variables (faciles à surcharger)
├── tasks/main.yml        les tâches
├── handlers/main.yml     rechargement du service
└── templates/*.j2        fichiers générés depuis des variables
```

Un **rôle** est l'équivalent Ansible d'un **module Terraform** ([cours Terraform avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/03-terraform-avance.md)) : une brique réutilisable, avec des **entrées** (variables) et un contenu encapsulé.

## Mise en place

Cette VM est neuve : on réinstalle Ansible et on prépare le projet.

```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ansible >/dev/null
ansible --version | head -n 1
mkdir -p ~/ansible-roles && cd ~/ansible-roles
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
ansible all -m ping
```{{exec}}
