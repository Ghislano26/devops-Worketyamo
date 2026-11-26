#!/bin/bash
promtool_docker() { docker run --rm --entrypoint promtool -v "$HOME/slo:/slo" -w /slo prom/prometheus:v3.5.0 "$@"; }

cd "$HOME/slo" 2>/dev/null || { echo "Le dossier ~/slo n'existe pas."; exit 1; }
[ -s slo.rules.yml ] || { echo "slo.rules.yml est absent ou vide."; exit 1; }
grep -q 'slo:error_budget_remaining:ratio_30d' slo.rules.yml || { echo "La règle « slo:error_budget_remaining:ratio_30d » est absente de slo.rules.yml."; exit 1; }
if ! sortie=$(promtool_docker check rules slo.rules.yml 2>&1); then echo "promtool check rules a échoué : $sortie"; exit 1; fi
if ! sortie=$(promtool_docker test rules test-budget-30j.yml 2>&1); then
  echo "Le test du budget restant échoue (valeur attendue : 0.5) :"
  echo "$sortie" | head -n 15
  exit 1
fi
p=politique-release.yml
[ -s "$p" ] || { echo "Le fichier ~/slo/$p est absent ou vide."; exit 1; }
grep -qE 'budget_restant_pct: *50(\.0)? *$' "$p" || { echo "$p : « budget_restant_pct » doit valoir 50."; exit 1; }
grep -qE 'budget_restant_minutes: *21\.6 *$' "$p" || { echo "$p : « budget_restant_minutes » doit valoir 21.6 (43,2 min × 50 %)."; exit 1; }
grep -qE 'budget_restant *> *0' "$p" || { echo "$p : la règle de décision doit comparer « budget_restant > 0 »."; exit 1; }
grep -q 'release_autorisee' "$p" || { echo "$p : la décision « release_autorisee » est absente."; exit 1; }
grep -q 'gel' "$p" || { echo "$p : la décision de gel des releases est absente."; exit 1; }
echo "OK : budget restant 50 % (21,6 min) et politique de release écrite."
exit 0
