# Playbook Ansible idempotent

**Durée : ~25 minutes.** Compétence travaillée : écrire un **playbook**, l'exécuter, et prouver son **idempotence** (`changed=0` au second passage).

Rappel du [cours Ansible : les fondamentaux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/13-iac/cours/04-ansible-fondamentaux.md) :

```text
inventaire + playbook (tâches, handlers) → ansible-playbook → PLAY RECAP : ok / changed / failed
2ᵉ passage sans rien toucher → changed=0
```

Ici, le **nœud de contrôle** et le **nœud géré** sont la **même machine** (`localhost`, connexion locale) : pas de SSH à configurer.

## Mise en place : installer Ansible

```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ansible >/dev/null
ansible --version | head -n 2
mkdir -p ~/ansible-nginx
```{{exec}}

> L'installation prend environ une minute. Ansible est installé ici depuis les dépôts d'Ubuntu ; en production, on installe souvent `ansible-core` avec `pipx` pour choisir sa version.
