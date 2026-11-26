# Étape 1 : un workflow « hello » exécuté avec `act`

Un workflow est un fichier YAML dans `.github/workflows/` ([cours 2](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/02-pipeline-as-code-github-actions.md)). Créez-en un avec un job **`hello`** de deux étapes :

```bash
cd ~/ci-actions
cat > .github/workflows/hello.yml <<'EOF'
name: Hello
on: [push]

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Dire bonjour
        run: echo "Bonjour depuis le workflow $GITHUB_WORKFLOW"
      - name: Afficher le système
        run: uname -a
EOF
cat .github/workflows/hello.yml
```{{exec}}

Listez les jobs que `act` détecte, puis exécutez **uniquement** le job `hello` en gardant une trace dans un journal :

```bash
act -l
act -j hello 2>&1 | tee ~/ci-actions/act-hello.log
```{{exec}}

Au premier lancement, `act` télécharge l'image du runner (quelques dizaines de secondes). Vous devez voir les deux étapes s'exécuter puis `Job succeeded`.

## Questions

- Que signifie `runs-on: ubuntu-latest` en local ? (Grâce à `~/.actrc`, ce libellé est associé à une image Docker légère.)
- Pourquoi un workflow n'a-t-il pas besoin de `git push` pour être testé ? (`act` simule l'évènement `push` localement.)

Cliquez sur **Vérifier**.
