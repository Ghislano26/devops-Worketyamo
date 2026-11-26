# Bravo !

Vous avez écrit et exécuté deux workflows :

| Notion | Où vous l'avez vue |
|---|---|
| `on`, `jobs`, `steps`, `run` | `hello.yml` |
| `strategy.matrix` | 3 jobs `test` en parallèle |
| `needs` | `build` attend `test` |
| `act` | Exécution locale avant tout `git push` |

## Défi bonus : tests Python dans un workflow

1. Ajoutez un fichier `calcul.py` avec une fonction `addition(a, b)` et un `test_calcul.py` (module `unittest`).
2. Créez `tests.yml` avec `actions/checkout@v4`, `actions/setup-python@v5` et `python -m unittest`.
3. Exécutez-le avec `act` (image `catthehacker/ubuntu:act-22.04` pour que les actions fonctionnent) puis ajoutez une **matrice** sur deux versions de Python.
4. Validez la syntaxe avec **actionlint**.

## Pour aller plus loin

- [Pipeline as code avec GitHub Actions](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/02-pipeline-as-code-github-actions.md) · [GitLab CI et alternatives](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/03-gitlab-ci-et-alternatives.md).
- Suite : [atelier 2 — pipeline build, test et push](https://github.com/Ghislano26/devops-Worketyamo/tree/main/12-cicd/ateliers-killercoda/atelier-02-pipeline-build-test-push).
