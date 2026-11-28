#!/bin/bash
export AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
EP=http://localhost:4566
awsl() { aws --endpoint-url "$EP" "$@"; }
command -v aws >/dev/null 2>&1 || { echo "awscli n'est pas installé (voir l'étape de mise en place)."; exit 1; }
curl -fs --max-time 5 "$EP/_localstack/health" >/dev/null || { echo "LocalStack ne répond pas sur $EP : le conteneur tourne-t-il ? (docker ps ; docker logs localstack)"; exit 1; }

B=archives-worketyamo
ids=$(awsl s3api get-bucket-lifecycle-configuration --bucket "$B" --query 'Rules[].ID' --output text 2>/dev/null) || { echo "Aucune configuration de cycle de vie sur $B : lancez put-bucket-lifecycle-configuration."; exit 1; }
for r in expirer-tmp archiver-logs purger-anciennes-versions; do
  echo "$ids" | tr '\t' '\n' | grep -qx "$r" || { echo "La règle « $r » est absente de la configuration (règles trouvées : $ids)."; exit 1; }
done
jours=$(awsl s3api get-bucket-lifecycle-configuration --bucket "$B" --query "Rules[?ID=='expirer-tmp'].Expiration.Days | [0]" --output text 2>/dev/null)
[ "$jours" = "7" ] || { echo "La règle expirer-tmp doit expirer après 7 jours (trouvé : $jours)."; exit 1; }
classes=$(awsl s3api get-bucket-lifecycle-configuration --bucket "$B" --query "Rules[?ID=='archiver-logs'].Transitions[].StorageClass" --output text 2>/dev/null)
for c in STANDARD_IA GLACIER; do
  echo "$classes" | tr '\t' '\n' | grep -qx "$c" || { echo "La règle archiver-logs doit contenir une transition vers $c (trouvé : $classes)."; exit 1; }
done
nc=$(awsl s3api get-bucket-lifecycle-configuration --bucket "$B" --query "Rules[?ID=='purger-anciennes-versions'].NoncurrentVersionExpiration.NoncurrentDays | [0]" --output text 2>/dev/null)
[ "$nc" = "30" ] || { echo "La règle purger-anciennes-versions doit purger après 30 jours (trouvé : $nc)."; exit 1; }
echo "OK : 3 règles de cycle de vie enregistrées sur $B (expiration 7 j, transitions IA puis Glacier, purge des anciennes versions à 30 j)."
exit 0
