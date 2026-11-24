# Git et workflows collaboratifs

## Pourquoi ce cours ?

Sans gestion de versions, on se retrouve avec `script_final.sh`, `script_final_v2.sh`, `script_final_VRAIMENT.sh`.
**Git** résout ce problème et bien davantage : il garde l'historique complet de chaque modification, permet de
travailler à plusieurs sans s'écraser mutuellement, et sert de **source de vérité** à toute la chaîne DevOps
(*Infrastructure as Code*, CI/CD, GitOps). Tout ce que vous avez écrit dans ce cours (scripts, fichiers de configuration) a
vocation à vivre dans un dépôt Git.

## 1. Concepts fondamentaux

Git est un système de gestion de versions **distribué** : chaque copie du dépôt contient **tout l'historique**.

```text
Dépôt distant (GitHub)  ◄──── push ──── Dépôt local ◄── commit ── Index (staging) ◄── add ── Répertoire de travail
        │                                   ▲                                                    ▲
        └────────── clone / fetch / pull ───┘                                                    │
                                                              vos fichiers modifiés ─────────────┘
```

| Zone | Rôle |
|---|---|
| **Répertoire de travail** | Vos fichiers tels que vous les éditez |
| **Index** (*staging area*) | Ce qui sera inclus dans le prochain commit |
| **Dépôt local** (`.git/`) | L'historique des commits |
| **Dépôt distant** (*remote*) | Copie partagée (GitHub, GitLab) |

## 2. Fonctionnement interne

Git est une **base de données d'objets adressés par leur contenu** (empreinte SHA-1/SHA-256) dans `.git/objects/`.

| Objet | Contenu |
|---|---|
| **blob** | Le contenu d'un fichier |
| **tree** | Un répertoire : liste de noms → blobs/trees |
| **commit** | Un instantané (tree) + auteur + message + **parent(s)** |
| **tag** | Une étiquette sur un commit |

```text
 commit C3 ──► commit C2 ──► commit C1
   │             │             │
 tree          tree          tree     ← chaque commit pointe vers l'état COMPLET du projet
```

Une **branche** n'est qu'un **pointeur** (un fichier de 41 octets) vers un commit. `HEAD` pointe vers la branche courante.

```bash
cat .git/HEAD                      # ref: refs/heads/main
cat .git/refs/heads/main           # empreinte du dernier commit
git cat-file -p HEAD               # contenu de l'objet commit
git cat-file -p HEAD^{tree}        # son arbre
```

## 3. Configuration initiale

```bash
git config --global user.name "Prénom Nom"
git config --global user.email "prenom@exemple.org"
git config --global init.defaultBranch main
git config --global core.editor vim
git config --global pull.rebase false
git config --list --show-origin
```

## 4. Le cycle de base

```bash
git init mon-projet                  # crée un dépôt local
cd mon-projet
echo "# Mon projet" > README.md
git status                           # état des fichiers
git add README.md                    # ajoute à l'index
git commit -m "Ajoute le README"     # enregistre
git log --oneline                    # historique condensé
git log --oneline --graph --all      # avec le graphe des branches
git diff                             # modifications non indexées
git diff --staged                    # modifications indexées
git show HEAD                        # détail du dernier commit
```

### Bons messages de commit

```text
Ajoute la vérification de l'espace disque dans sante.sh

Le script échouait silencieusement quand df renvoyait une valeur vide.
On valide désormais le résultat et on sort avec le code 2.
```

- Une ligne de résumé (≤ 50 caractères), à l'impératif ; ligne vide ; explication du **pourquoi**.
- Un commit = **un changement logique** (atomique).
- Cherchez la convention du projet : *Conventional Commits* (`feat:`, `fix:`, `docs:`).

> 💡 **Conseil** : `git add -p` permet de choisir **morceau par morceau** ce qui entre dans le commit.

### `.gitignore`

```text
*.log
.env
node_modules/
*.swp
```

> ⚠️ **Attention** : ne commitez **jamais** de mot de passe, de clé privée ou de jeton. Même supprimés ensuite, ils restent dans l'historique et doivent être considérés comme compromis (révoquez-les).

## 5. Annuler et corriger

| Situation | Commande |
|---|---|
| Désindexer un fichier | `git restore --staged fichier` |
| Annuler les modifications d'un fichier (**irréversible**) | `git restore fichier` |
| Corriger le **dernier** commit (non publié) | `git commit --amend` |
| Annuler un commit **en créant** un commit inverse (sûr) | `git revert <commit>` |
| Déplacer la branche en arrière | `git reset --soft/--mixed/--hard <commit>` |
| Retrouver un commit « perdu » | `git reflog` |
| Mettre de côté du travail en cours | `git stash` / `git stash pop` |

| `reset` | Déplace la branche | Index | Répertoire de travail |
|---|---|---|---|
| `--soft` | ✅ | conservé | conservé |
| `--mixed` (défaut) | ✅ | réinitialisé | conservé |
| `--hard` | ✅ | réinitialisé | **réinitialisé (perte !)** |

> ⚠️ **Attention** : ne réécrivez **jamais** l'historique déjà publié et partagé (`reset --hard` + `push --force`). Utilisez `git revert`. `git reflog` est votre filet de sécurité local pendant ~90 jours.

## 6. Branches

```bash
git branch                         # liste
git switch -c fonctionnalite/login # crée et bascule
git switch main                    # revient sur main
git branch -d fonctionnalite/login # supprime (si fusionnée)
git branch -D nom                  # supprime de force
```

### Fusionner : `merge` et `rebase`

```text
Avant :              main:  A───B───C
                                 \
                      feature:    D───E

merge (--no-ff) :    A───B───C───────M      (commit de fusion, historique fidèle)
                          \         /
                           D───E───┘

rebase :             A───B───C───D'──E'     (historique linéaire, commits réécrits)
```

```bash
git switch main
git merge fonctionnalite/login         # fusionne dans main
git switch fonctionnalite/login
git rebase main                        # rejoue vos commits sur main
```

> 📌 **À retenir** : *merge* préserve l'historique tel qu'il s'est passé ; *rebase* le rend linéaire mais **réécrit** les commits. Règle d'or : **ne rebasez que des commits non publiés**.

### Résoudre un conflit

Un conflit survient quand deux branches modifient les mêmes lignes.

```text
<<<<<<< HEAD
version de la branche courante
=======
version de la branche fusionnée
>>>>>>> fonctionnalite/login
```

```bash
git status                  # fichiers en conflit
# éditez le fichier : gardez le bon contenu, supprimez les marqueurs
git add fichier
git commit                  # termine la fusion (ou git rebase --continue)
git merge --abort           # abandonner la fusion
```

## 7. Dépôts distants

```bash
git clone https://github.com/utilisateur/projet.git
git remote -v                          # liste des distants
git remote add origin git@github.com:utilisateur/projet.git
git fetch                              # récupère sans fusionner
git pull                               # fetch + merge (ou rebase)
git push -u origin main                # publie et mémorise le suivi
git push origin fonctionnalite/login
git push origin --delete ancienne-branche
```

### Authentification

- **HTTPS + jeton d'accès personnel** (PAT) : simple.
- **SSH** : recommandé. Réutilisez vos compétences du [cours SSH](../../02-linux-intermediaire/cours/04-ssh-cles.md) : `ssh-keygen -t ed25519`, ajoutez la clé **publique** dans les paramètres GitHub, testez avec `ssh -T git@github.com`.

## 8. Workflows d'équipe

| Workflow | Principe | Usage |
|---|---|---|
| **GitHub Flow** | `main` toujours déployable ; branche courte par fonctionnalité ; *pull request* ; fusion | Déploiement continu, équipes web |
| **Gitflow** | `main`, `develop`, `feature/*`, `release/*`, `hotfix/*` | Versions planifiées |
| **Trunk-based** | Intégration quotidienne sur `main`, branches très courtes, *feature flags* | CI/CD mature |

### Cycle d'une *pull request* (GitHub Flow)

```text
1. git switch -c fix/typo-readme
2. modifications + commits
3. git push -u origin fix/typo-readme
4. Ouvrir la Pull Request  ──►  revue de code  ──►  CI automatique (tests)
5. Corrections éventuelles (nouveaux commits)
6. Fusion (merge / squash / rebase) dans main
7. Suppression de la branche
```

Protégez `main` : revue obligatoire, tests CI obligatoires, interdiction du *force push*.

## 9. Étiquettes et versions

```bash
git tag v1.0.0                         # étiquette légère
git tag -a v1.0.1 -m "Correctif"       # étiquette annotée (recommandée)
git push origin --tags
git describe --tags
```

**Versionnage sémantique (SemVer)** : `MAJEUR.MINEUR.CORRECTIF` — majeur : rupture ; mineur : ajout compatible ; correctif : bug.

## 10. Investigation

```bash
git log --oneline --author="Awa" --since="2 weeks ago"
git log -p fichier                     # historique d'un fichier avec diffs
git blame fichier                      # qui a modifié chaque ligne ?
git log -S"motdepasse"                 # trouve les commits ajoutant/supprimant cette chaîne
git bisect start && git bisect bad && git bisect good v1.0.0   # recherche dichotomique d'une régression
git shortlog -sn                       # contributions par auteur
```

## 11. Hooks et automatisation

Les **hooks** sont des scripts exécutés à certains moments (`.git/hooks/`) : `pre-commit` (lint), `commit-msg` (format), `pre-push` (tests).

```bash
cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
# Refuse un commit contenant des scripts Bash non conformes
for f in $(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$'); do
    bash -n "$f" || { echo "Syntaxe invalide : $f"; exit 1; }
done
EOF
chmod +x .git/hooks/pre-commit
```

## Résumé

- Git est **distribué** : objets *blob/tree/commit* ; une branche est un **pointeur**.
- Cycle : `status` → `add` → `commit` ; `diff`, `log --oneline --graph`.
- Annuler sans casser : `restore`, `revert` ; `reset --hard` est destructeur ; `reflog` sauve.
- `merge` préserve l'historique, `rebase` le linéarise (uniquement avant publication).
- Collaboration : `clone`, `fetch`, `pull`, `push`, **pull requests**, branches protégées.
- Jamais de secrets dans un dépôt.

## Pour aller plus loin

- Livre gratuit *Pro Git* (git-scm.com/book/fr/v2), `man gittutorial`, `man gitworkflows`.
- *Conventional Commits*, `git rebase -i`, `git worktree`, *submodules*.
- GitHub Actions / GitLab CI (voir [CI/CD](03-ci-cd-principes.md)).
- Atelier associé : [Git et branches](../ateliers/atelier-01-git-branches.md).
- Cours suivant : [Docker, fondamentaux](02-docker-fondamentaux.md).
