# Étape 1 : du SLI au SLO

Un **SLI** est un ratio *évènements bons / évènements valides* ; un **SLO** est un objectif sur ce SLI et une fenêtre (voir le [cours 02](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/02-slo-sli-error-budget.md)).

Le service simulé reçoit **10 000 requêtes par heure** : 9 985 réussies (`code="200"`) et 15 en erreur serveur (`code="500"`), pendant **7 jours** (168 heures). Ces données se trouvent dans `~/slo/test-sli-7j.yml` (jeu de **séries simulées** utilisé par `promtool test rules`).

## A. Écrire la règle d'enregistrement du SLI

Créez `~/slo/slo.rules.yml` avec une *recording rule* nommée **`slo:sli_availability:ratio_7d`** : la part de requêtes **non-5xx** sur **7 jours**.

```bash
cat > ~/slo/slo.rules.yml <<'EOF'
groups:
  - name: slo-disponibilite
    rules:
      - record: slo:sli_availability:ratio_7d
        expr: sum(increase(http_requests_total{code!~"5.."}[7d])) / sum(increase(http_requests_total[7d]))
EOF
```{{exec}}

Validez la syntaxe puis **testez** la règle sur les séries simulées (`promtool` est fourni par l'image Prometheus) :

```bash
promtool_docker() { docker run --rm --entrypoint promtool -v "$HOME/slo:/slo" -w /slo prom/prometheus:v3.5.0 "$@"; }
promtool_docker check rules slo.rules.yml
promtool_docker test rules test-sli-7j.yml
```{{exec}}

Le test attend un SLI de **0,9985** (99,85 %), arrondi à 4 décimales avec `round()` pour éviter les écarts d'arrondi des nombres flottants. S'il échoue, `promtool` affiche la valeur obtenue : comparez-la à la formule.

## B. Écrire le SLO

Créez `~/slo/slo.yml` : la **description** du SLO (une source de vérité lisible, qu'on pourrait donner à des outils comme Sloth ou Pyrra) :

```bash
cat > ~/slo/slo.yml <<'EOF'
nom: disponibilite-api
service: api
objectif: 99.9
fenetre: 30d
sli:
  description: Part des requêtes HTTP qui ne se terminent pas en erreur serveur (non-5xx)
  expression: sum(increase(http_requests_total{code!~"5.."}[7d])) / sum(increase(http_requests_total[7d]))
  bons: code!~"5.."
  total: toutes les requêtes
EOF
cat ~/slo/slo.yml
```{{exec}}

## Questions

- Le SLI mesuré (99,85 %) respecte-t-il l'objectif de **99,9 %** ? (Non : 0,15 % d'erreurs contre 0,1 % autorisé.)
- Pourquoi `increase()` et pas la valeur brute de `http_requests_total` ? (C'est un **counter** cumulatif : on regarde sa variation sur la fenêtre.)

Cliquez sur **Vérifier**.
