#!/bin/bash
export AWS_PAGER="" AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-west-3
EP=http://localhost:4566
awsl() { aws --endpoint-url "$EP" "$@"; }
command -v aws >/dev/null 2>&1 || { echo "awscli n'est pas installé (voir l'étape de mise en place)."; exit 1; }
curl -fs --max-time 5 "$EP/_localstack/health" >/dev/null || { echo "LocalStack ne répond pas sur $EP : le conteneur tourne-t-il ? (docker ps ; docker logs localstack)"; exit 1; }

d="$HOME/iam-lab"
B=donnees-worketyamo
[ -s "$d/evaluer-policy.py" ] || { echo "Le fichier $d/evaluer-policy.py est absent : refaites l'étape 1."; exit 1; }
arn=$(awsl iam list-attached-user-policies --user-name lecteur --query "AttachedPolicies[?PolicyName=='LectureDonnees'].PolicyArn | [0]" --output text 2>/dev/null)
if [ -z "$arn" ] || [ "$arn" = "None" ]; then echo "La policy LectureDonnees n'est plus attachée à lecteur."; exit 1; fi
cle=$(aws configure get aws_access_key_id --profile lecteur 2>/dev/null)
[ -n "$cle" ] || { echo "Le profil « lecteur » n'est pas configuré (partie A : aws configure set … --profile lecteur)."; exit 1; }
awsl iam list-access-keys --user-name lecteur --query 'AccessKeyMetadata[].AccessKeyId' --output text | tr '\t' '\n' | grep -qx "$cle" || { echo "La clé du profil lecteur ne correspond à aucune clé de l'utilisateur dans LocalStack."; exit 1; }
nv=$(awsl iam list-policy-versions --policy-arn "$arn" --query 'length(Versions)' --output text)
if [ "${nv:-0}" -lt 2 ]; then echo "La policy n'a qu'une version : créez la v2 (aws iam create-policy-version ... --set-as-default)."; exit 1; fi
vers=$(awsl iam get-policy --policy-arn "$arn" --query Policy.DefaultVersionId --output text)
[ "$vers" != "v1" ] || { echo "La version par défaut est encore v1 : utilisez --set-as-default."; exit 1; }
doc=$(mktemp)
awsl iam get-policy-version --policy-arn "$arn" --version-id "$vers" --query PolicyVersion.Document > "$doc" 2>/dev/null || { echo "Impossible de lire la version par défaut de la policy."; rm -f "$doc"; exit 1; }
if grep -q '"s3:\*"' "$doc" || grep -q '"Action": *"\*"' "$doc"; then echo "La policy contient un joker trop large (s3:* ou *)."; rm -f "$doc"; exit 1; fi
ev() { python3 "$d/evaluer-policy.py" "$doc" "$1" "$2" 2>&1; }
ev s3:PutObject "arn:aws:s3:::$B/uploads/ok.txt" | grep -q '^ALLOW' || { echo "L'écriture dans uploads/ devrait être autorisée par la nouvelle version."; rm -f "$doc"; exit 1; }
ev s3:PutObject "arn:aws:s3:::$B/ecriture.txt" | grep -q '^DENY' || { echo "L'écriture HORS de uploads/ doit rester refusée (moindre privilège)."; rm -f "$doc"; exit 1; }
ev s3:DeleteObject "arn:aws:s3:::$B/uploads/ok.txt" | grep -q '^DENY' || { echo "La suppression doit rester refusée."; rm -f "$doc"; exit 1; }
ev s3:GetObject "arn:aws:s3:::$B/rapport.txt" | grep -q '^ALLOW' || { echo "La lecture doit rester autorisée."; rm -f "$doc"; exit 1; }
rm -f "$doc"
echo "OK : policy corrigée (version $vers, $nv versions) : écriture limitée à uploads/, lecture conservée, suppression refusée."
exit 0
