# Atelier 03 — Cherry-pick, rétroportage et tags de version

## 🎯 Objectifs

- Prélever un commit précis avec `git cherry-pick` (seul, en série, avec `-x`).
- **Rétroporter** un correctif de sécurité vers une branche de maintenance.
- Gérer un conflit de cherry-pick.
- Créer des **tags** (légers et annotés), les publier, et les utiliser pour retrouver une version.

## 📋 Prérequis

- Ateliers [01](atelier-01-premiers-commits-branches.md) et [02](atelier-02-merge-vs-rebase.md) terminés.
- Cours lu : [Merge, rebase et cherry-pick](../cours/03-merge-rebase-cherry-pick.md) (section 4) et [Workflows d'équipe](../cours/05-workflows-equipe.md) (SemVer).
- Exercice interactif conseillé : [Cherry-pick](../interactif/exercices/04-cherry-pick.html).

## 🧪 Scénario

*Kamer Logistics* maintient deux versions de son API : la **2.x** (en développement, branche `main`) et la **1.x**
(encore en production chez un gros client, branche `release/1.x`). Une faille est corrigée sur `main` ; le client en 1.x
ne peut pas passer en 2.x : vous devez **rétroporter uniquement le correctif**, puis publier la version `v1.4.1`.

## Préparation

```bash
mkdir -p ~/git-lab && cd ~/git-lab && rm -rf cherry && mkdir cherry && cd cherry
git init -q -b main
git config user.name "Awa Test"; git config user.email "awa@kamer.example"
git config alias.graph "log --oneline --graph --all --decorate"

cat > api.sh <<'EOF'
#!/usr/bin/env bash
# API de suivi (version simplifiée)
saisie="$1"
echo "Recherche du colis : $saisie"
EOF
git add . && git commit -qm "feat: première version de l'API"
git tag -a v1.0.0 -m "Version 1.0.0"

echo 'echo "journal: requête reçue"' >> api.sh && git commit -qam "feat: journalise les requêtes"
echo 'echo "cache: activé"' >> api.sh           && git commit -qam "feat: ajoute un cache"
git tag -a v1.4.0 -m "Version 1.4.0"

# Création de la branche de maintenance 1.x à partir du tag v1.4.0
git branch release/1.x v1.4.0

# Évolutions 2.x sur main
echo 'echo "pagination: 50"' >> api.sh         && git commit -qam "feat: ajoute la pagination"
sed -i 's/^saisie="\$1"/saisie="${1\/\/[^a-zA-Z0-9-]\/}"   # SÉCURITÉ : filtre les caractères dangereux/' api.sh
git commit -qam "fix: filtre la saisie (faille d'injection CVE-fictive-2025-001)"
echo 'echo "export: csv"' >> api.sh            && git commit -qam "feat: ajoute l'export CSV"
git graph
```

## Étapes

### Étape 1 — Identifier le commit à rétroporter

```bash
git log --oneline main
git log --oneline --grep="fix:"
git show --stat HEAD~1
```

Notez l'empreinte du commit « fix: filtre la saisie… » :

```bash
FIX=$(git log --format=%h --grep="filtre la saisie" -1); echo "commit correctif = $FIX"
git show "$FIX"
```

> ❓ **Question 1** : Pourquoi ne peut-on pas simplement **fusionner** `main` dans `release/1.x` ? Qu'embarquerait-on en plus du correctif ?

### Étape 2 — Cherry-pick sur la branche de maintenance

```bash
git switch release/1.x
cat api.sh
git cherry-pick -x "$FIX"
git graph
cat api.sh
git log -1
```

Le message du nouveau commit se termine par `(cherry picked from commit …)` grâce à `-x`.

> ❓ **Question 2** : Le commit rétroporté a-t-il le **même SHA** que l'original ? Pourquoi (parent différent) ? Quel est l'intérêt de l'option `-x` pour la traçabilité ?

### Étape 3 — Un cherry-pick qui entre en conflit

On ajoute à `main` un correctif qui touche une ligne déjà modifiée sur `release/1.x` :

```bash
git switch main
sed -i 's/^echo "Recherche du colis : \$saisie"/echo "Recherche du colis n° $saisie"/' api.sh
git commit -qam "fix: améliore le message de recherche"
FIX2=$(git rev-parse --short HEAD)

git switch release/1.x
sed -i 's/^echo "Recherche du colis : \$saisie"/echo "Colis demandé : $saisie"/' api.sh
git commit -qam "fix: reformule le message (spécifique 1.x)"

git cherry-pick "$FIX2"                      # CONFLIT
git status
cat api.sh
```

Résolvez en conservant la formulation spécifique de la 1.x :

```bash
# Éditez api.sh : gardez « Colis demandé : $saisie » et supprimez les marqueurs
nano api.sh
git add api.sh
git cherry-pick --continue
git graph
```

Ou renoncez : `git cherry-pick --abort`.

> ❓ **Question 3** : Pourquoi un conflit apparaît-il ? Sur quelle base Git calcule-t-il le « three-way merge » d'un cherry-pick ? *(Indice : parent du commit pris comme base.)*

### Étape 4 — Plusieurs commits, plages et `-n`

```bash
git switch -c experience main~3                # branche expérimentale depuis un ancien point
echo "x1" > x1.txt && git add . && git commit -qm "exp: x1"
echo "x2" > x2.txt && git add . && git commit -qm "exp: x2"
echo "x3" > x3.txt && git add . && git commit -qm "exp: x3"
git graph

git switch -c recup main
git cherry-pick experience~2 experience       # x1 et x3 (liste explicite)
git log --oneline -3
git switch main && git branch -D recup

git switch -c recup2 main
git cherry-pick experience~2..experience      # plage : x2 et x3 (le début est exclu)
git log --oneline -3

git reset -q --hard main
git cherry-pick -n experience~1               # -n : applique SANS committer
git status -s
git reset -q --hard main
git switch -q main
```

> ❓ **Question 4** : Dans une plage `A..B`, le commit A est-il inclus ? Quelle plage prendriez-vous pour copier exactement `x1`, `x2` et `x3` ?

### Étape 5 — Les tags : légers et annotés

```bash
git tag                                  # liste (v1.0.0, v1.4.0)
git tag -n                               # avec leur message
git show v1.4.0 | head -12               # tag annoté : auteur, date, message, puis le commit

git switch release/1.x
git tag v1.4.1-rc1                       # tag LÉGER (juste un pointeur)
git tag -a v1.4.1 -m "Correctif de sécurité : filtrage de la saisie"
git tag -a v1.4.1 -m x 2>&1 | tail -1    # refuse : le tag existe déjà
git tag -d v1.4.1-rc1                    # supprimer un tag local
cat .git/refs/tags/v1.4.1                # l'empreinte de l'OBJET tag (annoté)
git cat-file -t v1.4.1                   # tag  (annoté)
git cat-file -t v1.0.0                   # tag  (annoté aussi)
git tag legere && git cat-file -t legere # commit  (léger)
git tag -d legere
git describe --tags                      # « v1.4.1 »
git graph
```

| | Tag **léger** | Tag **annoté** |
|---|---|---|
| Objet Git | Aucun : simple pointeur vers le commit | Objet `tag` : auteur, date, message, signature possible |
| Recommandé pour les versions publiées | ❌ | ✅ |
| Commande | `git tag nom` | `git tag -a nom -m "message"` |

> ❓ **Question 5** : Quel tag désignent `git cat-file -t` comme « tag » et lequel comme « commit » ? Lequel utiliseriez-vous pour une version livrée au client ?

### Étape 6 — Publier, retrouver, compiler une version

```bash
cd ~/git-lab && rm -rf cherry-central.git && git init -q --bare cherry-central.git
cd cherry
git remote add origin ../cherry-central.git
git push -q origin main release/1.x
git push origin v1.4.1                   # un tag n'est PAS poussé automatiquement
git push -q origin --tags                # tous les tags
git ls-remote --tags origin

# Retrouver exactement ce qui a été livré
git switch --detach v1.4.0
cat api.sh                                # sans le correctif
git switch --detach v1.4.1
cat api.sh                                # avec le correctif
git switch -q main

git diff v1.4.0 v1.4.1 --stat
git log --oneline v1.4.0..v1.4.1          # changements entre deux versions : le journal de livraison
git describe --tags --abbrev=7 main       # « v1.4.0-4-g... » : 4 commits après v1.4.0
```

> ❓ **Question 6** : Que raconte `git describe` pour `main` ? Pourquoi est-ce pratique pour numéroter automatiquement un build ?

### Étape 7 — Déplacer ou supprimer un tag publié (à éviter)

```bash
git tag -d v1.4.1
git push origin --delete v1.4.1          # supprime sur le distant
git tag -a v1.4.1 -m "Correctif de sécurité (re-créé)" release/1.x
git push origin v1.4.1
```

> ⚠️ **Attention** : un tag publié est un **engagement** : ceux qui l'ont déjà récupéré ne voient pas le changement (`git fetch --tags --force` est nécessaire). Pour corriger une version, **publiez une nouvelle** (`v1.4.2`), ne modifiez jamais une ancienne.

### Étape 8 — Versionnage sémantique

Complétez dans vos notes, en vous aidant des [Conventional Commits](../cours/05-workflows-equipe.md) :

| Commits depuis `v1.4.0` | Prochaine version |
|---|---|
| `fix:` uniquement | `v1.4.1` |
| au moins un `feat:` | |
| un `feat!:` ou `BREAKING CHANGE:` | |

## ✅ Validation

- [ ] `release/1.x` contient le correctif de sécurité mais **pas** la pagination ni l'export CSV (`git log --oneline release/1.x`).
- [ ] Le message du commit rétroporté contient `(cherry picked from commit …)`.
- [ ] Vous avez résolu un conflit de cherry-pick (ou fait un `--abort`).
- [ ] `v1.4.1` est un tag **annoté** (`git cat-file -t v1.4.1` → `tag`) et figure sur le distant (`git ls-remote --tags origin`).
- [ ] `git diff v1.4.0 v1.4.1` ne montre que le correctif de sécurité (et la reformulation).
- [ ] Vous pouvez expliquer pourquoi le cherry-pick crée un **nouveau** commit.

## 💡 Pour aller plus loin

- **Défi 1** : `git cherry-pick -m 1 <commit-de-fusion>` : prélevez une fusion en désignant la ligne principale.
- **Défi 2** : `git log --cherry-pick --left-right --oneline main...release/1.x` : listez les commits présents d'un seul côté malgré les cherry-picks.
- **Défi 3** : signez un tag (`git tag -s`) avec une clé GPG ou SSH et vérifiez-le (`git tag -v`).
- **Défi 4** : écrivez un script `rétroporter.sh <commit> <branche>` qui vérifie que l'arbre est propre, cherry-pick avec `-x` et affiche le résultat.

Atelier suivant : [Récupération avec reflog](atelier-04-recuperation-reflog.md).
