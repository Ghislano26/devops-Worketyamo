# Ateliers Killercoda — Infrastructure as Code

Trois scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** : un serveur Ubuntu dans le navigateur. Rien à installer sur votre poste : **Terraform et Ansible sont installés par l'introduction de chaque scénario**.

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-premier-projet-terraform`](atelier-01-premier-projet-terraform/) | `ubuntu` | ~25 min | ⭐⭐ | HCL, provider `local`, `init`/`plan`/`apply`/`destroy`, **state**, dérive | [1](../cours/01-introduction-iac.md), [2](../cours/02-terraform-fondamentaux.md) |
| [`atelier-02-ansible-playbook-idempotent`](atelier-02-ansible-playbook-idempotent/) | `ubuntu` | ~25 min | ⭐⭐⭐ | Inventaire local, playbook nginx, handler, `changed=0` au 2ᵉ passage, `--check --diff` | [4](../cours/04-ansible-fondamentaux.md) |
| [`atelier-03-modules-et-roles`](atelier-03-modules-et-roles/) | `ubuntu` | ~30 min | ⭐⭐⭐ | Rôle Ansible (`defaults`, `tasks`, `handlers`, `templates`), surcharge de variables, idempotence | [3](../cours/03-terraform-avance.md), [5](../cours/05-ansible-avance.md) |

**Lisez le cours associé avant chaque atelier.** Les cours 6 (Terraform ou Ansible ?) et 7 (bonnes pratiques) sont surtout théoriques : ils se mettent en pratique sur un vrai dépôt.

## Ce que fait chaque scénario sur la machine

| Atelier | Installe | Crée | Vérification (`verify.sh`) |
|---|---|---|---|
| 1 | Terraform 1.9.8 (binaire HashiCorp) | `~/tf-premier/` : `main.tf`, `sortie/bienvenue.txt` | `terraform state list`, **`terraform plan -detailed-exitcode` = 0**, fichier présent puis **détruit** |
| 2 | `ansible` (paquet Ubuntu) | `~/ansible-nginx/` ; **nginx** et `/etc/nginx/conf.d/atelier.conf` | **Le script relance le playbook et exige `changed=0`**, `curl` sur le port 8080 |
| 3 | `ansible` | `~/ansible-roles/` : rôle `webserver` ; nginx sur 8080 puis 9090 | Structure du rôle, **second passage `changed=0`**, `curl` sur le port 9090, README du rôle |

Les vérifications **testent l'état réel** (service actif, page servie, plan sans changement, recap Ansible), pas seulement la présence des fichiers.

## Prérequis réseau

Les scénarios téléchargent des outils et des plugins : prévoyez une connexion et quelques minutes au premier lancement.

| Téléchargement | Source | Taille indicative |
|---|---|---|
| Terraform | `releases.hashicorp.com` | ~25 Mo |
| Provider `hashicorp/local` | `registry.terraform.io` (par `terraform init`) | quelques Mo |
| Ansible | Dépôts Ubuntu (`apt`) | plusieurs dizaines de Mo (jusqu'à ~200 Mo avec le méta-paquet `ansible`) |
| nginx | Dépôts Ubuntu | quelques Mo |

## Publier sur Killercoda

Procédure complète (dépôt GitHub, `structure.json`, mises à jour, tests) dans [**`KILLERCODA.md`**](../../KILLERCODA.md). Contrôle local avant de pousser :

```bash
python3 scripts/check-killercoda.py
```

> ⚠️ **Attention** : ces ateliers installent des logiciels et des services (`nginx`) **sur la machine du scénario**, jetable. Ne les exécutez pas tels quels sur un serveur que vous voulez conserver.

[← Retour au module 13](../README.md)
