# Étape 1 : un utilisateur en lecture seule

## A. Préparer le bucket

```bash
mkdir -p ~/iam-lab && cd ~/iam-lab
aws s3 mb s3://donnees-worketyamo
echo "rapport confidentiel" > rapport.txt
aws s3 cp rapport.txt s3://donnees-worketyamo/rapport.txt
```{{exec}}

## B. Créer l'utilisateur et sa policy

Un nouvel utilisateur n'a **aucun droit**. On crée un utilisateur `lecteur` et une **policy gérée** qui l'autorise à **lister** le bucket et **lire** ses objets (et rien d'autre). Notez les **deux ARN** : le bucket (`ListBucket`) et ses objets (`/*`, `GetObject`).

```bash
cd ~/iam-lab
cat > politique-lecture.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListerLeBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::donnees-worketyamo"
    },
    {
      "Sid": "LireLesObjets",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::donnees-worketyamo/*"
    }
  ]
}
EOF
aws iam create-user --user-name lecteur
POLICY_ARN=$(aws iam create-policy --policy-name LectureDonnees --policy-document file://politique-lecture.json --query Policy.Arn --output text)
echo "$POLICY_ARN" | tee policy.arn
aws iam attach-user-policy --user-name lecteur --policy-arn "$POLICY_ARN"
aws iam list-attached-user-policies --user-name lecteur
aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id v1 --query PolicyVersion.Document
```{{exec}}

## C. Écrire l'évaluateur de policy

LocalStack n'appliquera pas la policy : vous allez donc **la tester vous-même**.

```bash
cd ~/iam-lab
cat > evaluer-policy.py <<'EOF'
#!/usr/bin/env python3
"""Évaluateur minimal de policy IAM : ALLOW / DENY pour (action, ressource).
Usage : evaluer-policy.py <policy.json | -> <action> <arn-ressource>
Règles : refus par défaut, un Deny explicite l'emporte, sinon il faut un Allow.
Non géré (volontairement) : Condition, NotAction, NotResource, Principal."""
import fnmatch, json, sys


def liste(x):
    return x if isinstance(x, list) else [x]


def evaluer(doc, action, ressource):
    autorise = False
    for st in liste(doc["Statement"]):
        if any(k in st for k in ("Condition", "NotAction", "NotResource")):
            sys.exit("Non supporté par cet évaluateur : Condition / NotAction / NotResource")
        if not any(fnmatch.fnmatchcase(action.lower(), a.lower()) for a in liste(st["Action"])):
            continue
        if not any(fnmatch.fnmatchcase(ressource, r) for r in liste(st["Resource"])):
            continue
        if st["Effect"] == "Deny":
            return "DENY (refus explicite : %s)" % st.get("Sid", "sans Sid")
        autorise = True
    return "ALLOW" if autorise else "DENY (refus implicite : aucun Allow ne correspond)"


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    source = sys.stdin if sys.argv[1] == "-" else open(sys.argv[1], encoding="utf-8")
    resultat = evaluer(json.load(source), sys.argv[2], sys.argv[3])
    print(resultat)
    sys.exit(0 if resultat == "ALLOW" else 1)

EOF
chmod +x evaluer-policy.py
```{{exec}}

Interrogez-le avec la policy **réellement enregistrée dans LocalStack** (récupérée avec `awscli`, pas votre fichier local) :

```bash
cd ~/iam-lab
ARN=$(cat policy.arn)
aws iam get-policy-version --policy-arn "$ARN" --version-id v1 --query PolicyVersion.Document > actuelle.json
./evaluer-policy.py actuelle.json s3:GetObject arn:aws:s3:::donnees-worketyamo/rapport.txt   # ALLOW
./evaluer-policy.py actuelle.json s3:ListBucket arn:aws:s3:::donnees-worketyamo               # ALLOW
./evaluer-policy.py actuelle.json s3:PutObject arn:aws:s3:::donnees-worketyamo/copie.txt      # DENY
./evaluer-policy.py actuelle.json s3:DeleteObject arn:aws:s3:::donnees-worketyamo/rapport.txt # DENY
```{{exec}}

La lecture est **autorisée**, l'écriture et la suppression sont **refusées** (refus **implicite** : aucune règle ne les autorise).

## Questions

- Pourquoi deux ARN différents (`…:::donnees-worketyamo` et `…:::donnees-worketyamo/*`) ? *(`ListBucket` porte sur le **bucket**, `GetObject` sur les **objets**.)*
- Pourquoi n'y a-t-il aucun `Deny` dans la policy et pourtant `PutObject` est refusé ? *(Refus **implicite** : tout ce qui n'est pas autorisé est refusé.)*

Cliquez sur **Vérifier**.
