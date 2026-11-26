#!/bin/bash
promtool_docker() { docker run --rm --entrypoint promtool -v "$HOME/slo:/slo" -w /slo prom/prometheus:v3.5.0 "$@"; }

cd "$HOME/slo" 2>/dev/null || { echo "Le dossier ~/slo n'existe pas (voir l'introduction)."; exit 1; }
[ -s slo.rules.yml ] || { echo "Le fichier ~/slo/slo.rules.yml est absent ou vide."; exit 1; }
[ -s slo.yml ] || { echo "Le fichier ~/slo/slo.yml est absent ou vide."; exit 1; }
for champ in '^nom:' '^service:' '^objectif:' '^fenetre:' '^sli:' '^ +expression:'; do
  grep -qE "$champ" slo.yml || { echo "slo.yml : champ manquant (${champ#^}) — voir le modèle de l'énoncé."; exit 1; }
done
grep -qE '^objectif: *99\.9 *$' slo.yml || { echo "slo.yml : « objectif » doit valoir 99.9."; exit 1; }
grep -qE '^fenetre: *30d *$' slo.yml || { echo "slo.yml : « fenetre » doit valoir 30d."; exit 1; }
grep -q 'http_requests_total' slo.yml || { echo "slo.yml : l'expression du SLI doit utiliser http_requests_total."; exit 1; }
if ! command -v docker >/dev/null 2>&1; then echo "docker est introuvable."; exit 1; fi
if ! sortie=$(promtool_docker check rules slo.rules.yml 2>&1); then
  echo "promtool check rules a échoué : $sortie"
  exit 1
fi
if ! grep -q 'slo:sli_availability:ratio_7d' slo.rules.yml; then
  echo "La règle d'enregistrement « slo:sli_availability:ratio_7d » est absente de slo.rules.yml."
  exit 1
fi
if ! sortie=$(promtool_docker test rules test-sli-7j.yml 2>&1); then
  echo "Le test sur les séries simulées échoue (SLI attendu : 0.9985) :"
  echo "$sortie" | head -n 15
  exit 1
fi
echo "OK : règle valide, SLI de 99,85 % retrouvé sur les séries simulées, SLO documenté dans slo.yml."
exit 0
