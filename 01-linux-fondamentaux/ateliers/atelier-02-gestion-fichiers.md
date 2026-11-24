# Atelier 02 — Gestion de fichiers, redirections et recherche

## 🎯 Objectifs

- Créer, copier, déplacer et supprimer fichiers et dossiers en toute sécurité.
- Utiliser les redirections (`>`, `>>`, `2>`, `2>&1`) et les pipes.
- Rechercher avec `find` et `grep`.
- Comprendre la différence entre lien physique et lien symbolique.

## 📋 Prérequis

- Atelier [01 — Navigation](atelier-01-navigation.md) terminé.
- Cours lus : [Système de fichiers](../cours/02-systeme-fichiers.md) et [Navigation et commandes de base](../cours/03-navigation-commandes-base.md).

## 🧪 Scénario

L'équipe web de *Kamer Logistics* vous demande de préparer l'arborescence d'un nouveau projet
`site-vitrine`, d'y déposer des fichiers de configuration et des journaux fictifs, puis
d'analyser ces journaux pour savoir quelles pages génèrent des erreurs.

## Étapes

### Étape 1 — Créer l'arborescence

```bash
cd ~
mkdir -p site-vitrine/{src,conf,logs,sauvegardes}
mkdir -p site-vitrine/src/{css,js,images}
tree site-vitrine
```

> ❓ **Question 1** : Pourquoi l'option `-p` est-elle indispensable pour créer `site-vitrine/src/css` d'un coup ?

### Étape 2 — Créer des fichiers

```bash
cd ~/site-vitrine
touch src/index.html src/css/style.css src/js/app.js
echo "<h1>Bienvenue</h1>" > src/index.html
echo "body { margin: 0; }" > src/css/style.css
echo "console.log('ok');" > src/js/app.js
cat > conf/site.conf <<'EOF'
# Configuration du site
nom=site-vitrine
port=8080
debug=false
EOF
cat conf/site.conf
```

> ❓ **Question 2** : Quelle est la différence entre `>` et `>>` ? Testez : `echo "x" > a.txt` deux fois, puis `echo "x" >> a.txt` deux fois, et comptez les lignes avec `wc -l`.

### Étape 3 — Copier, déplacer, renommer

```bash
cp conf/site.conf conf/site.conf.bak            # sauvegarde rapide
cp -r src sauvegardes/src-$(date +%F)           # copie d'un dossier datée
mv conf/site.conf.bak sauvegardes/
mv src/js/app.js src/js/main.js                 # renommage
ls -R sauvegardes
```

> ❓ **Question 3** : Que fait `$(date +%F)` ? Pourquoi est-ce pratique pour nommer des sauvegardes ?

### Étape 4 — Générer des journaux fictifs

```bash
cat > logs/acces.log <<'EOF'
10.0.0.5 GET /index.html 200
10.0.0.7 GET /produits.html 200
10.0.0.5 GET /contact.html 404
10.0.0.9 POST /login 500
10.0.0.7 GET /produits.html 200
10.0.0.9 POST /login 500
10.0.0.12 GET /index.html 200
10.0.0.5 GET /admin 403
10.0.0.9 POST /login 401
10.0.0.12 GET /panier.html 404
EOF
wc -l logs/acces.log
```

### Étape 5 — Analyser avec `grep`, `cut`, `sort`, `uniq`

```bash
grep " 404" logs/acces.log                    # lignes en erreur 404
grep -c " 500" logs/acces.log                 # combien d'erreurs 500 ?
grep -v " 200" logs/acces.log                 # tout sauf les succès
cut -d' ' -f1 logs/acces.log | sort | uniq -c | sort -nr     # IP les plus actives
cut -d' ' -f3 logs/acces.log | sort | uniq -c | sort -nr     # pages les plus demandées
```

> ❓ **Question 4** : Pourquoi faut-il `sort` **avant** `uniq -c` ? Essayez sans `sort` et comparez.

### Étape 6 — Séparer sortie normale et erreurs

```bash
ls ~/site-vitrine conf-inexistant                      # mélange sortie et erreur
ls ~/site-vitrine conf-inexistant > ~/ok.txt 2> ~/err.txt
cat ~/ok.txt
cat ~/err.txt
ls ~/site-vitrine conf-inexistant > ~/tout.txt 2>&1
```

> ❓ **Question 5** : Dans quel fichier atterrit le message « No such file or directory » à la dernière commande ? Pourquoi ?

### Étape 7 — Rechercher avec `find`

```bash
cd ~/site-vitrine
find . -name "*.html"
find . -type f -size -1k                       # fichiers de moins de 1 Ko
find . -type d                                 # tous les dossiers
find . -name "*.conf*" -exec ls -l {} \;       # détails des fichiers de conf
grep -r "port" conf/                           # recherche dans le contenu
```

### Étape 8 — Liens physique et symbolique

```bash
cd ~/site-vitrine/conf
ln site.conf site-dur.conf
ln -s site.conf site-sym.conf
ls -li
rm site.conf
cat site-dur.conf          # fonctionne ?
cat site-sym.conf          # fonctionne ?
ls -l                      # le lien symbolique apparaît cassé
```

> ❓ **Question 6** : Pourquoi `site-dur.conf` fonctionne encore après suppression de `site.conf`, alors que `site-sym.conf` est cassé ?
> Retrouvez la réponse dans la section « Liens » du [cours sur le système de fichiers](../cours/02-systeme-fichiers.md).

Restaurez : `cp site-dur.conf site.conf && rm site-sym.conf`.

### Étape 9 — Suppression prudente

```bash
cd ~/site-vitrine
rm -i sauvegardes/site.conf.bak        # confirmation demandée
ls sauvegardes
rm -r sauvegardes/src-*                # supprime la copie datée
```

> ⚠️ **Attention** : relisez toujours votre commande `rm -r` avant `Entrée`. Avec des jokers, faites d'abord un `ls` avec le même motif.

## ✅ Validation

- [ ] `tree ~/site-vitrine` montre `src/{css,js,images}`, `conf`, `logs`, `sauvegardes`.
- [ ] `src/js/main.js` existe (et `app.js` n'existe plus).
- [ ] `grep -c " 404" logs/acces.log` affiche **2**.
- [ ] `grep -c " 500" logs/acces.log` affiche **2**.
- [ ] L'IP la plus active est `10.0.0.5` ou `10.0.0.9` (3 requêtes chacune).
- [ ] `~/err.txt` contient un message d'erreur et `~/ok.txt` n'en contient pas.
- [ ] Vous pouvez expliquer pourquoi le lien physique survit à la suppression.

## 💡 Pour aller plus loin

- **Défi 1** : écrivez une seule ligne qui affiche les 3 pages ayant produit le plus d'erreurs (codes 4xx/5xx).
- **Défi 2** : avec `find`, supprimez tous les fichiers `.bak` de plus de 7 jours (testez d'abord sans `-delete`).
- **Défi 3** : utilisez `tee` pour afficher à l'écran et enregistrer dans `rapport.txt` le résultat d'un `grep`.
- **Défi 4** : créez 20 fichiers vides d'un coup avec `touch fichier{01..20}.txt`, puis supprimez uniquement les pairs.

Atelier suivant : [Permissions](atelier-03-permissions.md).
