#!/bin/bash
export AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
EP=http://localhost:4566
awsl() { aws --endpoint-url "$EP" "$@"; }
command -v aws >/dev/null 2>&1 || { echo "awscli n'est pas installé (voir l'étape de mise en place)."; exit 1; }
curl -fs --max-time 5 "$EP/_localstack/health" >/dev/null || { echo "LocalStack ne répond pas sur $EP : le conteneur tourne-t-il ? (docker ps ; docker logs localstack)"; exit 1; }

d="$HOME/iam-lab"
B=donnees-worketyamo
awsl s3api head-object --bucket "$B" --key rapport.txt >/dev/null 2>&1 || { echo "L'objet rapport.txt est absent du bucket $B (partie A)."; exit 1; }
awsl iam get-user --user-name lecteur >/dev/null 2>&1 || { echo "L'utilisateur « lecteur » n'existe pas (aws iam create-user --user-name lecteur)."; exit 1; }
arn=$(awsl iam list-attached-user-policies --user-name lecteur --query "AttachedPolicies[?PolicyName=='LectureDonnees'].PolicyArn | [0]" --output text 2>/dev/null)
if [ -z "$arn" ] || [ "$arn" = "None" ]; then echo "La policy « LectureDonnees » n'est pas attachée à l'utilisateur lecteur (aws iam attach-user-policy)."; exit 1; fi
[ -s "$d/evaluer-policy.py" ] || { echo "Le fichier $d/evaluer-policy.py est absent (partie C)."; exit 1; }
vers=$(awsl iam get-policy --policy-arn "$arn" --query Policy.DefaultVersionId --output text)
doc=$(mktemp)
awsl iam get-policy-version --policy-arn "$arn" --version-id "$vers" --query PolicyVersion.Document > "$doc" 2>/dev/null || { echo "Impossible de lire la policy dans LocalStack."; rm -f "$doc"; exit 1; }
if grep -q '"s3:\*"' "$doc" || grep -q '"Action": *"\*"' "$doc"; then echo "La policy contient un joker trop large (s3:* ou *) : appliquez le moindre privilège."; rm -f "$doc"; exit 1; fi
ev() { python3 "$d/evaluer-policy.py" "$doc" "$1" "$2" 2>&1; }
ev s3:GetObject "arn:aws:s3:::$B/rapport.txt" | grep -q '^ALLOW' || { echo "La lecture (s3:GetObject) devrait être autorisée par la policy."; rm -f "$doc"; exit 1; }
ev s3:ListBucket "arn:aws:s3:::$B" | grep -q '^ALLOW' || { echo "Le listage (s3:ListBucket sur le bucket) devrait être autorisé."; rm -f "$doc"; exit 1; }
ev s3:PutObject "arn:aws:s3:::$B/copie.txt" | grep -q '^DENY' || { echo "L'écriture (s3:PutObject) devrait être refusée par une policy de lecture seule."; rm -f "$doc"; exit 1; }
ev s3:DeleteObject "arn:aws:s3:::$B/rapport.txt" | grep -q '^DENY' || { echo "La suppression devrait être refusée."; rm -f "$doc"; exit 1; }
rm -f "$doc"
echo "OK : utilisateur lecteur, policy $arn attachée (version $vers) : lecture autorisée, écriture et suppression refusées."
exit 0
