# Étape 1 : un scan de vulnérabilités avec rapport JSON

L'image **`alpine:3.10`** est ancienne (fin de vie) : elle contient des vulnérabilités connues, idéale pour s'entraîner ([cours 6](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/06-securite-dans-la-ci.md)).

## A. Rapport complet au format JSON

```bash
mkdir -p ~/sec && cd ~/sec
trivy image --format json --output ~/sec/rapport-trivy.json alpine:3.10
ls -lh ~/sec/rapport-trivy.json
```{{exec}}

Le premier lancement télécharge la base de vulnérabilités (une à deux minutes). Lisez la synthèse du rapport :

```bash
python3 - <<'EOF'
import json, collections, os
rapport = json.load(open(os.path.expanduser("~/sec/rapport-trivy.json")))
compte = collections.Counter(v["Severity"] for r in rapport.get("Results", []) for v in r.get("Vulnerabilities") or [])
print(dict(compte))
EOF
```{{exec}}

## B. Un seuil bloquant (*gate*)

En CI, on **échoue** quand une faille de sévérité haute ou critique est présente (`--exit-code 1`). Lancez le contrôle et enregistrez le code de retour :

```bash
trivy image --severity HIGH,CRITICAL --exit-code 1 --quiet alpine:3.10 >/dev/null; echo "code=$?" | tee ~/sec/gate.txt
```{{exec}}

`code=1` signifie « pipeline bloquée » : une image avec ces failles n'irait pas plus loin.

## Questions

- Pourquoi corriger en **mettant à jour l'image de base** plutôt qu'en ignorant les alertes ? (La plupart des failles viennent de paquets du système de base.)
- À quoi sert `--ignore-unfixed` ? (Masquer les failles sans correctif disponible : du bruit non actionnable.)

Cliquez sur **Vérifier**.
