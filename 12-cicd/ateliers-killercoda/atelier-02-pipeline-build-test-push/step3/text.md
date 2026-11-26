# Étape 3 : `make push` et vérification dans le registre

La publication est la dernière étape de la chaîne : `push` dépend de `build`, qui dépend de `test`.

```bash
cd ~/cicd-app
make push
```{{exec}}

Interrogez l'API du registre : quels dépôts et quels tags contient-il ?

```bash
curl -s http://localhost:5000/v2/_catalog; echo
curl -s http://localhost:5000/v2/monapp/tags/list; echo
```{{exec}}

Vous devez voir le dépôt `monapp` avec les tags `1.0.0` et `latest`.

## Simuler une nouvelle version

Changez le message dans `app.py` (par exemple `Bonjour {nom} !` → `Salut {nom} !`), **adaptez le test** en conséquence, puis publiez la version `1.1.0` :

```bash
cd ~/cicd-app
sed -i 's/Bonjour/Salut/' app.py test_app.py
make push VERSION=1.1.0
curl -s http://localhost:5000/v2/monapp/tags/list; echo
```{{exec}}

> Un tag de version ne se **réécrit jamais** : on publie `1.1.0`, on ne remplace pas `1.0.0`. Le **digest** (`sha256:…`) est la référence réellement immuable.

Cliquez sur **Vérifier**.
