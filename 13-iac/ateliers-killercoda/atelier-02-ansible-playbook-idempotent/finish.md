# Bravo !

Vous avez écrit un playbook et **prouvé qu'il est idempotent** :

| Notion | Où vous l'avez vue |
|---|---|
| Inventaire local, `ansible.cfg` | `localhost ansible_connection=local` |
| Modules idempotents | `apt`, `file`, `copy`, `service` |
| Handler | Rechargement de nginx **seulement** si la configuration change |
| `changed=0` | Second passage = rien à faire |
| `--check --diff` | Simuler avant d'appliquer ; voir la dérive |

## Défi bonus : transformer une tâche non idempotente

1. Ajoutez une tâche `ansible.builtin.command: date >> /tmp/passage.log` : au second passage, elle sera **`changed`** (à chaque fois). Constatez que `changed=0` n'est plus atteint.
2. Corrigez-la : soit avec un module adapté, soit avec `creates: /tmp/passage.log` ou `changed_when: false` selon l'intention.
3. Passez `ansible-playbook site.yml --list-tasks` puis `--tags` après avoir étiqueté les tâches (`tags: [nginx]`).
4. Installez `ansible-lint` (`apt-get install -y ansible-lint`) et corrigez ses remarques.

## Pour aller plus loin

- [Ansible : les fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/04-ansible-fondamentaux.md) · [Ansible avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/05-ansible-avance.md) · [Terraform ou Ansible ?](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/06-terraform-vs-ansible.md).
- Suite : [atelier 3 — modules et rôles](https://github.com/Ghislano26/devops-Worketyamo/tree/main/13-iac/ateliers-killercoda/atelier-03-modules-et-roles) : transformer ce playbook en **rôle** réutilisable.
