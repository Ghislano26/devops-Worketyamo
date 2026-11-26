# Étape 2 : budget d'erreur sur 30 jours et politique de release

Le **budget d'erreur** est `100 % − SLO` (voir le [cours 02](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/02-slo-sli-error-budget.md)). Pour un SLO de **99,9 % sur 30 jours** : 0,1 % de requêtes en échec, soit **43,2 minutes** d'indisponibilité totale (`43 200 min × 0,001`).

Nouvelle fenêtre de données (`~/slo/test-budget-30j.yml`) : **30 jours** (720 h), 10 000 requêtes/heure, dont **5 en erreur** (99,95 % de réussite).

## A. Règle du budget restant

Ajoutez à `~/slo/slo.rules.yml` (dans le même groupe) la règle **`slo:error_budget_remaining:ratio_30d`** :

```text
budget restant = 1 − (taux d'erreur sur 30 jours / budget autorisé)
               = 1 − ( erreurs / total ) / (1 − 0,999)
```

```bash
cat > ~/slo/slo.rules.yml <<'EOF'
groups:
  - name: slo-disponibilite
    rules:
      - record: slo:sli_availability:ratio_7d
        expr: sum(increase(http_requests_total{code!~"5.."}[7d])) / sum(increase(http_requests_total[7d]))
      - record: slo:error_budget_remaining:ratio_30d
        expr: 1 - (sum(increase(http_requests_total{code=~"5.."}[30d])) / sum(increase(http_requests_total[30d]))) / (1 - 0.999)
EOF
promtool_docker() { docker run --rm --entrypoint promtool -v "$HOME/slo:/slo" -w /slo prom/prometheus:v3.5.0 "$@"; }
promtool_docker check rules slo.rules.yml
promtool_docker test rules test-sli-7j.yml
promtool_docker test rules test-budget-30j.yml
```{{exec}}

Le test attend **0,5** : il reste **50 %** du budget.

## B. Traduire en minutes et décider

1. Budget total : **43,2 min** ; consommé : 50 % ; **restant : 21,6 min**.
2. Écrivez la **politique de budget d'erreur** dans `~/slo/politique-release.yml` : releases autorisées tant que le budget restant est **> 0**, **gel** sinon.

```bash
cat > ~/slo/politique-release.yml <<'EOF'
politique_budget:
  slo: 99.9
  fenetre: 30d
  budget_restant_pct: 50
  budget_restant_minutes: 21.6
  decision:
    si: "budget_restant > 0"
    alors: release_autorisee
    sinon: gel_des_releases
  exceptions: correctifs de securite et de fiabilite
EOF
cat ~/slo/politique-release.yml
```{{exec}}

## Questions

- Avec les données de l'étape 1 (99,85 %, soit **150 %** du budget consommé), quelle serait la décision ? (**Gel** : budget épuisé, SLO violé.)
- Pourquoi une politique **écrite et acceptée d'avance** ? (Pour décider sur un fait, sans débat subjectif « on livre ou pas ? ».)

Cliquez sur **Vérifier**.
