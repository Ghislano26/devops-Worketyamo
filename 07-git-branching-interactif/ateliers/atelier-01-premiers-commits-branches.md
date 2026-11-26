# Atelier 01 — Premiers commits, branches et HEAD

## 🎯 Objectifs

- Observer concrètement le **modèle** de Git : commits, parents, `HEAD`, branches comme pointeurs.
- Créer des commits et des branches, se déplacer avec `git switch`.
- Provoquer et **sortir** d'un HEAD détaché.
- Lire le graphe avec `git log --graph` et les fichiers de `.git/`.

## 📋 Prérequis

- Cours lus : [Modéliser Git](../cours/01-modeliser-git.md) et [Branches et checkout](../cours/02-branches-et-checkout.md).
- Git configuré (`git config --global user.name` / `user.email`). Module 05 : [atelier Git](../../05-devops-outils/ateliers/atelier-01-git-branches.md) conseillé.
- *Facultatif mais recommandé* : faites d'abord l'exercice interactif [Branches de base](../interactif/exercices/01-branches-de-base.html) (ouvrez-le dans un navigateur).

## 🧪 Scénario

*Kamer Logistics* vous confie un dépôt de scripts d'exploitation. Avant de toucher à quoi que ce soit, votre responsable
exige que vous prouviez que vous comprenez ce qu'est réellement une branche. Vous allez **ouvrir le capot** de Git.

## Étapes

### Étape 1 — Créer le dépôt

```bash
mkdir -p ~/git-lab/atelier1 && cd ~/git-lab/atelier1
git init -b main
git config alias.graph "log --oneline --graph --all --decorate"
cat .git/HEAD
ls .git
```

> ❓ **Question 1** : Que contient `.git/HEAD` ? Le dépôt a-t-il déjà des commits ? (`git log` vous répond.)

### Étape 2 — Trois commits sur `main`

```bash
echo "# Scripts d'exploitation" > README.md
git add README.md && git commit -m "Initialise le dépôt"
echo '#!/usr/bin/env bash' > sante.sh && echo 'df -h /' >> sante.sh
git add sante.sh && git commit -m "Ajoute sante.sh"
echo 'free -h' >> sante.sh
git commit -am "Affiche la mémoire"
git graph
```

Inspectez le modèle :

```bash
cat .git/refs/heads/main
git cat-file -t HEAD
git cat-file -p HEAD
git cat-file -p 'HEAD^{tree}'
git rev-parse HEAD HEAD~1 HEAD~2
```

> ❓ **Question 2** : Dans la sortie de `git cat-file -p HEAD`, quelle ligne désigne le **parent** ? Comparez-la avec `git rev-parse HEAD~1`. Que remarquez-vous ?
> ❓ **Question 3** : Le premier commit (« Initialise le dépôt ») a-t-il une ligne `parent` ? Pourquoi ?

### Étape 3 — Une branche est un pointeur

```bash
git branch fonctionnalite
git graph
cat .git/refs/heads/main .git/refs/heads/fonctionnalite
git branch -vv
```

> ❓ **Question 4** : Les deux fichiers contiennent-ils la même empreinte ? Qu'est-ce que cela prouve sur le coût de création d'une branche ? Sur quelle branche `HEAD` est-il toujours ?

### Étape 4 — Faire avancer une seule branche

```bash
git switch fonctionnalite
cat .git/HEAD
echo 'echo "uptime: $(uptime -p)"' >> sante.sh
git commit -am "Affiche l'uptime"
git graph
git switch main
cat sante.sh
git graph
```

> ❓ **Question 5** : Après `git switch main`, l'« uptime » a disparu de `sante.sh`. Où est-il passé ? Qu'a fait `switch` sur le répertoire de travail ?

### Étape 5 — Faire diverger deux branches

```bash
echo "Voir sante.sh pour les contrôles." >> README.md
git commit -am "Documente sante.sh"
git graph
git log --oneline main..fonctionnalite     # commits de fonctionnalite absents de main
git log --oneline fonctionnalite..main     # et l'inverse
git merge-base main fonctionnalite
```

> ❓ **Question 6** : Quel est l'**ancêtre commun** (merge-base) ? Vérifiez qu'il correspond au commit « Affiche la mémoire ».

### Étape 6 — Créer + basculer, renommer, supprimer

```bash
git switch -c correctif/rapport          # crée et bascule
git branch -m correctif/rapports         # renomme
git branch
git switch main
git branch -d correctif/rapports         # supprime (fusionnée : elle ne porte aucun commit en plus)
git branch -d fonctionnalite             # refuse : pas fusionnée !
```

> ❓ **Question 7** : Pourquoi Git refuse-t-il `-d` pour `fonctionnalite` ? Quelle option forcerait la suppression, et quel risque cela comporte-t-il ?

### Étape 7 — HEAD détaché : explorer le passé

```bash
git switch --detach HEAD~2
git status | head -3
cat .git/HEAD                      # une empreinte, plus un nom de branche
git graph
cat README.md
```

Committez en étant détaché (danger contrôlé) :

```bash
echo "essai" > essai.txt && git add essai.txt && git commit -m "Essai en HEAD détaché"
git graph
git switch main
git graph                          # le commit d'essai n'est plus visible !
```

Retrouvez-le et sauvez-le :

```bash
git reflog | head -5
git branch sauvetage-essai HEAD@{1}
git graph
```

> ❓ **Question 8** : Pourquoi le commit « Essai » a-t-il disparu du graphe après le `switch main` ? Comment l'avez-vous retrouvé ? Comment auriez-vous **évité** de le perdre ?

### Étape 8 — Un dépôt distant simulé et le suivi

```bash
cd ~/git-lab
git init --bare central.git
cd atelier1
git remote add origin ../central.git
git push -u origin main
git push origin fonctionnalite
git branch -vv
cat .git/refs/remotes/origin/main
git status -sb
echo "ligne locale" >> README.md && git commit -am "Commit local"
git status -sb                     # « ahead 1 »
git log --oneline origin/main..main
```

> ❓ **Question 9** : Que signifie `[origin/main: ahead 1]` ? Où est stocké `origin/main` et qui peut le modifier ?

### Étape 9 — Les trois espaces

```bash
echo "a" > a.txt; echo "b" > b.txt
git add a.txt
git status -s                      # A  a.txt   ??  b.txt
git diff                           # (rien : a.txt est déjà dans l'index)
echo "a2" >> a.txt
git diff                           # répertoire de travail vs index
git diff --staged                  # index vs dernier commit
git diff HEAD                      # répertoire de travail vs dernier commit
git restore --staged a.txt
git restore a.txt
git clean -n                       # simule : quels fichiers non suivis seraient supprimés ?
```

> ❓ **Question 10** : Quelle commande compare quoi ? Remplissez : `git diff` = ___ vs ___ ; `git diff --staged` = ___ vs ___.

## ✅ Validation

- [ ] `git graph` montre `main` et `fonctionnalite` divergeant après « Affiche la mémoire ».
- [ ] Vous avez expliqué que `.git/refs/heads/<nom>` ne contient qu'une empreinte.
- [ ] Vous avez commité en HEAD détaché, **perdu** puis **récupéré** le commit via `git reflog`.
- [ ] `git branch -vv` montre `main` en suivi de `origin/main`.
- [ ] Vous distinguez les trois `git diff` (travail/index/HEAD).
- [ ] Vous avez refait l'exercice [Branches de base](../interactif/exercices/01-branches-de-base.html) et vu le graphe s'animer.

## 💡 Pour aller plus loin

- **Défi 1** : écrivez à la main une branche : `git update-ref refs/heads/manuelle HEAD`, puis `git branch` (elle apparaît).
- **Défi 2** : reconstituez l'arbre d'un commit avec `git ls-tree -r HEAD` et retrouvez un blob avec `git cat-file -p <empreinte>`.
- **Défi 3** : `git stash` : modifiez un fichier, changez de branche (Git refuse ?), mettez de côté, changez, reprenez avec `git stash pop`.
- **Défi 4** : créez un alias `git config --global alias.st "status -sb"` et un autre pour vos habitudes.

Atelier suivant : [Merge vs rebase](atelier-02-merge-vs-rebase.md).
