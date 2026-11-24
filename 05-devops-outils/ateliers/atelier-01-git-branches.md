# Atelier 01 — Git : commits, branches, fusions et conflits

## 🎯 Objectifs

- Initialiser un dépôt et produire des commits atomiques avec de bons messages.
- Travailler avec des branches, fusionner (`merge`) et rebaser (`rebase`).
- Résoudre un **conflit** de fusion.
- Annuler proprement (`restore`, `revert`, `reflog`) et simuler un workflow de *pull request* avec un dépôt distant local.

## 📋 Prérequis

- Modules 01 à 04 terminés (au minimum les modules 01 et 02).
- Cours lu : [Git et workflows collaboratifs](../cours/01-git-workflow.md).
- Git installé : `git --version` (inclus dans la [checklist post-installation](../../00-installation-ubuntu-vm/checklist-post-installation.md)).

> 💡 **Conseil** : cet atelier n'a besoin d'**aucun compte GitHub** : le « dépôt distant » est un simple dossier local (dépôt *bare*).

## 🧪 Scénario

L'équipe de *Kamer Logistics* gère ses scripts d'exploitation dans un dépôt Git. Vous (**Awa**) et une collègue
(**Binta**, jouée par vous aussi) modifiez le même script. Vous allez : créer le dépôt, ajouter des fonctionnalités sur
des branches, provoquer un conflit, le résoudre, et corriger une erreur d'historique.

## Étapes

### Étape 1 — Configuration

```bash
git config --global user.name "Awa Test"
git config --global user.email "awa@kamer.example"
git config --global init.defaultBranch main
git config --global core.editor nano
git config --list | grep -E "user|defaultBranch|editor"
```

### Étape 2 — Le dépôt distant partagé (simulé) et le premier clone

```bash
mkdir -p ~/atelier-git && cd ~/atelier-git
git init --bare central.git                 # dépôt « serveur » sans répertoire de travail
git clone central.git awa 2>&1 | tail -1
cd awa
git status
git branch
```

> ❓ **Question 1** : Que signifie « bare » ? Pourquoi un dépôt partagé n'a-t-il pas de répertoire de travail ?

### Étape 3 — Premiers commits

```bash
cat > sante.sh <<'EOF'
#!/usr/bin/env bash
echo "Contrôle de santé"
df -h /
EOF
chmod +x sante.sh
printf '*.log\n.env\n' > .gitignore
git status
git add sante.sh
git status --short
git commit -m "Ajoute le script de contrôle de santé"
git add .gitignore
git commit -m "Ajoute .gitignore"
git log --oneline
git push -u origin main
```

> ❓ **Question 2** : À quoi sert l'index (*staging area*) ? Pourquoi a-t-on fait deux commits séparés plutôt qu'un seul ?

### Étape 4 — Explorer l'intérieur de Git

```bash
cat .git/HEAD
cat .git/refs/heads/main
git cat-file -t HEAD
git cat-file -p HEAD
git cat-file -p 'HEAD^{tree}'
```

> ❓ **Question 3** : Quels types d'objets avez-vous rencontrés ? Que contient un objet *commit* ?

### Étape 5 — Branche de fonctionnalité

```bash
git switch -c fonctionnalite/memoire
cat >> sante.sh <<'EOF'
echo "Mémoire :"
free -h | head -2
EOF
git diff
git commit -am "Affiche l'utilisation de la mémoire"
git log --oneline --graph --all
git switch main
cat sante.sh                       # la mémoire n'apparaît pas : normal
git merge fonctionnalite/memoire   # fast-forward
git log --oneline --graph --all
```

> ❓ **Question 4** : Pourquoi la fusion a-t-elle été un *fast-forward* ? Que se serait-il passé si `main` avait avancé entre-temps ?

### Étape 6 — Provoquer un conflit

Deux branches vont modifier **la même ligne**.

```bash
git switch -c fonctionnalite/titre-awa
sed -i 's/^echo "Contrôle de santé"/echo "=== Contrôle de santé (Awa) ==="/' sante.sh
git commit -am "Awa : nouveau titre"

git switch main
git switch -c fonctionnalite/titre-binta
sed -i 's/^echo "Contrôle de santé"/echo "### Santé du serveur (Binta) ###"/' sante.sh
git commit -am "Binta : titre différent"

git switch main
git merge fonctionnalite/titre-awa          # OK (fast-forward)
git merge fonctionnalite/titre-binta        # CONFLIT
git status
```

Ouvrez le fichier :

```bash
cat sante.sh
```

Vous voyez les marqueurs `<<<<<<<`, `=======`, `>>>>>>>`. Résolvez :

```bash
nano sante.sh        # gardez UNE ligne de titre (ex. "=== Santé du serveur ===") et supprimez les marqueurs
bash -n sante.sh && echo "syntaxe OK"
git add sante.sh
git commit           # accepte le message de fusion proposé
git log --oneline --graph --all
```

> ❓ **Question 5** : Pourquoi Git ne peut-il pas résoudre ce conflit seul ? Pourquoi `git add` marque-t-il la résolution ?

> 💡 **Conseil** : `git merge --abort` annule une fusion en cours si vous êtes perdu.

### Étape 7 — `rebase` pour un historique linéaire

```bash
git push origin main
git switch -c fonctionnalite/disque-inodes
echo 'echo "Inodes :"; df -i / | tail -1' >> sante.sh
git commit -am "Affiche les inodes"
git switch main
echo '# Voir README pour l usage' >> sante.sh
git commit -am "Ajoute un commentaire d'usage"
git switch fonctionnalite/disque-inodes
git rebase main
git log --oneline --graph --all
git switch main
git merge fonctionnalite/disque-inodes       # fast-forward : historique linéaire
```

> ❓ **Question 6** : En quoi les empreintes (hash) du commit « Affiche les inodes » ont-elles changé après `rebase` ? Pourquoi ne faut-il pas rebaser des commits déjà publiés ?

### Étape 8 — Annuler : `restore`, `revert`, `reset`, `reflog`

```bash
# 1. Annuler une modification non commitée
echo "ligne indésirable" >> sante.sh
git diff
git restore sante.sh

# 2. Annuler un commit PUBLIÉ de manière sûre (revert)
echo 'echo "debug: ne pas livrer"' >> sante.sh
git commit -am "Ajoute un debug par erreur"
git push origin main
git revert --no-edit HEAD
git log --oneline | head -3
git push origin main

# 3. Le filet de sécurité : reflog (travail LOCAL seulement)
echo 'echo "brouillon"' >> sante.sh
git commit -am "Brouillon"
git reset --hard HEAD~1                      # le commit « disparaît »...
git reflog | head -5
git reset --hard HEAD@{1}                    # ... mais on le récupère
git log --oneline | head -3
git reset --hard HEAD~1                      # on le retire définitivement (non publié)
```

> ❓ **Question 7** : Pourquoi utiliser `revert` et non `reset --hard` pour un commit déjà poussé ?

### Étape 9 — Simuler la collaboration : un second clone

```bash
cd ~/atelier-git
git clone central.git binta 2>&1 | tail -1
cd binta
git config user.name "Binta Test"
git config user.email "binta@kamer.example"
echo 'echo "Charge : $(cut -d" " -f1-3 /proc/loadavg)"' >> sante.sh
git commit -am "Binta : affiche la charge CPU"
git push origin main

cd ~/atelier-git/awa
git fetch
git log --oneline HEAD..origin/main       # commits distants que je n'ai pas
git pull
git log --oneline --graph --all | head
```

Provoquez un rejet de `push` :

```bash
cd ~/atelier-git/awa
echo '# note Awa' >> sante.sh
git commit -am "Awa : note"
cd ../binta
echo '# note Binta' >> sante.sh
git commit -am "Binta : note"
git push origin main
cd ../awa
git push origin main          # rejeté : non fast-forward
git pull --no-rebase          # (peut produire un conflit : résolvez-le comme à l'étape 6)
git push origin main
```

> ❓ **Question 8** : Pourquoi Git refuse-t-il le dernier `push` ? Que devez-vous faire avant de pouvoir publier ?

### Étape 10 — Étiquette de version

```bash
git tag -a v1.0.0 -m "Première version stable"
git push origin v1.0.0
git tag
git show v1.0.0 | head -5
git blame sante.sh | head -5
git log -S"inodes" --oneline
```

## ✅ Validation

- [ ] `git log --oneline --graph --all` montre au moins une fusion avec conflit résolue et une branche rebasée.
- [ ] Aucun marqueur `<<<<<<<` ne reste dans `sante.sh` (`grep -n '<<<<' sante.sh` ne renvoie rien).
- [ ] Le dépôt distant contient les commits de `awa` et `binta` (`git --git-dir=~/atelier-git/central.git log --oneline`).
- [ ] Le tag `v1.0.0` existe localement et dans le dépôt distant.
- [ ] Vous avez retrouvé un commit « perdu » avec `git reflog`.
- [ ] Vous pouvez expliquer la différence entre `merge`, `rebase`, `revert` et `reset`.

## 💡 Pour aller plus loin

- **Défi 1** : utilisez `git rebase -i HEAD~3` pour fusionner (*squash*) trois commits en un seul avant publication.
- **Défi 2** : utilisez `git stash` pour interrompre un travail, corriger un bug urgent sur `main`, puis reprendre.
- **Défi 3** : créez un hook `pre-commit` qui exécute `bash -n` et `shellcheck` sur `sante.sh`.
- **Défi 4** : poussez le dépôt sur GitHub via SSH, ouvrez une *pull request* entre deux branches et fusionnez-la avec « Squash and merge ».

Atelier suivant : [Premier Dockerfile](atelier-02-premier-dockerfile.md).
