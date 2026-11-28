#!/bin/bash
export AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
EP=http://localhost:4566
awsl() { aws --endpoint-url "$EP" "$@"; }
command -v aws >/dev/null 2>&1 || { echo "awscli n'est pas installé (voir l'étape de mise en place)."; exit 1; }
curl -fs --max-time 5 "$EP/_localstack/health" >/dev/null || { echo "LocalStack ne répond pas sur $EP : le conteneur tourne-t-il ? (docker ps ; docker logs localstack)"; exit 1; }

docker ps --filter name='^/localstack$' --filter status=running -q | grep -q . || { echo "Le conteneur « localstack » n'est pas démarré (docker run -d --name localstack …)."; exit 1; }
[ "$(aws configure get endpoint_url)" = "$EP" ] || { echo "endpoint_url n'est pas configuré : lancez « aws configure set endpoint_url http://localhost:4566 »."; exit 1; }
compte=$(awsl sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "« aws sts get-caller-identity » échoue : LocalStack est-il prêt ?"; exit 1; }
[ "$compte" = "000000000000" ] || { echo "Le compte renvoyé n'est pas celui de LocalStack (000000000000) : $compte"; exit 1; }
echo "OK : LocalStack répond (compte fictif $compte) et awscli est configuré pour l'utiliser."
exit 0
