# Définir un SLO et un error budget

**Durée : ~25 minutes.** Compétence travaillée : mesurer un **SLI** avec PromQL, écrire un **SLO**, calculer le **budget d'erreur** et en tirer une **décision**.

Rappel du [cours SLI, SLO et error budget](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/02-slo-sli-error-budget.md) :

```text
SLI = requêtes bonnes / requêtes valides          SLO = 99,9 % sur 30 jours
Budget d'erreur = 100 % − SLO = 0,1 %  →  43,2 minutes d'indisponibilité sur 30 jours
Budget restant ≤ 0  →  gel des releases ;  > 0  →  on livre
```

## Comment mesurer sans attendre 7 jours de données ?

Prometheus offre **`promtool test rules`** : on lui donne des **séries simulées** (`input_series`) et la valeur attendue d'une règle à un instant donné. C'est la méthode utilisée en pratique pour **tester ses règles de SLO** avant de les déployer. Aucun serveur Prometheus n'est nécessaire.

## Mise en place

Ce script crée le dossier `~/slo` avec les deux jeux de données simulés, et télécharge l'image Prometheus (elle fournit `promtool`) :

```bash
mkdir -p ~/slo && cd ~/slo
cat > test-sli-7j.yml <<'EOF'
rule_files:
  - slo.rules.yml
evaluation_interval: 1h
tests:
  - interval: 1h
    input_series:
      - series: 'http_requests_total{code="200"}'
        values: '0+9985x168'
      - series: 'http_requests_total{code="500"}'
        values: '0+15x168'
    promql_expr_test:
      - expr: round(slo:sli_availability:ratio_7d, 0.0001)
        eval_time: 168h
        exp_samples:
          - labels: '{}'
            value: 0.9985
EOF
cat > test-budget-30j.yml <<'EOF'
rule_files:
  - slo.rules.yml
evaluation_interval: 1h
tests:
  - interval: 1h
    input_series:
      - series: 'http_requests_total{code="200"}'
        values: '0+9995x720'
      - series: 'http_requests_total{code="500"}'
        values: '0+5x720'
    promql_expr_test:
      - expr: round(slo:error_budget_remaining:ratio_30d, 0.001)
        eval_time: 720h
        exp_samples:
          - labels: '{}'
            value: 0.5
EOF
docker pull prom/prometheus:v3.5.0
ls ~/slo
```{{exec}}

Vérifiez `promtool` :

```bash
docker run --rm --entrypoint promtool prom/prometheus:v3.5.0 --version
```{{exec}}

Lisez un jeu de données : `'0+9985x168'` signifie « part de 0, ajoute 9985 à chaque pas, 168 fois » (un pas = 1 h) : un compteur qui progresse de 9 985 requêtes réussies **par heure**.
