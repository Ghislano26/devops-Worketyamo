# Atelier 02 — Merge ou rebase ? Fusionner, rebaser, résoudre un conflit

## 🎯 Objectifs

- Réaliser un **fast-forward**, une **fusion à trois points** et la comparer à un **rebase** du même scénario.
- Constater que le rebase **recrée** les commits (nouveaux SHA).
- **Résoudre un conflit** de merge puis de rebase (et observer l'inversion `ours`/`theirs`).
- Nettoyer un historique avec `rebase -i` et appliquer la **règle d'or**.

## 📋 Prérequis

- [Atelier 01](atelier-01-premiers-commits-branches.md) terminé.
- Cours lu : [Merge, rebase et cherry-pick](../cours/03-merge-rebase-cherry-pick.md).
- Exercices interactifs conseillés **avant** : [Merge](../interactif/exercices/02-merge.html) et [Rebase](../interactif/exercices/03-rebase.html).

## 🧪 Scénario

Deux collègues de *Kamer Logistics*, Awa et Binta, modifient le script `sante.sh`. Vous allez rejouer **le même
scénario deux fois** : intégré par *merge*, puis par *rebase*, pour comparer les historiques. Ensuite, un conflit.

## Préparation : un dépôt de départ réutilisable

```bash
mkdir -p ~/git-lab && cd ~/git-lab
cat > prepare-atelier2.sh <<'EOF'
#!/usr/bin/env bash
# prepare-atelier2.sh <dossier> — crée un dépôt avec main (2 commits) et feature divergente (2 commits)
set -euo pipefail
rm -rf "$1" && mkdir -p "$1" && cd "$1"
git init -q -b main
git config user.name "Awa Test"; git config user.email "awa@kamer.example"
git config alias.graph "log --oneline --graph --all --decorate"
printf '#!/usr/bin/env bash\necho "Santé"\n' > sante.sh
git add . && git commit -qm "C1 : initialise sante.sh"
printf 'df -h /\n' >> sante.sh && git commit -qam "C2 : ajoute le disque"
git switch -qc feature
printf 'free -h\n' > memoire.sh && git add . && git commit -qm "F1 : ajoute memoire.sh"
printf 'uptime\n' >> memoire.sh && git commit -qam "F2 : ajoute l'uptime"
git switch -q main
printf '# Voir README\n' > README.md && git add . && git commit -qm "C3 : ajoute le README"
printf '# Auteur : equipe\n' >> README.md && git commit -qam "C4 : ajoute l'auteur"
EOF
chmod +x prepare-atelier2.sh
./prepare-atelier2.sh merge-demo && ./prepare-atelier2.sh rebase-demo
cd merge-demo && git graph
```

Vous devez voir `main` (C1 ← C2 ← C3 ← C4) et `feature` (C2 ← F1 ← F2) **divergentes** depuis `C2`.

## Étapes

### Étape 1 — Le fast-forward

```bash
cd ~/git-lab && rm -rf ff-demo && mkdir ff-demo && cd ff-demo
git init -q -b main && git config user.name "Awa Test" && git config user.email awa@kamer.example
git config alias.graph "log --oneline --graph --all --decorate"
echo "base" > f.txt && git add . && git commit -qm "Base"
git switch -qc correctif
echo "correctif" >> f.txt && git commit -qam "X1 : petit correctif"
git switch -q main                        # main n'a PAS bougé depuis la création de « correctif »
git merge --ff-only correctif
git graph
git log --merges --oneline | wc -l        # 0 commit de fusion
```

> ❓ **Question 1** : Quand un merge est-il un fast-forward ? Pourquoi aucun commit de fusion n'a-t-il été créé ?

### Étape 2 — Fusion à trois points (merge)

```bash
cd ~/git-lab/merge-demo
git switch main
git merge feature -m "Fusionne feature dans main"
git graph
git cat-file -p HEAD | head -5            # deux lignes « parent »
git log --oneline --merges
git merge-base HEAD^1 HEAD^2
```

> ❓ **Question 2** : Combien de parents le commit de fusion a-t-il ? Quel est le point de divergence (`merge-base`) ?
> ❓ **Question 3** : Les SHA de C3, C4, F1, F2 ont-ils changé ? *(Comparez avec l'état précédent : `git reflog`.)*

### Étape 3 — Le même scénario avec `rebase`

```bash
cd ~/git-lab/rebase-demo
git graph
git rev-parse --short feature > /tmp/avant-rebase.txt      # SHA de F2 avant
git switch feature
git rebase main
git graph
echo "avant : $(cat /tmp/avant-rebase.txt)   après : $(git rev-parse --short feature)"
git switch main
git merge --ff-only feature
git graph
```

> ❓ **Question 4** : L'historique est-il linéaire ? Le SHA de `F2` est-il le même avant/après ? Pourquoi les commits sont-ils considérés comme **nouveaux** ? *(auteur, parent, donc empreinte différents).*
> ❓ **Question 5** : Que devient l'ancien `F2` ? Retrouvez-le avec `git reflog`.

Comparez les deux historiques :

```bash
cd ~/git-lab && for d in merge-demo rebase-demo; do echo "=== $d ==="; (cd $d && git log --oneline --graph); done
```

| | `merge-demo` | `rebase-demo` |
|---|---|---|
| Forme du graphe | | |
| Commit de fusion | | |
| Commits réécrits | | |

(Remplissez le tableau dans vos notes.)

### Étape 4 — Un conflit lors d'un **merge**

```bash
cd ~/git-lab
mkdir conflit-merge && cd conflit-merge
git init -q -b main && git config user.name "Awa Test" && git config user.email awa@kamer.example
git config alias.graph "log --oneline --graph --all --decorate"
printf 'echo "Contrôle de santé"\ndf -h /\n' > sante.sh
git add . && git commit -qm "Initialise"
git switch -qc titre-awa
sed -i '1s/.*/echo "=== Santé (Awa) ==="/' sante.sh && git commit -qam "Awa : nouveau titre"
git switch -q main
git switch -qc titre-binta
sed -i '1s/.*/echo "### Santé du serveur ###"/' sante.sh && git commit -qam "Binta : autre titre"
git switch -q main
git merge titre-awa                       # OK (fast-forward)
git merge titre-binta                     # CONFLIT
git status
cat sante.sh
git merge --abort                         # on renonce : retour à l'état d'avant la fusion
git status -sb
git merge titre-binta                     # on recommence : le même conflit réapparaît
```

Résolvez :

```bash
nano sante.sh                             # gardez UNE seule ligne de titre ; supprimez <<<<<<<, =======, >>>>>>>
grep -n '<<<<<<<\|>>>>>>>' sante.sh || echo "plus de marqueurs"
bash -n sante.sh && echo "syntaxe OK"
git add sante.sh
git commit                                # message de fusion proposé
git graph
```

> ❓ **Question 6** : Dans le fichier en conflit, que représentent `HEAD` et le nom après `>>>>>>>` ? Pourquoi `git add` est-il nécessaire pour conclure ?

### Étape 5 — Un conflit lors d'un **rebase** (les rôles s'inversent)

```bash
cd ~/git-lab && rm -rf conflit-rebase && mkdir conflit-rebase && cd conflit-rebase
git init -q -b main && git config user.name "Awa Test" && git config user.email awa@kamer.example
git config alias.graph "log --oneline --graph --all --decorate"
printf 'titre=Santé\nport=80\n' > conf.ini
git add . && git commit -qm "Initialise"
git switch -qc feature
sed -i 's/^port=.*/port=8080/' conf.ini && git commit -qam "feature : port 8080"
git switch -q main
sed -i 's/^port=.*/port=9090/' conf.ini && git commit -qam "main : port 9090"
git switch -q feature
git rebase main                           # CONFLIT
cat conf.ini
git status | head -6
```

Dans le fichier, la partie `HEAD` correspond à **main** (la base sur laquelle on rejoue) et l'autre côté à **votre commit** de `feature`.

```bash
sed -i '/^<<<<<<<\|^=======\|^>>>>>>>/d;/port=8080/d' conf.ini      # on choisit 9090
cat conf.ini
git add conf.ini
git rebase --continue                    # (acceptez le message, enregistrez et quittez l'éditeur)
git graph
```

> ❓ **Question 7** : Pourquoi, pendant un rebase, `HEAD` représente-t-il la branche **de base** (`main`) et non votre travail ? *(Indice : Git rejoue vos commits un par un sur la base.)*

### Étape 6 — Nettoyer avec `rebase -i`

```bash
cd ~/git-lab && rm -rf nettoyage && mkdir nettoyage && cd nettoyage
git init -q -b main && git config user.name "Awa Test" && git config user.email awa@kamer.example
git config alias.graph "log --oneline --graph --all --decorate"
echo "base" > f.txt && git add . && git commit -qm "Base"
git switch -qc fonctionnalite
echo "1" > a.txt && git add . && git commit -qm "WIP"
echo "2" >> a.txt && git commit -qam "fix"
echo "3" >> a.txt && git commit -qam "oups"
echo "debug" > debug.txt && git add . && git commit -qm "debug temporaire"
git rm -q debug.txt && git commit -qm "retire le debug"
git log --oneline
```

Trois commits sont du bruit. Lancez :

```bash
GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/fixup/;3s/^pick/fixup/;4s/^pick/drop/;5s/^pick/drop/'" git rebase -i main
git log --oneline
```

*(Pour vous exercer à la main : `git rebase -i main` ouvre l'éditeur ; remplacez `pick` par `fixup` / `squash` / `reword` / `drop`.)*

Puis donnez un vrai message :

```bash
git commit --amend -m "feat: ajoute a.txt avec son contenu"
git graph
```

> ❓ **Question 8** : Combien de commits restent ? Pourquoi est-il légitime de réécrire ici, mais pas sur une branche déjà utilisée par vos collègues ?

### Étape 7 — La règle d'or en pratique

```bash
cd ~/git-lab && rm -rf regle-or && mkdir regle-or && cd regle-or
git init -q --bare central.git
git clone -q central.git awa 2>/dev/null; git clone -q central.git binta 2>/dev/null
cd awa && git config user.name Awa && git config user.email a@k.example
git switch -qc partagee && echo 1 > f && git add f && git commit -qm "A1" && git push -q -u origin partagee
cd ../binta && git config user.name Binta && git config user.email b@k.example
git fetch -q && git switch -q partagee && echo 2 >> f && git commit -qam "B1" && git push -q
cd ../awa
git commit -q --amend -m "A1 (réécrit)" --allow-empty      # Awa réécrit un commit DÉJÀ publié
git push origin partagee 2>&1 | tail -2                    # rejeté
git push --force-with-lease origin partagee 2>&1 | tail -2 # rejeté aussi : B1 a été poussé entre-temps
```

> ❓ **Question 9** : Pourquoi le push est-il refusé, et pourquoi `--force-with-lease` protège-t-il mieux que `--force` ? Que se serait-il passé avec `--force` ? *(Le commit de Binta aurait été écrasé sur le distant.)*

## ✅ Validation

- [ ] `merge-demo` montre un commit de fusion à **deux parents** ; `rebase-demo` est **linéaire**.
- [ ] Le SHA de `F2` a **changé** après le rebase (preuve de la réécriture).
- [ ] Vous avez résolu un conflit de **merge** et un conflit de **rebase** sans laisser de marqueurs.
- [ ] `git merge --abort` a ramené un dépôt propre.
- [ ] Le `rebase -i` a réduit 5 commits à 1 commit propre.
- [ ] Vous pouvez énoncer la règle d'or du rebase et expliquer `--force-with-lease`.

## 💡 Pour aller plus loin

- **Défi 1** : `git config --global merge.conflictStyle zdiff3` puis reproduisez un conflit : que montre la section supplémentaire ?
- **Défi 2** : activez `git config --global rerere.enabled true`, résolvez un conflit, annulez-le, refaites-le : Git réutilise votre résolution.
- **Défi 3** : `git pull --rebase` vs `git pull` : provoquez les deux situations avec deux clones et comparez les graphes.
- **Défi 4** : `git range-diff main@{1}..feature@{1} main..feature` après un rebase pour comparer avant/après.

Atelier suivant : [Cherry-pick et tags](atelier-03-cherry-pick-et-tags.md).
