# Module 13 — Infrastructure as Code (Terraform et Ansible)

## Pourquoi ce module ?

Vous savez écrire du code ([Git](../07-git-branching-interactif/README.md)), l'empaqueter ([Docker](../08-docker-approfondi/README.md)), l'orchestrer ([Kubernetes](../09-kubernetes-approfondi/README.md)) et le livrer automatiquement ([CI/CD](../12-cicd/README.md)). Reste une question : **qui crée les serveurs, les réseaux et les bases sur lesquels tout cela tourne, et comment les recréer à l'identique ?** Ce module répond par l'**Infrastructure as Code** : on **décrit** l'infrastructure dans des fichiers versionnés, et des outils la **créent** (Terraform / OpenTofu) et la **configurent** (Ansible).

> 🗺️ **Place dans le parcours.** Ce module porte le **numéro 13** mais se lit **après le CI/CD (12)** et **avant le Monitoring (10) et le SRE (11)**. La numérotation des dossiers est gelée ; l'ordre pédagogique est expliqué dans le [README principal](../README.md). La logique : **on livre** (12), **on décrit et on provisionne l'infrastructure qui accueille la livraison** (13), **on observe** (10), **on fiabilise** (11).

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [04 Linux expert](../04-linux-expert/README.md) | Processus, services, SSH, performance : ce qu'Ansible configure |
| [06 Réseaux](../06-reseaux-devops/README.md) | Adresses, ports, DNS : ce que Terraform déclare |
| [07 Git](../07-git-branching-interactif/README.md) | Branches et revues : l'IaC se travaille comme du code |
| [12 CI/CD](../12-cicd/README.md) | Pipelines, secrets, GitOps : le pipeline IaC s'appuie dessus |
| Notions de cloud | Facilitent la lecture des exemples (un module dédié est à venir) ; les ateliers n'en ont **pas besoin** |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Introduction à l'Infrastructure as Code](cours/01-introduction-iac.md) | ⭐⭐ | IaC, déclaratif vs impératif, idempotence, dérive, mutable vs immuable, panorama des outils |
| 2 | [Terraform : les fondamentaux](cours/02-terraform-fondamentaux.md) | ⭐⭐⭐ | HCL, providers, ressources, variables, outputs, `plan`/`apply`, state local et distant, dépendances |
| 3 | [Terraform avancé](cours/03-terraform-avance.md) | ⭐⭐⭐⭐ | Modules, workspaces vs répertoires, `for_each`, `moved`/`import`, `lifecycle`, `terraform test`, OpenTofu |
| 4 | [Ansible : les fondamentaux](cours/04-ansible-fondamentaux.md) | ⭐⭐⭐ | Architecture sans agent, inventaire, playbooks, modules, handlers, facts, idempotence, `--check` |
| 5 | [Ansible avancé](cours/05-ansible-avance.md) | ⭐⭐⭐⭐ | Rôles, collections, Vault, Jinja2, `delegate_to`, `serial`, stratégies, `ansible-lint`, AWX |
| 6 | [Terraform ou Ansible ?](cours/06-terraform-vs-ansible.md) | ⭐⭐⭐ | Provisioning vs configuration, schéma hybride, Packer + cloud-init, pièges classiques |
| 7 | [Bonnes pratiques IaC](cours/07-bonnes-pratiques-iac.md) | ⭐⭐⭐⭐ | Structure du dépôt, environnements, secrets, pipeline IaC, dérive, tests, documentation |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — Premier projet Terraform](ateliers-killercoda/atelier-01-premier-projet-terraform/intro.md) (2 étapes) | `ubuntu` | ⭐⭐ | 1, 2 |
| [Atelier 02 — Playbook Ansible idempotent](ateliers-killercoda/atelier-02-ansible-playbook-idempotent/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 4 |
| [Atelier 03 — Modules et rôles](ateliers-killercoda/atelier-03-modules-et-roles/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 3, 5 |

Procédure de publication : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 (Terraform) → Cours 03
        → Cours 04 → Atelier 02 (playbook idempotent) → Cours 05 → Atelier 03 (rôle)
        → Cours 06 → Cours 07
```

> 💡 **Conseil** : les ateliers n'ont besoin d'**aucun compte cloud** : Terraform y gère des fichiers locaux, Ansible configure la machine du scénario. Les mécanismes (plan, state, dérive, idempotence, handlers) sont **ceux d'un vrai cloud**. Pour aller plus loin, refaites l'atelier 1 avec un vrai provider sur un compte gratuit, en vérifiant toujours votre facturation.

## Ce que vous saurez faire à la fin

- Expliquer l'IaC, la **dérive** et l'**idempotence**, et choisir entre **déclaratif** et **impératif**.
- Écrire un projet **Terraform** (providers, variables, state distant, modules) et en lire les **plans**.
- Écrire des **playbooks** et des **rôles Ansible** idempotents, avec templates, handlers et secrets chiffrés.
- Choisir **Terraform, Ansible ou Packer** selon le besoin, et les combiner.
- Bâtir un **pipeline IaC** (plan en PR, apply au merge, détection de dérive) avec tests et revue.

## Navigation

- [← Module 12 — CI/CD complet](../12-cicd/README.md)
- [→ Module 10 — Monitoring et observabilité](../10-monitoring-observabilite/README.md) (étape suivante du parcours)
- [← README principal](../README.md)
