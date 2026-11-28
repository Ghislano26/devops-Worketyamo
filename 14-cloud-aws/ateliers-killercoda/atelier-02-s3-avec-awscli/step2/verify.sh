#!/bin/bash
export AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
EP=http://localhost:4566
awsl() { aws --endpoint-url "$EP" "$@"; }
command -v aws >/dev/null 2>&1 || { echo "awscli n'est pas installé (voir l'étape de mise en place)."; exit 1; }
curl -fs --max-time 5 "$EP/_localstack/health" >/dev/null || { echo "LocalStack ne répond pas sur $EP : le conteneur tourne-t-il ? (docker ps ; docker logs localstack)"; exit 1; }

B=archives-worketyamo
awsl s3api head-bucket --bucket "$B" >/dev/null 2>&1 || { echo "Le bucket « $B » n'existe pas : refaites l'étape 1."; exit 1; }
courant=$(awsl s3 cp "s3://$B/rapport.txt" - 2>/dev/null) || { echo "L'objet rapport.txt est introuvable : un marqueur de suppression est peut-être encore actif (partie B)."; exit 1; }
echo "$courant" | grep -q 'version 1' || { echo "La version courante doit contenir « version 1 » (restauration) ; contenu actuel : $courant"; exit 1; }
nb=$(awsl s3api list-object-versions --bucket "$B" --prefix rapport.txt --query 'length(Versions)' --output text 2>/dev/null)
if [ "${nb:-0}" -lt 3 ]; then echo "Il faut au moins 3 versions (v1, v2 et la restauration) : trouvé ${nb:-0}."; exit 1; fi
marqueur=$(awsl s3api list-object-versions --bucket "$B" --prefix rapport.txt --query 'DeleteMarkers[?IsLatest].VersionId | [0]' --output text 2>/dev/null)
if [ -n "$marqueur" ] && [ "$marqueur" != "None" ]; then echo "Un marqueur de suppression est encore actif ($marqueur) : retirez-le avec delete-object --version-id."; exit 1; fi
echo "OK : version 1 restaurée comme version courante ($nb versions conservées, aucun marqueur de suppression actif)."
exit 0
