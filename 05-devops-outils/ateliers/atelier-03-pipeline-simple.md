# Atelier 03 — Un pipeline CI/CD simple

## 🎯 Objectifs

- Écrire des tests automatisés pour un script Bash et une API.
- Construire un pipeline local (script) qui enchaîne qualité → tests → build → déploiement.
- Décrire le même pipeline en **GitHub Actions** (YAML) et le faire tourner en local avec `act` (facultatif) ou sur GitHub.
- Mettre en place un déploiement avec **vérification de santé** et **retour arrière**.

## 📋 Prérequis

- Ateliers [01 — Git](atelier-01-git-branches.md) et [02 — Docker](atelier-02-premier-dockerfile.md) terminés (l'API `kamer/api` et son `Dockerfile`).
- Cours lu : [Principes du CI/CD](../cours/03-ci-cd-principes.md).
- Paquets : `sudo apt install -y shellcheck curl`.
- *(Facultatif)* un compte GitHub et une clé SSH configurée.

## 🧪 Scénario

L'équipe de *Kamer Logistics* livre manuellement l'API de suivi de colis, et la dernière mise en production a
cassé le site pendant 40 minutes (une erreur de syntaxe jamais testée). Votre mission : construire un
**pipeline automatique** qui refuse tout changement défectueux et déploie les changements valides avec possibilité de retour arrière.

## Étapes

### Étape 1 — Préparer le dépôt du projet

```bash
mkdir -p ~/atelier-cicd && cd ~/atelier-cicd
git init -q
mkdir -p api scripts tests .github/workflows
cp ~/atelier-docker/api/app.py api/ 2>/dev/null || echo "Recopiez app.py de l'atelier précédent dans api/"
cp ~/atelier-docker/api/Dockerfile api/ 2>/dev/null
ls api
```

> 💡 **Conseil** : si les fichiers de l'atelier 02 n'existent plus, recréez-les rapidement depuis cet atelier (voir l'étape 2 pour `app.py`).

Si besoin, écrivez une version minimale de l'API :

```bash
[ -f api/app.py ] || cat > api/app.py <<'EOF'
import json, os
from http.server import BaseHTTPRequestHandler, HTTPServer
PORT = int(os.environ.get("PORT", "8000"))
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        corps = {"statut": "ok"} if self.path == "/sante" else {"colis": "KL-1042", "statut": "en transit"}
        data = json.dumps(corps).encode()
        self.send_response(200); self.send_header("Content-Type", "application/json"); self.end_headers()
        self.wfile.write(data + b"\n")
if __name__ == "__main__":
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
EOF
[ -f api/Dockerfile ] || cat > api/Dockerfile <<'EOF'
FROM python:3.12-slim
RUN useradd --system --uid 10001 --no-create-home appuser
WORKDIR /app
COPY app.py .
ENV PORT=8000
EXPOSE 8000
USER appuser
CMD ["python", "app.py"]
EOF
```

### Étape 2 — Un script à contrôler et des tests

Un script d'exploitation à vérifier :

```bash
cat > scripts/sante.sh <<'EOF'
#!/usr/bin/env bash
# Affiche un état de santé simple. Code retour : 0 si le disque < seuil, 1 sinon.
set -euo pipefail
SEUIL="${1:-90}"
utilise=$(df --output=pcent / | tail -1 | tr -dc '0-9')
echo "Disque / : ${utilise} %"
(( utilise < SEUIL ))
EOF
chmod +x scripts/sante.sh
```

Le **script de tests** :

```bash
cat > tests/tests.sh <<'EOF'
#!/usr/bin/env bash
# Tests élémentaires — chaque test affiche OK/KO ; le script échoue si un test échoue.
set -uo pipefail
cd "$(dirname "$0")/.."
echec=0

verifie() {                 # verifie "description" commande...
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "  OK  $desc"; else echo "  KO  $desc"; echec=1; fi
}

echo "== Tests du script sante.sh =="
verifie "retourne 0 avec un seuil de 100 %"     ./scripts/sante.sh 100
verifie "retourne 1 avec un seuil de 0 %"       bash -c '! ./scripts/sante.sh 0'
verifie "affiche une ligne « Disque »"          bash -c './scripts/sante.sh 100 | grep -q "^Disque"'

echo "== Tests de l'API =="
PORT=18000
PORT=$PORT python3 api/app.py &
PID=$!
trap 'kill $PID 2>/dev/null' EXIT
for _ in $(seq 1 20); do curl -s "localhost:$PORT/sante" >/dev/null && break; sleep 0.3; done
verifie "GET /sante renvoie statut ok"  bash -c "curl -s localhost:$PORT/sante | grep -q '\"statut\": \"ok\"'"
verifie "GET / renvoie du JSON"      bash -c "curl -s localhost:$PORT/ | python3 -m json.tool"
verifie "GET / contient 'colis'"     bash -c "curl -s localhost:$PORT/ | grep -q colis"

exit $echec
EOF
chmod +x tests/tests.sh
./tests/tests.sh ; echo "code retour = $?"
```

> ❓ **Question 1** : Pourquoi un script de test doit-il renvoyer un **code de retour** non nul en cas d'échec ? Qui consomme ce code ?

### Étape 3 — Le pipeline local

```bash
cat > scripts/pipeline.sh <<'EOF'
#!/usr/bin/env bash
#
# pipeline.sh — pipeline CI/CD local : qualité → tests → build → déploiement → vérification
# Usage : scripts/pipeline.sh
#
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE="kamer/api"
VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
NOM="api-prod"
PORT_PROD=8000

etape() { printf '\n\033[1;34m=== ÉTAPE : %s ===\033[0m\n' "$1"; }
echec() { printf '\033[1;31m✘ ÉCHEC : %s\033[0m\n' "$1" >&2; exit 1; }

etape "1/5 Qualité (shellcheck + syntaxe Python)"
shellcheck scripts/*.sh tests/*.sh || echec "shellcheck"
python3 -m py_compile api/app.py || echec "syntaxe Python"

etape "2/5 Tests"
if [[ "${SANS_TESTS:-0}" == 1 ]]; then
    echo "(tests ignorés : SANS_TESTS=1, démonstration uniquement)"
else
    ./tests/tests.sh || echec "tests"
fi

etape "3/5 Construction de l'image ${IMAGE}:${VERSION}"
docker build -q -t "${IMAGE}:${VERSION}" api/ || echec "build"

etape "4/5 Déploiement"
ANCIENNE="$(docker inspect -f '{{.Config.Image}}' "$NOM" 2>/dev/null || true)"
docker rm -f "$NOM" >/dev/null 2>&1 || true
docker run -d --name "$NOM" -p "${PORT_PROD}:8000" --restart unless-stopped "${IMAGE}:${VERSION}" >/dev/null

etape "5/5 Vérification de santé"
ok=0
for _ in $(seq 1 15); do
    if curl -fs "localhost:${PORT_PROD}/sante" >/dev/null; then ok=1; break; fi
    sleep 1
done
if [[ $ok -eq 1 ]]; then
    printf '\033[1;32m✔ Déployé : %s:%s\033[0m\n' "$IMAGE" "$VERSION"
else
    echo "La nouvelle version ne répond pas : RETOUR ARRIÈRE" >&2
    docker rm -f "$NOM" >/dev/null 2>&1 || true
    if [[ -n "$ANCIENNE" ]]; then
        docker run -d --name "$NOM" -p "${PORT_PROD}:8000" "$ANCIENNE" >/dev/null
        echo "Version précédente rétablie : $ANCIENNE" >&2
    fi
    exit 1
fi
EOF
chmod +x scripts/pipeline.sh
shellcheck scripts/*.sh tests/*.sh && echo "shellcheck OK"
git add . && git commit -qm "Initialise le projet et le pipeline local" && git log --oneline
```

> ❓ **Question 2** : Pourquoi taguer l'image avec le hash court du commit plutôt que `latest` ? Que gagne-t-on pour le retour arrière ?

### Étape 4 — Première exécution (cas nominal)

```bash
./scripts/pipeline.sh
curl -s localhost:8000
docker ps --filter name=api-prod
```

### Étape 5 — Le pipeline doit **refuser** un mauvais changement

Introduisez volontairement une erreur de syntaxe :

```bash
echo 'if then fi' >> scripts/sante.sh
git commit -qam "Change cassé (volontaire)"
./scripts/pipeline.sh ; echo "code retour = $?"
curl -s localhost:8000               # l'ancienne version tourne toujours !
```

> ❓ **Question 3** : À quelle étape le pipeline s'est-il arrêté ? La production a-t-elle été affectée ? Qu'aurait-on eu sans pipeline ?

Corrigez :

```bash
git revert --no-edit HEAD
./scripts/pipeline.sh
```

### Étape 6 — Un test qui échoue

Cassez le **comportement** (pas la syntaxe) :

```bash
sed -i 's#"/sante"#"/health"#' api/app.py
git commit -qam "Renomme la route de santé (régression)"
./scripts/pipeline.sh ; echo "code retour = $?"
```

Les tests détectent la régression. Annulez :

```bash
git revert --no-edit HEAD
```

> ❓ **Question 4** : Quel test a échoué ? En quoi les tests automatiques protègent-ils contre des erreurs qu'une relecture humaine laisserait passer ?

### Étape 7 — Simuler un retour arrière au déploiement

On fait échouer **uniquement** la vérification de santé de la nouvelle version (l'application démarre mais plante) :

```bash
# Version précédente saine déjà en production
./scripts/pipeline.sh
# Nouvelle version qui démarre puis plante après le lancement
sed -i 's#HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()#import sys; sys.exit(1)#' api/app.py
git commit -qam "Version qui plante au démarrage"
SANS_TESTS=1 ./scripts/pipeline.sh || true
curl -s localhost:8000                   # la version précédente a été rétablie
git revert --no-edit HEAD
```

> ❓ **Question 5** : Quelles étapes du pipeline ont détecté le problème (test, vérification de santé) ? Comment le pipeline limite-t-il l'indisponibilité ?
> *(Cette expérience contourne volontairement les tests pour montrer le dernier filet de sécurité : la vérification de santé et le *rollback*.)*

### Étape 8 — Le même pipeline en GitHub Actions

```bash
cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  qualite-et-tests:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - name: Installer shellcheck
        run: sudo apt-get update -qq && sudo apt-get install -y -qq shellcheck

      - name: Qualité
        run: |
          shellcheck scripts/*.sh tests/*.sh
          python3 -m py_compile api/app.py

      - name: Tests
        run: ./tests/tests.sh

  image:
    needs: qualite-et-tests
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - name: Construire l'image
        run: docker build -t kamer/api:${{ github.sha }} api/
      - name: Vérifier que le conteneur démarre et est sain
        run: |
          docker run -d --name test -p 8000:8000 kamer/api:${{ github.sha }}
          for i in $(seq 1 15); do curl -fs localhost:8000/sante && exit 0; sleep 1; done
          docker logs test
          exit 1
EOF
git add .github && git commit -qm "Ajoute le workflow GitHub Actions"
```

> ❓ **Question 6** : Relevez les correspondances entre `pipeline.sh` (étapes 1 à 3) et les `jobs`/`steps` du YAML. Pourquoi le job `image` utilise-t-il `needs:` ?

#### Option A — Sur GitHub

```bash
git remote add origin git@github.com:<votre-compte>/atelier-cicd.git
git branch -M main
git push -u origin main
```

Onglet **Actions** du dépôt : observez le workflow. Provoquez ensuite un échec (étape 5) via une *pull request* et constatez que la fusion est bloquée si vous avez protégé `main`.

#### Option B — En local avec `act` (facultatif)

```bash
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash   # vérifiez le script avant d'exécuter !
act -j qualite-et-tests
```

> ⚠️ **Attention** : n'exécutez pas un script téléchargé (`curl … | sudo bash`) sans l'avoir lu au préalable. C'est un classique vecteur d'attaque. Téléchargez d'abord, lisez, puis exécutez.

### Étape 9 — Déclencher le pipeline automatiquement en local (hook Git)

```bash
cat > .git/hooks/pre-push <<'EOF'
#!/usr/bin/env bash
echo "Hook pre-push : lancement des tests…"
./tests/tests.sh
EOF
chmod +x .git/hooks/pre-push
git commit --allow-empty -qm "Test du hook"
# git push → les tests se lancent avant toute publication
```

> ❓ **Question 7** : Quelle différence entre un hook local et un pipeline serveur ? Pourquoi ne peut-on pas se contenter des hooks ?

### Étape 10 — Nettoyage

```bash
docker rm -f api-prod test 2>/dev/null
docker images "kamer/api" -q | xargs -r docker rmi -f
```

## ✅ Validation

- [ ] `./tests/tests.sh` affiche uniquement des `OK` sur le code sain.
- [ ] `./scripts/pipeline.sh` déploie `api-prod` et `curl localhost:8000/sante` répond.
- [ ] L'erreur de syntaxe volontaire a été arrêtée à l'étape **Qualité**, sans toucher à la production.
- [ ] La régression de route a été arrêtée à l'étape **Tests**.
- [ ] Le scénario de retour arrière a rétabli la version précédente.
- [ ] `.github/workflows/ci.yml` est valide (relu, ou exécuté sur GitHub / avec `act`).
- [ ] Vous savez expliquer CI, livraison continue et déploiement continu.

## 💡 Pour aller plus loin

- **Défi 1** : ajoutez une étape d'analyse de sécurité : `shellcheck` strict, `gitleaks` ou Trivy sur l'image.
- **Défi 2** : implémentez une stratégie **blue/green** en lançant `api-bleu` (8001) et `api-vert` (8002) derrière un `nginx` qui bascule.
- **Défi 3** : publiez l'image sur **GitHub Container Registry** depuis le workflow, taguée avec `github.sha`, et protégez `main` (revue + CI obligatoires).
- **Défi 4** : ajoutez un job de déploiement SSH vers votre VM, avec la clé stockée dans `secrets.SSH_KEY` et un environnement `production` nécessitant une approbation manuelle.

Félicitations : vous avez parcouru le cursus de la console Linux au pipeline CI/CD. Retour à la [vue d'ensemble](../../README.md) et aux [ressources](../../ressources/liens-utiles.md).
