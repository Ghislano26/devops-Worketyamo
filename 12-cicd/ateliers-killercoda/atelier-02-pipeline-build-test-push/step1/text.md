# Étape 1 : le registry, l'application et ses tests

Une CI mince appelle des **commandes simples** (`make test`, `make build`, `make push`) que vous pouvez aussi lancer en local ([cours 3, « garder la CI mince »](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/03-gitlab-ci-et-alternatives.md)). Préparez les trois éléments.

## A. Un registry local

```bash
docker run -d --name registry -p 5000:5000 --restart=always registry:2
curl -s http://localhost:5000/v2/
```{{exec}}

La réponse `{}` confirme que l'API du registre répond ([cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/04-build-artefacts-et-registries.md)).

## B. L'application et ses tests

```bash
cd ~/cicd-app
cat > app.py <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer


def salutation(nom="monde"):
    return f"Bonjour {nom} !"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        corps = salutation().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(corps)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
EOF
cat > test_app.py <<'EOF'
import unittest

from app import salutation


class TestSalutation(unittest.TestCase):
    def test_defaut(self):
        self.assertEqual(salutation(), "Bonjour monde !")

    def test_avec_nom(self):
        self.assertEqual(salutation("Awa"), "Bonjour Awa !")


if __name__ == "__main__":
    unittest.main()
EOF
python3 -m unittest -v
```{{exec}}

## C. Le Makefile (le « pipeline » exécutable)

Les recettes de `make` commencent normalement par une tabulation, fragile en copier-coller ; la ligne `.RECIPEPREFIX = >` les remplace par `>` :

```bash
cd ~/cicd-app
cat > Makefile <<'EOF'
.RECIPEPREFIX = >
IMAGE   = localhost:5000/monapp
VERSION ?= 1.0.0

.PHONY: test build push all

test:
> python3 -m unittest -v

build: test
> docker build -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

push: build
> docker push $(IMAGE):$(VERSION)
> docker push $(IMAGE):latest

all: push
EOF
make test
```{{exec}}

Remarquez que `build` **dépend** de `test` et `push` de `build` : impossible de publier une image dont les tests échouent. C'est le principe d'une pipeline (*fail fast*, [cours 5](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/05-tests-automatises-dans-la-pipeline.md)).

Cliquez sur **Vérifier**.
