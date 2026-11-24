# Principes du CI/CD

## Pourquoi ce cours ?

Livrer une application « à la main » (copier des fichiers par SSH, relancer un service) est lent, risqué et
non reproductible. Le **CI/CD** automatise le chemin qui va du *commit* du développeur jusqu'à la
*production*, avec des contrôles à chaque étape. C'est le cœur de la culture DevOps : livrer **plus souvent**, **plus
sûrement**, avec **moins de stress**.

## 1. Définitions

| Sigle | Signification | Question à laquelle il répond |
|---|---|---|
| **CI** | *Continuous Integration* — Intégration continue | « Le code de chacun s'assemble-t-il et passe-t-il les tests ? » |
| **CD** (*Delivery*) | Livraison continue | « Pouvons-nous déployer à tout moment, d'un clic ? » |
| **CD** (*Deployment*) | Déploiement continu | « Chaque changement validé part-il en production automatiquement ? » |

```text
 Développeur
     │ git push
     ▼
┌──────────┐  ┌────────┐  ┌────────┐  ┌──────────┐  ┌────────┐  ┌────────────┐
│  Source  │─►│ Build  │─►│ Tests  │─►│ Analyse  │─►│Artefact│─►│ Déploiement│
│  (Git)   │  │        │  │        │  │ sécurité │  │ (image)│  │ test → prod│
└──────────┘  └────────┘  └────────┘  └──────────┘  └────────┘  └────────────┘
                     └────────── CI ─────────────────────┘ └──────── CD ───────┘
```

## 2. Pourquoi cela change tout

- **Détection précoce** des erreurs : un bug trouvé 5 minutes après le commit coûte bien moins qu'un bug trouvé en production.
- **Reproductibilité** : le même processus, à chaque fois, sans oubli humain.
- **Rapidité** : de nombreux déploiements par jour deviennent possibles.
- **Traçabilité** : chaque version déployée correspond à un commit identifié.
- **Confiance** : on déploie un vendredi sans trembler… (en théorie).

Mesures de performance DevOps (**DORA**) : fréquence de déploiement, délai de mise en production, taux d'échec des changements, temps de rétablissement.

## 3. Principes de l'intégration continue

1. **Un dépôt unique** de référence (Git).
2. **Intégrer souvent** (au moins une fois par jour) vers la branche principale.
3. **Construire à chaque commit**, automatiquement.
4. **Tests automatisés** rapides ; un build cassé est la priorité n°1 de l'équipe.
5. **Un seul artefact** construit une fois, **promu** d'environnement en environnement (« build once, deploy many »).
6. **Retour rapide** : un pipeline CI de plus de 10 minutes décourage.

## 4. Anatomie d'un pipeline

| Concept | Définition |
|---|---|
| **Pipeline** | Enchaînement automatisé d'étapes |
| **Stage** (étape) | Groupe logique : build, test, deploy |
| **Job** | Tâche exécutée dans un stage |
| **Runner / agent** | Machine ou conteneur qui exécute les jobs |
| **Artefact** | Résultat conservé (binaire, image, rapport) |
| **Déclencheur** (*trigger*) | `push`, `pull_request`, calendrier, manuel, tag |
| **Secret** | Valeur sensible injectée à l'exécution |
| **Cache** | Réutilisation de dépendances entre exécutions |

### La pyramide des tests

```text
          ▲ lents, coûteux, peu nombreux
         /E2E\          tests de bout en bout (navigateur, API réelle)
        /──────\
       /intégra-\       tests d'intégration (base de données, services)
      /  tion    \
     /────────────\
    /  unitaires   \    tests unitaires : rapides, nombreux
   /────────────────\
          ▼ rapides, bon marché, nombreux
```

## 5. Exemple : GitHub Actions

Les workflows sont des fichiers YAML dans `.github/workflows/`.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  qualite:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - name: Vérifier les scripts shell
        run: |
          sudo apt-get update -qq
          sudo apt-get install -y -qq shellcheck
          shellcheck scripts/*.sh

      - name: Tests
        run: ./scripts/tests.sh

  image:
    needs: qualite
    runs-on: ubuntu-24.04
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
```

| Élément | Rôle |
|---|---|
| `on:` | Déclencheurs |
| `jobs:` | Tâches, parallèles par défaut ; `needs:` crée une dépendance |
| `runs-on:` | Type de runner |
| `steps:` | Étapes : `uses:` (action réutilisable) ou `run:` (commande shell) |
| `${{ secrets.X }}` | Accès aux secrets du dépôt |
| `if:` | Condition d'exécution |

### Équivalent GitLab CI (`.gitlab-ci.yml`)

```yaml
stages: [test, build]

test:
  stage: test
  image: ubuntu:24.04
  script:
    - apt-get update -qq && apt-get install -y -qq shellcheck
    - shellcheck scripts/*.sh

build:
  stage: build
  image: docker:27
  services: [docker:27-dind]
  script:
    - docker build -t "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA" .
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

> 💡 **Conseil** : épinglez les versions des actions (`@v4`, voire une empreinte de commit pour les actions tierces) : une action compromise peut exécuter du code dans votre pipeline.

## 6. Stratégies de déploiement

| Stratégie | Principe | Avantage | Inconvénient |
|---|---|---|---|
| **Recreate** | On arrête l'ancienne version, on lance la nouvelle | Simple | Interruption de service |
| **Rolling** | Remplacement progressif des instances | Sans coupure | Deux versions coexistent |
| **Blue/Green** | Deux environnements ; bascule du trafic | Retour arrière instantané | Double infrastructure |
| **Canary** | Une petite part du trafic vers la nouvelle version | Risque limité | Mise en place complexe |
| **Feature flags** | Code déployé mais fonctionnalité désactivée | Découple déploiement et mise en production | Dette technique si non nettoyé |

```text
Blue/Green :
 Utilisateurs ─► Routeur ─┬─► BLUE  (v1, actif)
                          └─► GREEN (v2, prête)   → bascule du routeur → rollback = rebascule
```

Toujours prévoir un **plan de retour arrière** (*rollback*) testé.

## 7. Gestion des secrets et de la sécurité (DevSecOps)

> ⚠️ **Attention** : un pipeline a souvent accès à vos serveurs de production : c'est une **cible privilégiée**. Protégez-le comme un système critique.

- **Secrets** : dans le coffre de la plateforme (`secrets.*`), jamais dans le dépôt ni dans les journaux (les plateformes masquent les valeurs, mais pas leurs transformations).
- **Moindre privilège** : jetons à durée limitée, droits minimaux (`permissions:`), environnements protégés avec approbation manuelle.
- **Analyses automatisées** (*shift left*) :
  - SAST : analyse du code (CodeQL, Semgrep) ;
  - dépendances : Dependabot, `pip-audit`, `npm audit` ;
  - **secrets** : `gitleaks`, `trufflehog` ;
  - **images** : Trivy, Grype ;
  - IaC : `tfsec`, `checkov`.
- **Chaîne d'approvisionnement** : signer les artefacts (cosign), produire une SBOM.

## 8. Infrastructure as Code et GitOps

- **IaC** : décrire l'infrastructure par du code versionné (Terraform, Ansible, scripts Bash). Reproductible, relue, testée.
- **GitOps** : l'état souhaité est dans Git ; un agent (Argo CD, Flux) **synchronise** le cluster avec le dépôt. Un déploiement = un *merge*.

## 9. Observabilité après déploiement

Un déploiement n'est pas terminé quand le pipeline est vert, mais quand la production est **saine** : sondes de santé (`HEALTHCHECK`), métriques, journaux ([cours observabilité](../../04-linux-expert/cours/03-observabilite-logs.md)), alertes, *rollback* automatique en cas de dégradation.

## 10. Bonnes pratiques et anti-patterns

| ✅ À faire | ❌ À éviter |
|---|---|
| Pipeline **en tant que code**, versionné | Configuration manuelle dans l'interface |
| Builds **reproductibles** (versions épinglées) | `latest` partout |
| Tests rapides et fiables | Tests « flaky » qu'on relance jusqu'à ce que ça passe |
| Petites modifications fréquentes | Énormes livraisons trimestrielles |
| Même artefact de dev à prod | Reconstruire pour chaque environnement |
| Journaux et artefacts conservés | Pipelines opaques |

> 📌 **À retenir** : un pipeline n'est utile que s'il est **rapide**, **fiable** et **bloquant** : un test rouge doit empêcher la livraison. Un pipeline qu'on contourne ne protège plus personne.

## Résumé

- **CI** = intégrer et tester automatiquement ; **CD** = livrer/déployer automatiquement.
- Un pipeline : *source → build → tests → analyse → artefact → déploiement*.
- Pyramide des tests ; « build once, deploy many ».
- Stratégies : recreate, rolling, blue/green, canary, feature flags ; prévoir le **rollback**.
- Sécurité : secrets protégés, moindre privilège, analyses automatiques, versions épinglées.
- IaC et GitOps prolongent la logique : **tout est dans Git**.

## Pour aller plus loin

- Documentation : GitHub Actions (`docs.github.com/actions`), GitLab CI/CD, Jenkins.
- Livres : *Continuous Delivery* (Humble & Farley), *The Phoenix Project*, rapport DORA / *Accelerate*.
- Outils : Terraform, Ansible, Argo CD, Kubernetes.
- Atelier associé : [Pipeline simple](../ateliers/atelier-03-pipeline-simple.md).
- Retour à la [vue d'ensemble du cours](../../README.md).
