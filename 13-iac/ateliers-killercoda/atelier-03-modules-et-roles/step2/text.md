# Étape 2 : surcharger, rejouer, documenter

## A. Surcharger une variable en ligne de commande

Le même rôle peut servir **plusieurs usages** : ici, on change le port **sans modifier le rôle** (`-e` est la source de variables **la plus prioritaire**).

```bash
cd ~/ansible-roles
ansible-playbook site.yml -e webserver_port=9090
curl -s http://localhost:9090
curl -s --max-time 3 http://localhost:8080 || echo "8080 ne répond plus : le port a changé"
```{{exec}}

Le **template** a produit une nouvelle configuration (`changed`), ce qui a déclenché le **handler** : nginx a été **rechargé**. Relancez la **même** commande :

```bash
ansible-playbook site.yml -e webserver_port=9090 | tee run-role.log
grep -E 'changed=|failed=' run-role.log
```{{exec}}

Le second passage affiche **`changed=0`** : le rôle est **idempotent**.

## B. Documenter le rôle

Un rôle sans documentation n'est pas réutilisable. Créez son `README.md` :

```bash
cat > roles/webserver/README.md <<'EOF'
# Rôle webserver

Installe nginx et publie une page statique.

## Variables

| Variable | Défaut | Rôle |
|---|---|---|
| `webserver_port` | `8080` | Port d'écoute de nginx |
| `webserver_racine` | `/var/www/webserver` | Dossier du site |
| `webserver_titre` | `Mon site` | Titre de la page d'accueil |

## Exemple

    - hosts: web
      roles:
        - role: webserver
          vars:
            webserver_port: 9090
EOF
ansible-playbook site.yml -e webserver_port=9090 --list-tasks
```{{exec}}

## Questions

- Pourquoi le port a-t-il changé **sans** toucher au rôle ? *(Une variable de priorité supérieure à `defaults/` l'a surchargée.)*
- Que se passerait-il si deux rôles utilisaient chacun une variable nommée simplement `port` ? *(Collision : toutes les variables Ansible sont globales ; d'où le préfixe `webserver_`.)*

Cliquez sur **Vérifier**.
