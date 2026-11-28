#!/bin/bash
export AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
EP=http://localhost:4566
awsl() { aws --endpoint-url "$EP" "$@"; }
command -v aws >/dev/null 2>&1 || { echo "awscli n'est pas installé (voir l'étape de mise en place)."; exit 1; }
curl -fs --max-time 5 "$EP/_localstack/health" >/dev/null || { echo "LocalStack ne répond pas sur $EP : le conteneur tourne-t-il ? (docker ps ; docker logs localstack)"; exit 1; }

B=mon-premier-bucket
awsl s3api list-buckets --query 'Buckets[].Name' --output text | tr '\t' '\n' | grep -qx "$B" || { echo "Le bucket « $B » n'existe pas dans LocalStack (aws s3 mb s3://$B)."; exit 1; }
awsl s3api head-object --bucket "$B" --key bonjour.txt >/dev/null 2>&1 || { echo "L'objet « bonjour.txt » est absent du bucket $B (aws s3 cp bonjour.txt s3://$B/bonjour.txt)."; exit 1; }
contenu=$(awsl s3 cp "s3://$B/bonjour.txt" - 2>/dev/null)
echo "$contenu" | grep -q 'LocalStack' || { echo "Le contenu de l'objet n'est pas celui attendu (« Bonjour depuis LocalStack »)."; exit 1; }
echo "OK : bucket $B créé, objet bonjour.txt présent et lisible (état vérifié dans LocalStack)."
exit 0
