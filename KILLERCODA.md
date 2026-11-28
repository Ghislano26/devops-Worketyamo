# Publier les scénarios sur Killercoda

Ce document explique **comment faire détecter** par [Killercoda](https://killercoda.com/) les scénarios des modules **08 (Docker)**, **09 (Kubernetes)**, **10 (Monitoring)**, **11 (SRE)**, **12 (CI/CD)**, **13 (IaC)**, **14 (Cloud AWS)** et **15 (GitOps Argo CD)**, avec deux options, puis la procédure d'import, de mise à jour et de test.

> 📌 **Ce qui est vérifié, ce qui ne l'est pas.** Le format de `structure.json` ci-dessous est confirmé par les dépôts d'exemple **officiels** de Killercoda ([`scenario-examples-groups`](https://github.com/killercoda/scenario-examples-groups), [`scenarios-kubernetes`](https://github.com/killercoda/scenarios-kubernetes)). En revanche, le **parcours exact dans l'interface Killercoda** (menus, boutons) n'a pas pu être vérifié depuis cette machine (la documentation est rendue en JavaScript) : suivez la documentation officielle <https://killercoda.com/creators> pour ces écrans. Les points non confirmés sont marqués **⚠️ à confirmer**.

## 1. Diagnostic de la structure actuelle

Les scénarios sont rangés **à l'intérieur de chaque module** :

```text
devops-Worketyamo/                                   ← racine du dépôt
├── 08-docker-approfondi/ateliers-killercoda/
│   ├── README.md
│   └── atelier-01-premiers-pas/index.json …         ← profondeur 3 : <module>/ateliers-killercoda/<scénario>
├── 09-kubernetes-approfondi/ateliers-killercoda/atelier-0X-…/
└── 10-monitoring-observabilite/ateliers-killercoda/atelier-0X-…/
```

Ce que disent les exemples officiels :

- Killercoda repère un scénario grâce à son **`index.json`**.
- « *Scenarios in a subdirectory are considered a group/course.* » : un scénario au **niveau 1** (`<scénario>/`) ou **niveau 2** (`<groupe>/<scénario>/`) est reconnu.
- « *Once a `structure.json` is available, only the information from that file will be used.* » et « *Any scenario or directory that exists outside the `structure.json` will be ignored.* ».
- Dans un `structure.json`, un `path` peut être **imbriqué** (exemple officiel : `"category1/scenarioB"`, `"../course1/scenario1"`).

**Conséquence** : nos scénarios sont à **3 niveaux de profondeur** (`<module>/ateliers-killercoda/<scénario>`). Sans `structure.json`, rien ne garantit qu'ils soient détectés (⚠️ à confirmer : la règle de détection automatique par défaut n'est documentée que pour 1 ou 2 niveaux). Il faut donc **déclarer explicitement** les chemins (option A) ou **remonter les scénarios à la racine** d'un dépôt dédié (option B).

## 2. Les deux options

| | **A. Monorepo + `structure.json`** | **B. Dépôts séparés générés** |
|---|---|---|
| Principe | Un fichier `structure.json` **à la racine** liste les chemins imbriqués | Un script copie les scénarios dans **un dépôt par module**, à plat |
| Source de vérité | **Unique** (ce dépôt) | Ce dépôt ; les dépôts générés sont des **copies** |
| Dépôts GitHub à gérer | **1** (celui-ci) | **6** (docker, kubernetes, monitoring, sre, cicd, iac) — ou 7 avec `--all` |
| Maintenance | Ajouter une ligne par nouveau scénario | Régénérer et pousser après chaque modification |
| Risque de divergence | Aucun | Réel (copie à resynchroniser) |
| Dépend de | Support des chemins imbriqués à la racine (⚠️ à confirmer, voir A2) | Cas standard, **le plus sûr** (scénarios à la racine) |
| Quand la choisir | **Par défaut** | Si l'option A n'est pas détectée, ou pour avoir des dépôts/URL distincts |

### Option A — `structure.json` à la racine (monorepo)

Le fichier [`structure.json`](structure.json) est déjà créé à la racine :

```json
{
  "items": [
    { "path": "08-docker-approfondi/ateliers-killercoda/atelier-01-premiers-pas" },
    { "path": "08-docker-approfondi/ateliers-killercoda/atelier-02-dockerfile-multistage" },
    { "path": "08-docker-approfondi/ateliers-killercoda/atelier-03-compose-reseau" },
    { "path": "09-kubernetes-approfondi/ateliers-killercoda/atelier-01-premier-pod-et-deployment" },
    { "path": "09-kubernetes-approfondi/ateliers-killercoda/atelier-02-service-et-nodeport" },
    { "path": "09-kubernetes-approfondi/ateliers-killercoda/atelier-03-configmap-secret-et-rbac" },
    { "path": "10-monitoring-observabilite/ateliers-killercoda/atelier-01-prometheus-grafana-ubuntu" },
    { "path": "10-monitoring-observabilite/ateliers-killercoda/atelier-02-promql-requetes" },
    { "path": "10-monitoring-observabilite/ateliers-killercoda/atelier-03-alertes-avec-alertmanager" },
    { "path": "10-monitoring-observabilite/ateliers-killercoda/atelier-04-monitoring-kubernetes" },
    { "path": "11-sre-pratiques/ateliers-killercoda/atelier-01-definir-slo-et-error-budget" },
    { "path": "11-sre-pratiques/ateliers-killercoda/atelier-02-postmortem-blameless" },
    { "path": "11-sre-pratiques/ateliers-killercoda/atelier-03-chaos-engineering-basique" },
    { "path": "12-cicd/ateliers-killercoda/atelier-01-premier-workflow-actions" },
    { "path": "12-cicd/ateliers-killercoda/atelier-02-pipeline-build-test-push" },
    { "path": "12-cicd/ateliers-killercoda/atelier-03-securite-sast-sbom" },
    { "path": "12-cicd/ateliers-killercoda/atelier-04-deploiement-canary-kubernetes" },
    { "path": "13-iac/ateliers-killercoda/atelier-01-premier-projet-terraform" },
    { "path": "13-iac/ateliers-killercoda/atelier-02-ansible-playbook-idempotent" },
    { "path": "13-iac/ateliers-killercoda/atelier-03-modules-et-roles" },
    { "path": "14-cloud-aws/ateliers-killercoda/atelier-01-localstack-premiers-pas" },
    { "path": "14-cloud-aws/ateliers-killercoda/atelier-02-s3-avec-awscli" },
    { "path": "14-cloud-aws/ateliers-killercoda/atelier-03-iam-policies" },
    { "path": "15-gitops-argocd/ateliers-killercoda/atelier-01-argo-cd-installation-premier-deploiement" },
    { "path": "15-gitops-argocd/ateliers-killercoda/atelier-02-selfheal-et-prune" },
    { "path": "15-gitops-argocd/ateliers-killercoda/atelier-03-applicationset-multi-env" }
  ]
}
```

| Module | Backend | Scénarios déclarés |
|---|---|---|
| 08 — Docker approfondi | `ubuntu` | `atelier-01-premiers-pas`, `atelier-02-dockerfile-multistage`, `atelier-03-compose-reseau` |
| 09 — Kubernetes approfondi | `kubernetes-kubeadm-1node` | `atelier-01-premier-pod-et-deployment`, `atelier-02-service-et-nodeport`, `atelier-03-configmap-secret-et-rbac` |
| 10 — Monitoring | `ubuntu` (1 à 3), `kubernetes-kubeadm-1node` (4) | `atelier-01-prometheus-grafana-ubuntu`, `atelier-02-promql-requetes`, `atelier-03-alertes-avec-alertmanager`, `atelier-04-monitoring-kubernetes` |
| 11 — SRE : pratiques | `ubuntu` (1 et 2), `kubernetes-kubeadm-1node` (3) | `atelier-01-definir-slo-et-error-budget`, `atelier-02-postmortem-blameless`, `atelier-03-chaos-engineering-basique` |
| 12 — CI/CD | `ubuntu` (1 à 3), `kubernetes-kubeadm-1node` (4) | `atelier-01-premier-workflow-actions`, `atelier-02-pipeline-build-test-push`, `atelier-03-securite-sast-sbom`, `atelier-04-deploiement-canary-kubernetes` |
| 13 — IaC | `ubuntu` (1 à 3) | `atelier-01-premier-projet-terraform`, `atelier-02-ansible-playbook-idempotent`, `atelier-03-modules-et-roles` |
| 14 — Cloud AWS (LocalStack) | `ubuntu` (1 à 3) | `atelier-01-localstack-premiers-pas`, `atelier-02-s3-avec-awscli`, `atelier-03-iam-policies` |
| 15 — GitOps Argo CD | `kubernetes-kubeadm-1node` (1 à 3) | `atelier-01-argo-cd-installation-premier-deploiement`, `atelier-02-selfheal-et-prune`, `atelier-03-applicationset-multi-env` |

Les chemins sont **relatifs au fichier** `structure.json` (donc à la racine du dépôt). Les titres viennent des `index.json` : on ne les répète pas ici pour éviter toute divergence.

> ⚠️ **Attention — effet de bord important.** Dès que `structure.json` existe, **seuls** les scénarios listés sont pris en compte. Les **8 scénarios Linux** (modules 01 à 04, dossiers `*/ateliers-killercoda/`) **ne figurent pas** dans ce fichier : ils seront **ignorés** par Killercoda. Ils n'ont pas été ajoutés car la demande portait sur les modules 08, 09 et 10. Pour les inclure, voir la [section 5](#5-et-les-scénarios-linux-01-à-04-).

#### A2 — Variante si les chemins imbriqués ne sont pas acceptés à la racine

Les exemples officiels montrent des chemins imbriqués dans le `structure.json` **d'un dossier-cours** (`course2/structure.json` contient `"category1/scenarioB"`), pas explicitement à la racine. Si Killercoda ne détecte pas les scénarios avec le fichier racine, utilisez des **groupes** : le fichier racine liste les dossiers-cours, chacun a son propre `structure.json` :

```json
{
  "items": [
    { "path": "08-docker-approfondi/ateliers-killercoda", "title": "Docker approfondi" },
    { "path": "09-kubernetes-approfondi/ateliers-killercoda", "title": "Kubernetes approfondi" },
    { "path": "10-monitoring-observabilite/ateliers-killercoda", "title": "Monitoring & Observabilité" }
  ]
}
```

et, par exemple, `08-docker-approfondi/ateliers-killercoda/structure.json` :

```json
{
  "title": "Docker approfondi",
  "description": "Cours Docker approfondis : architecture, images, Dockerfile, réseau, Compose, sécurité.",
  "items": [
    { "path": "atelier-01-premiers-pas" },
    { "path": "atelier-02-dockerfile-multistage" },
    { "path": "atelier-03-compose-reseau" }
  ]
}
```

(Ces fichiers de groupe ne sont **pas** créés par défaut : ils ne servent que si A ne fonctionne pas. Si besoin, ils s'ajoutent en quelques minutes, sans toucher aux scénarios.)

### Option B — dépôts séparés, prêts à pousser

Le script [`scripts/export-killercoda-repos.sh`](scripts/export-killercoda-repos.sh) copie les scénarios **à la racine** de dépôts dédiés, avec un `structure.json` à plat, un `README.md` et la `LICENSE` :

```bash
scripts/export-killercoda-repos.sh                    # modules 08, 09, 10, 11, 12, 13, 14, 15 → ../worketyamo-killercoda-export/
scripts/export-killercoda-repos.sh --all              # + modules Linux 01 à 04 (dépôt « linux »)
scripts/export-killercoda-repos.sh /chemin/de/sortie  # dossier de sortie au choix
```

Résultat (mode par défaut, 8 dépôts) :

```text
worketyamo-killercoda-export/
├── worketyamo-killercoda-docker/        (3 scénarios)
├── worketyamo-killercoda-kubernetes/    (3 scénarios)
├── worketyamo-killercoda-monitoring/    (4 scénarios)
├── worketyamo-killercoda-sre/           (3 scénarios)
├── worketyamo-killercoda-cicd/          (4 scénarios)
├── worketyamo-killercoda-iac/           (3 scénarios)
├── worketyamo-killercoda-cloud-aws/     (3 scénarios)
└── worketyamo-killercoda-gitops/        (3 scénarios)
      ├── structure.json   ← { "items": [ { "path": "atelier-01-…" }, … ] }
      ├── README.md   LICENSE
      └── atelier-01-…/   atelier-02-…/ …   (même structure dans chaque dépôt)
```

Le script **ne supprime rien** (il refuse d'écraser un dépôt existant) et écrit **hors de ce dépôt** par défaut. Pousser un dépôt généré :

```bash
cd ../worketyamo-killercoda-export/worketyamo-killercoda-docker
git init -b main && git add . && git commit -m "Scénarios Killercoda : Docker"
gh repo create <votre-compte>/worketyamo-killercoda-docker --public --source=. --push     # ou : git remote add … && git push
```

Les liens du contenu des scénarios (vers les cours) sont des **URL absolues** vers ce dépôt (`https://github.com/Ghislano26/devops-Worketyamo/blob/main/…`) : ils continuent de fonctionner depuis les dépôts générés, tant que ce dépôt-ci reste public et que la branche `main` existe.

> 💡 **Conseil** : les dépôts générés sont des **copies jetables**. Ne les éditez jamais directement : corrigez les scénarios **ici**, puis régénérez dans un dossier neuf (`rm -rf` du dossier de sortie, puis relancer le script).

## Scénarios disponibles

| # | Module | Scénario | Backend | Déclaré dans `structure.json` |
|---|---|---|---|---|
| 1 | 08 — Docker | `atelier-01-premiers-pas` | `ubuntu` | ✅ |
| 2 | 08 — Docker | `atelier-02-dockerfile-multistage` | `ubuntu` | ✅ |
| 3 | 08 — Docker | `atelier-03-compose-reseau` | `ubuntu` | ✅ |
| 4 | 09 — Kubernetes | `atelier-01-premier-pod-et-deployment` | `kubernetes-kubeadm-1node` | ✅ |
| 5 | 09 — Kubernetes | `atelier-02-service-et-nodeport` | `kubernetes-kubeadm-1node` | ✅ |
| 6 | 09 — Kubernetes | `atelier-03-configmap-secret-et-rbac` | `kubernetes-kubeadm-1node` | ✅ |
| 7 | 10 — Monitoring | `atelier-01-prometheus-grafana-ubuntu` | `ubuntu` | ✅ |
| 8 | 10 — Monitoring | `atelier-02-promql-requetes` | `ubuntu` | ✅ |
| 9 | 10 — Monitoring | `atelier-03-alertes-avec-alertmanager` | `ubuntu` | ✅ |
| 10 | 10 — Monitoring | `atelier-04-monitoring-kubernetes` | `kubernetes-kubeadm-1node` | ✅ |
| 11 | 11 — SRE | `atelier-01-definir-slo-et-error-budget` | `ubuntu` | ✅ |
| 12 | 11 — SRE | `atelier-02-postmortem-blameless` | `ubuntu` | ✅ |
| 13 | 11 — SRE | `atelier-03-chaos-engineering-basique` | `kubernetes-kubeadm-1node` | ✅ |
| 14 | 12 — CI/CD | `atelier-01-premier-workflow-actions` | `ubuntu` | ✅ |
| 15 | 12 — CI/CD | `atelier-02-pipeline-build-test-push` | `ubuntu` | ✅ |
| 16 | 12 — CI/CD | `atelier-03-securite-sast-sbom` | `ubuntu` | ✅ |
| 17 | 12 — CI/CD | `atelier-04-deploiement-canary-kubernetes` | `kubernetes-kubeadm-1node` | ✅ |
| 18 | 13 — IaC | `atelier-01-premier-projet-terraform` | `ubuntu` | ✅ |
| 19 | 13 — IaC | `atelier-02-ansible-playbook-idempotent` | `ubuntu` | ✅ |
| 20 | 13 — IaC | `atelier-03-modules-et-roles` | `ubuntu` | ✅ |
| 21 | 14 — Cloud AWS | `atelier-01-localstack-premiers-pas` | `ubuntu` | ✅ |
| 22 | 14 — Cloud AWS | `atelier-02-s3-avec-awscli` | `ubuntu` | ✅ |
| 23 | 14 — Cloud AWS | `atelier-03-iam-policies` | `ubuntu` | ✅ |
| 24 | 15 — GitOps Argo CD | `atelier-01-argo-cd-installation-premier-deploiement` | `kubernetes-kubeadm-1node` | ✅ |
| 25 | 15 — GitOps Argo CD | `atelier-02-selfheal-et-prune` | `kubernetes-kubeadm-1node` | ✅ |
| 26 | 15 — GitOps Argo CD | `atelier-03-applicationset-multi-env` | `kubernetes-kubeadm-1node` | ✅ |
| 27-34 | 01 à 04 — Linux | 8 scénarios `*-killercoda` (voir la [section 5](#5-et-les-scénarios-linux-01-à-04-)) | `ubuntu` | ❌ **non déclarés** (donc ignorés par Killercoda) |

**26 scénarios sont déclarés** (modules 08 à 15). Les 8 scénarios Linux existent dans le dépôt mais ne sont pas dans `structure.json` : décision à prendre (section 5). Vérifiez à tout moment avec `python3 scripts/check-killercoda.py`.

> **Note — module 12 (CI/CD)** : le module 12 utilise `act` pour exécuter GitHub Actions localement, car Killercoda ne peut pas déclencher de vrais workflows GitHub (il n'est pas relié à votre dépôt et n'a pas vos secrets). `act` imite GitHub sans être identique ; voir [`12-cicd/ateliers-killercoda/README.md`](12-cicd/ateliers-killercoda/README.md).

> **Note — module 13 (IaC)** : les 3 scénarios du module 13 **installent eux-mêmes Terraform et Ansible** sur la machine Ubuntu du scénario (binaire HashiCorp, paquet `ansible`) et n'ont **besoin d'aucun compte cloud** : Terraform y gère des fichiers locaux (provider `local`), Ansible configure `localhost`. Prévoyez quelques minutes de téléchargement au premier lancement ; voir [`13-iac/ateliers-killercoda/README.md`](13-iac/ateliers-killercoda/README.md).

> **Note — module 14 (Cloud AWS)** : les 3 scénarios du module 14 n'utilisent **aucun compte AWS** : ils installent `awscli` v2 et lancent **LocalStack** (`localstack/localstack:3.8`, image épinglée d'environ 1 Go, téléchargée par `docker run`) sur la machine Ubuntu du scénario. LocalStack est un **émulateur** : les données sont éphémères et certaines fonctions (notamment l'application des policies IAM en édition communautaire) ne sont pas supportées ; voir [`14-cloud-aws/ateliers-killercoda/README.md`](14-cloud-aws/ateliers-killercoda/README.md). Prévoyez 2 à 4 minutes de démarrage au premier lancement.

> **Note — module 15 (GitOps Argo CD)** : les 3 scénarios du module 15 utilisent le backend `kubernetes-kubeadm-1node` et **installent eux-mêmes Argo CD** (manifestes officiels `v2.13.3`, appliqués avec `--server-side`) : prévoyez **2 à 4 minutes** et l'accès à `github.com`, `quay.io` et `ghcr.io`. L'atelier 2 monte un **serveur Git local** (pod nginx + dépôt nu sur le disque du nœud) pour pouvoir modifier Git ; voir [`15-gitops-argocd/ateliers-killercoda/README.md`](15-gitops-argocd/ateliers-killercoda/README.md).

## 3. Procédure d'import

1. **Compte** : créez un compte sur <https://killercoda.com/> (connexion GitHub possible) et choisissez votre nom d'utilisateur (il apparaît dans les URL de vos scénarios).
2. **Prérequis du dépôt** : dépôt GitHub **public** (⚠️ à confirmer pour un dépôt privé : consultez la documentation « Creators »), avec `structure.json` / `index.json` **poussés sur la branche par défaut** (`main`).
3. **Lier le dépôt** : dans votre profil Killercoda, ouvrez l'espace **Creator** et suivez l'assistant de liaison à GitHub (⚠️ à confirmer : intitulés exacts des boutons) ; autorisez l'accès au dépôt ciblé. Documentation : <https://killercoda.com/creators>.
   - Option A : liez **ce** dépôt (`Ghislano26/devops-Worketyamo`).
   - Option B : liez **chaque** dépôt généré.
4. **Backend** : il est déjà fixé dans chaque `index.json` (`"backend": {"imageid": "ubuntu"}` ou `"kubernetes-kubeadm-1node"`) : rien à choisir dans l'interface.
5. **Ouvrir un scénario** : depuis votre page Creator, ou par son adresse. Le format habituel est `https://killercoda.com/<votre-nom>/scenario/<nom-du-dossier>` (⚠️ à confirmer). Le **nom du dossier** sert d'identifiant : il doit être **unique** (le script de contrôle le vérifie).
6. **Premier test** : lancez `atelier-01-premiers-pas`, exécutez les commandes et cliquez sur **Vérifier** à chaque étape.

## 4. Mise à jour

| Situation | Action |
|---|---|
| Modifier le texte ou un `verify.sh` d'un scénario | Éditer **ici**, valider avec le script de contrôle, commit et **push sur la branche liée** (⚠️ à confirmer : la synchronisation est déclenchée par le push ; un délai de quelques minutes ou un cache peut retarder l'affichage) |
| Ajouter un scénario (option A) | Créer le dossier, **ajouter un item dans `structure.json`**, contrôler, pousser |
| Ajouter un scénario (option B) | Créer le dossier ici, **régénérer** les dépôts (script), **pousser chaque dépôt modifié** |
| Renommer un scénario | Renommer le dossier **et** son entrée `structure.json` ; l'ancienne URL cesse de fonctionner |
| Retirer un scénario | Supprimer l'item de `structure.json` (et le dossier) |

**Check-list d'un nouveau scénario** : dossier `atelier-XX-nom/` · `index.json` (titre, description, `details`, `backend.imageid`) · `intro.md`, `finish.md` · `stepN/text.md` + `stepN/verify.sh` (`chmod +x`) · item ajouté à `structure.json` · `python3 scripts/check-killercoda.py` au vert.

## 5. Et les scénarios Linux (01 à 04) ?

Les modules Linux contiennent **8 scénarios Killercoda** (`01-linux-fondamentaux`, `02-linux-intermediaire`, `03-linux-avance`, `04-linux-expert`, sous `ateliers-killercoda/`). Avec le `structure.json` actuel, ils sont **ignorés** (le script de contrôle les signale en avertissement). Pour les inclure, **ajoutez ces 8 items** dans le tableau `items` de `structure.json` :

```json
    { "path": "01-linux-fondamentaux/ateliers-killercoda/atelier-01-navigation-killercoda" },
    { "path": "01-linux-fondamentaux/ateliers-killercoda/atelier-02-fichiers-killercoda" },
    { "path": "01-linux-fondamentaux/ateliers-killercoda/atelier-03-permissions-killercoda" },
    { "path": "02-linux-intermediaire/ateliers-killercoda/atelier-01-processus-services-killercoda" },
    { "path": "02-linux-intermediaire/ateliers-killercoda/atelier-02-apt-paquets-killercoda" },
    { "path": "03-linux-avance/ateliers-killercoda/atelier-01-scripting-bash-killercoda" },
    { "path": "03-linux-avance/ateliers-killercoda/atelier-02-awk-sed-grep-killercoda" },
    { "path": "04-linux-expert/ateliers-killercoda/atelier-01-namespaces-cgroups-killercoda" }
```

(Avec l'option B : `scripts/export-killercoda-repos.sh --all` génère aussi le dépôt `worketyamo-killercoda-linux`.)

## 6. Tests

### 6.1 Contrôle local avant de pousser

```bash
python3 scripts/check-killercoda.py                       # contrôle ce dépôt (option A)
python3 scripts/check-killercoda.py ../worketyamo-killercoda-export/worketyamo-killercoda-docker    # contrôle un dépôt généré (option B)
```

Le script (Python 3, sans dépendance) vérifie : `structure.json` valide ; chaque `path` existe et contient un `index.json` valide ; `intro`, `finish`, `text.md` et `verify.sh` référencés **existent et ne sont pas vides** ; chaque `verify.sh` est **exécutable** et passe `bash -n` ; `backend.imageid` renseigné ; **noms de scénarios uniques** ; et il **avertit** des scénarios présents mais non déclarés. Code de retour `1` en cas d'erreur (utilisable en CI).

```bash
shellcheck $(find . -name verify.sh)                      # analyse statique des vérifications
```

### 6.2 Test de bout en bout sur Killercoda

1. Ouvrez le scénario et lisez `intro.md`.
2. Exécutez chaque étape **à la main** (clic sur les blocs `{{exec}}`).
3. Cliquez sur **Vérifier** : **volontairement avant** d'avoir fini (le message doit expliquer ce qui manque), puis **après** (l'étape doit passer).
4. Terminez par `finish.md` et relisez les liens.

Points à surveiller (non testés tant que le scénario n'a pas été lancé) : durée de téléchargement des images (`prom/prometheus`, `grafana/grafana`, `gcr.io/cadvisor`), disponibilité de `jq`/`helm` dans l'environnement, image `kubernetes-kubeadm-1node` suffisante pour `kube-prometheus-stack`.

### 6.3 Tester une vérification en local

```bash
bash 08-docker-approfondi/ateliers-killercoda/atelier-01-premiers-pas/step1/verify.sh ; echo "code = $?"
```

(Sur une VM Ubuntu avec Docker : même comportement qu'en ligne ; `0` = étape réussie.)

## 7. Dépannage

| Symptôme | Cause probable | Piste |
|---|---|---|
| Scénario **introuvable / non listé** | Chemin absent de `structure.json`, ou `structure.json` non poussé sur la branche liée | `python3 scripts/check-killercoda.py` (avertissements) ; vérifier la branche |
| Aucun scénario détecté avec l'option A | Chemins imbriqués non acceptés à la racine | Passer à **A2** (groupes) ou à l'**option B** |
| Scénario **ignoré** alors qu'il existe | Il n'est pas dans `structure.json` : « tout ce qui est hors du fichier est ignoré » | Ajouter l'item |
| **Vérifier** reste en échec | `verify.sh` non exécutable, erreur de syntaxe, ou condition non remplie | `chmod +x`, `bash -n`, relire le message affiché |
| Étape qui dépend d'un service lent (Grafana, Helm) | Délai de démarrage | Relancer **Vérifier** après quelques secondes ; les scripts réessayent déjà plusieurs fois |
| Liens des scénarios cassés dans un dépôt généré | Les URL absolues pointent vers ce dépôt | Vérifier que `Ghislano26/devops-Worketyamo` est public, branche `main` |
| Modifications poussées mais anciennes versions affichées | Cache / synchronisation | Patienter, puis relancer une nouvelle session du scénario |

[← Retour au README principal](README.md)
