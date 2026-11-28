# Bravo !

Vous avez transformé un playbook en **rôle réutilisable** :

| Élément | Rôle |
|---|---|
| `defaults/main.yml` | Variables **préfixées** et faciles à surcharger |
| `tasks/main.yml` | Les tâches du rôle |
| `templates/*.j2` | Fichiers générés (Jinja2) depuis les variables |
| `handlers/main.yml` | Rechargement **seulement si** la configuration a changé |
| `README.md` | Documentation des variables |
| `-e variable=valeur` | Surcharge de priorité maximale |

## Défi bonus : tester le rôle et le rendre multi-système

1. Ajoutez une condition `when: ansible_facts['os_family'] == "Debian"` à l'installation, puis une variante `ansible.builtin.dnf` pour Rocky (`RedHat`).
2. Installez `ansible-lint` et lancez `ansible-lint roles/webserver` ; corrigez les remarques.
3. Écrivez un second playbook qui appelle le rôle **deux fois** avec des ports différents (pensez au nom du fichier de configuration : à rendre variable).
4. Côté Terraform : transformez le projet de l'atelier 1 en **module** (`modules/bienvenue/` avec `variable "nom"`) appelé deux fois depuis la racine ([cours Terraform avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/03-terraform-avance.md)).

## Pour aller plus loin

- [Ansible avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/05-ansible-avance.md) · [Terraform avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/03-terraform-avance.md) · [Bonnes pratiques IaC](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/07-bonnes-pratiques-iac.md).
- Molecule pour **tester** un rôle (machine éphémère, second passage = `changed=0`).
- Retour au [module 13](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/README.md).
