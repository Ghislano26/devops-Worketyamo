#!/bin/bash
export AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
EP=http://localhost:4566
awsl() { aws --endpoint-url "$EP" "$@"; }
command -v aws >/dev/null 2>&1 || { echo "awscli n'est pas installé (voir l'étape de mise en place)."; exit 1; }
curl -fs --max-time 5 "$EP/_localstack/health" >/dev/null || { echo "LocalStack ne répond pas sur $EP : le conteneur tourne-t-il ? (docker ps ; docker logs localstack)"; exit 1; }

B=archives-worketyamo
awsl s3api head-bucket --bucket "$B" >/dev/null 2>&1 || { echo "Le bucket « $B » n'existe pas (aws s3 mb s3://$B)."; exit 1; }
etat=$(awsl s3api get-bucket-versioning --bucket "$B" --query Status --output text 2>/dev/null)
[ "$etat" = "Enabled" ] || { echo "Le versioning n'est pas activé sur $B (état : ${etat:-aucun}). Utilisez put-bucket-versioning ... Status=Enabled."; exit 1; }
nb=$(awsl s3api list-object-versions --bucket "$B" --prefix rapport.txt --query 'length(Versions)' --output text 2>/dev/null)
if [ "${nb:-0}" -lt 2 ]; then echo "Il faut au moins 2 versions de rapport.txt (trouvé : ${nb:-0})."; exit 1; fi
courant=$(awsl s3 cp "s3://$B/rapport.txt" - 2>/dev/null)
echo "$courant" | grep -q 'version 2' || { echo "La version courante devrait être la « version 2 » (contenu actuel : $courant)."; exit 1; }
echo "OK : versioning actif sur $B, $nb versions de rapport.txt, version courante = 2."
exit 0
