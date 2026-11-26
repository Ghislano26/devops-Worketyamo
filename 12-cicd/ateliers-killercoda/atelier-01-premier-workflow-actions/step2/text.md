# Étape 2 : `matrix` et `needs`

Créez un second workflow **`ci.yml`** : un job `test` qui s'exécute sur **3 versions** grâce à une **matrice**, puis un job `build` qui **dépend** de `test` (`needs`).

```bash
cd ~/ci-actions
cat > .github/workflows/ci.yml <<'EOF'
name: CI
on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        version: ["1", "2", "3"]
    steps:
      - name: Tester une version
        run: echo "Test avec la version ${{ matrix.version }}"

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Construire après les tests
        run: echo "Build lancé car tous les tests sont passés"
EOF
cat .github/workflows/ci.yml
```{{exec}}

Exécutez ce workflow (option `-W` pour viser le fichier) et conservez le journal :

```bash
act -W .github/workflows/ci.yml 2>&1 | tee ~/ci-actions/act-ci.log
```{{exec}}

Observez dans le journal :

- **trois** exécutions de `test` (une par valeur de la matrice), en parallèle ;
- `build` qui démarre **après** elles : sans `needs`, il partirait en même temps ;
- **quatre** lignes `Job succeeded` au total.

```bash
grep -c 'Job succeeded' ~/ci-actions/act-ci.log
```{{exec}}

## Essayez de casser

Remplacez temporairement dans `ci.yml` une commande de `test` par `exit 1` et relancez : le job `build` doit être **ignoré**. Remettez ensuite le fichier d'origine avant de vérifier.

Cliquez sur **Vérifier**.
