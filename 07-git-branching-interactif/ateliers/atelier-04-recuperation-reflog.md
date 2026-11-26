# Atelier 04 — Récupération : reflog, reset et revert

## 🎯 Objectifs

- Comparer concrètement `reset --soft`, `--mixed` et `--hard`.
- **Récupérer** des commits « perdus » avec `git reflog` après un `reset --hard`, un rebase raté et une suppression de branche.
- Utiliser `revert` pour annuler un commit **publié** sans réécrire l'historique.
- Prendre l'habitude de poser un **filet de sécurité** avant une opération risquée.

## 📋 Prérequis

- Ateliers [01](atelier-01-premiers-commits-branches.md) à [03](atelier-03-cherry-pick-et-tags.md) terminés.
- Cours lu : [Reflog et récupération](../cours/04-reflog-et-recuperation.md).
- Exercice interactif conseillé : la commande `git reset --hard <sha>` dans [Merge](../interactif/exercices/02-merge.html) et [Rebase](../interactif/exercices/03-rebase.html).

## 🧪 Scénario

Vendredi 17 h. Un collègue de *Kamer Logistics* a lancé un `git reset --hard` et croit avoir perdu une semaine de
travail. Un déploiement a aussi embarqué un commit défectueux, déjà poussé en production. Vous jouez le pompier : récupérer l'un, annuler l'autre, **proprement**.

## Préparation

```bash
mkdir -p ~/git-lab && cd ~/git-lab && rm -rf secours && mkdir secours && cd secours
git init -q -b main
git config user.name "Awa Test"; git config user.email "awa@kamer.example"
git config alias.graph "log --oneline --graph --all --decorate"
for i in 1 2 3 4 5; do echo "ligne $i" >> travail.txt; git add . ; git commit -qm "Commit $i"; done
git graph
```

## Étapes

### Étape 1 — Comparer les trois `reset`

Nous testons les trois modes à partir du même état, puis nous revenons. Notez à chaque fois : `git status -s`, `git log --oneline`, contenu de `travail.txt`.

```bash
git branch point-depart                      # filet de sécurité : on pourra toujours revenir à cet état

echo "modification non commitée" >> travail.txt
git add travail.txt                          # une modif DANS l'index
echo "autre modif non indexée" >> notes.txt  # fichier non suivi
git status -s
```

**a) `--soft`** :

```bash
git reset --soft HEAD~2
git status -s                                # les changements des commits 4 et 5 sont dans l'INDEX
git log --oneline
cat travail.txt
git reset --soft point-depart                # retour (HEAD seulement)
```

**b) `--mixed`** (défaut) :

```bash
git reset HEAD~2
git status -s                                # changements dans le répertoire de travail, NON indexés
git log --oneline
cat travail.txt
git reset --soft point-depart
```

**c) `--hard`** (⚠️ détruit les modifications non commitées) :

```bash
git reset --hard HEAD~2
git status -s
git log --oneline
cat travail.txt                              # « modification non commitée » a DISPARU
ls notes.txt                                 # le fichier non suivi est resté (reset ne touche pas aux fichiers non suivis)
```

Remplissez le tableau :

| Mode | HEAD / branche | Index | Répertoire de travail |
|---|---|---|---|
| `--soft` | | | |
| `--mixed` | | | |
| `--hard` | | | |

> ❓ **Question 1** : Quelle modification a été **définitivement perdue** avec `--hard` ? Pourquoi le reflog ne peut-il pas la restaurer ?

Récupérez les commits 4 et 5 :

```bash
git reset --hard point-depart
git log --oneline
rm -f notes.txt
```

### Étape 2 — Récupérer après un `reset --hard` accidentel

```bash
git graph
git reset --hard HEAD~3                      # « oups »
git log --oneline                            # il ne reste que 2 commits
git reflog
```

Repérez la ligne `commit: Commit 5` : c'est l'état **d'avant** l'accident.

```bash
git reset --hard HEAD@{1}                    # l'état avant le reset
git log --oneline                            # 5 commits : tout est revenu
git reflog | head -4
```

> ❓ **Question 2** : Que signifie `HEAD@{1}` ? Pourquoi est-ce `{1}` et non `{0}` ? *(`{0}` est l'état courant.)*

Variante plus prudente : **ne pas écraser** votre état courant, créer une branche de secours.

```bash
git reset --hard HEAD~3
git branch sauvetage "HEAD@{1}"
git graph
git switch sauvetage && git switch main
git branch -D sauvetage
git reset --hard "HEAD@{2}" 2>/dev/null || git reset --hard point-depart
```

### Étape 3 — Récupérer après un rebase raté

```bash
git switch -c feature
for n in a b c; do echo "$n" > "f-$n.txt"; git add .; git commit -qm "feature : $n"; done
git switch -q main
echo "nouveau en main" > autre.txt && git add . && git commit -qm "main avance"
git switch -q feature
git graph
```

Un rebase s'engage, puis on le regrette :

```bash
git rebase main
git graph                                    # feature a été rejouée (nouveaux SHA)
git reflog | head -8
```

Annulez grâce à `ORIG_HEAD` ou au reflog :

```bash
git reset --hard ORIG_HEAD                   # position de HEAD avant le rebase
git graph
# ou, équivalent :  git reflog  puis  git reset --hard HEAD@{N}  (la ligne « checkout: moving from main to feature »)
```

> ❓ **Question 3** : Pourquoi `ORIG_HEAD` fonctionne-t-il ici ? Quelles autres opérations le positionnent ? *(`merge`, `reset`, `rebase`, `pull`.)*

### Étape 4 — Branche supprimée par erreur

```bash
git switch -q main
git branch -D feature                        # Git affiche : Deleted branch feature (was XXXXXXX).
git branch
```

Retrouvez-la :

```bash
git reflog | grep -i "feature" | head -3
git branch feature-retrouvee <SHA-affiché-ci-dessus>
git graph
git log --oneline feature-retrouvee
```

> ❓ **Question 4** : Si vous aviez perdu le message de suppression, comment trouveriez-vous le SHA ? *(Indice : `git reflog`, `git fsck --lost-found`.)*

### Étape 5 — Les commits « dangling » et `git fsck`

```bash
git branch -D feature-retrouvee
git reflog expire --expire=now --all          # ⚠️ simulation d'une expiration TOTALE du reflog (laboratoire)
git fsck --lost-found                         # « dangling commit XXXXXXX »
```

Le commit existe encore physiquement :

```bash
DANGLING=$(git fsck --lost-found 2>/dev/null | awk '/dangling commit/ {print $3; exit}')
git show --stat "$DANGLING" | head -8
git branch recup "$DANGLING"
git log --oneline recup
```

> ⚠️ **Attention** : `git gc --prune=now` supprimerait définitivement ces objets. Ne lancez **jamais** ces commandes sur un dépôt réel sans raison précise (ex. : purger un secret).

### Étape 6 — Annuler un commit **publié** : `revert`

On simule un dépôt partagé :

```bash
cd ~/git-lab && rm -rf prod-central.git && git init -q --bare prod-central.git
cd secours && git remote remove origin 2>/dev/null; git remote add origin ../prod-central.git
git switch -q main
git push -q -u origin main
echo "mot_de_passe=admin123" > config.ini            # commit DÉFECTUEUX livré en production
git add . && git commit -qm "feat: ajoute la configuration"
echo "ok" > bonus.txt && git add . && git commit -qm "feat: ajoute un bonus"
git push -q
git graph
```

Le commit « configuration » est fautif. Un collègue a déjà fait `git pull`. **N'utilisez pas `reset`** : annulez avec `revert`.

```bash
FAUTIF=$(git log --format=%h --grep="ajoute la configuration" -1)
git revert --no-edit "$FAUTIF"
git graph
cat config.ini 2>/dev/null || echo "config.ini n'existe plus dans l'arbre de travail"
git push
```

> ❓ **Question 5** : Pourquoi `revert` est-il sûr pour les collègues alors que `reset --hard` + `push --force` ne l'est pas ? Que contient l'historique après `revert` ?
> ❓ **Question 6** : Le mot de passe est-il toujours dans l'historique ? *(Oui : `git log -p -- config.ini`.)* Que faut-il faire en plus ? *(Le **révoquer** ; réécrire l'historique avec `git filter-repo` n'est qu'un complément.)*

### Étape 7 — Annuler une fusion

```bash
git switch -qc topic main~3
echo "topic" > topic.txt && git add . && git commit -qm "topic: ajout"
git switch -q main
git merge --no-ff topic -m "Fusionne topic"
git graph
git revert -m 1 HEAD --no-edit               # annule la fusion en gardant le 1er parent (main) comme ligne principale
git graph
ls topic.txt 2>&1 | tail -1
```

> ❓ **Question 7** : À quoi sert `-m 1` ? Pourquoi un commit de fusion a-t-il besoin qu'on précise le parent ?

### Étape 8 — Le filet de sécurité avant l'opération risquée

Bonne pratique à adopter dès maintenant :

```bash
git branch avant-menage                       # un pointeur, gratuit : « point de sauvegarde »
git switch -q main
git reset --hard HEAD~2                       # …opération risquée (ici : un reset)…
git log --oneline | head -3
git reset --hard avant-menage                 # retour instantané si ça tourne mal
git log --oneline | head -3
git branch -D avant-menage
```

## ✅ Validation

- [ ] Vous avez rempli le tableau `--soft` / `--mixed` / `--hard` sans relire le cours.
- [ ] Après un `reset --hard HEAD~3`, vous avez retrouvé les 5 commits via `git reflog` + `git reset --hard HEAD@{1}`.
- [ ] Vous avez annulé un rebase avec `ORIG_HEAD`.
- [ ] Vous avez recréé une branche supprimée à partir de son SHA.
- [ ] `git fsck --lost-found` vous a permis de retrouver un commit sans aucune référence.
- [ ] Le commit fautif publié a été annulé avec `revert` (et poussé) sans `--force`.
- [ ] Vous savez expliquer pourquoi le travail **non commité** n'est pas récupérable.

## 💡 Pour aller plus loin

- **Défi 1** : `git stash` un travail non commité, faites un `git reset --hard`, puis récupérez-le avec `git stash pop` : quelle différence avec le cas de l'étape 1 ?
- **Défi 2** : `git reflog show main` et `git log -g --date=iso` : lisez les dates des déplacements de branche.
- **Défi 3** : configurez `git config --global gc.reflogExpire 180.days` et expliquez l'effet.
- **Défi 4** : écrivez un alias `git undo` = `reset --soft HEAD~1`, et un alias `git oups` qui affiche `git reflog -10`.

Atelier terminé. Passez à la [partie interactive](../interactif/README.md) pour consolider avec les exercices animés, ou retournez au [sommaire du module](../README.md).
