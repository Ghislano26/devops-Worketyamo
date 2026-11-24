# Traitement de texte avancé : `grep`, `sed`, `awk` et expressions régulières

## Pourquoi ce cours ?

Les journaux, fichiers de configuration, sorties de commandes : sous Linux, tout est du **texte**. Savoir
filtrer, extraire et transformer ce texte en une ligne de commande permet d'analyser un incident en quelques
secondes au lieu de faire défiler des milliers de lignes. `grep`, `sed` et `awk` forment le trio de base des
administrateurs.

```text
grep  → TROUVER des lignes
sed   → TRANSFORMER des lignes (substitution, suppression)
awk   → EXTRAIRE et CALCULER sur des colonnes
```

## 1. Expressions régulières (regex)

Une **expression régulière** décrit un motif de texte. Deux dialectes courants : **BRE** (basique, défaut de `grep` et `sed`) et **ERE** (étendue, option `-E`). Utilisez `-E` pour rester lisible.

| Motif | Signification | Exemple |
|---|---|---|
| `.` | Un caractère quelconque | `a.c` → abc, a1c |
| `*` | 0 ou plusieurs du précédent | `ab*` → a, ab, abbb |
| `+` | 1 ou plusieurs (ERE) | `[0-9]+` |
| `?` | 0 ou 1 (ERE) | `colou?r` |
| `^` / `$` | Début / fin de ligne | `^root`, `bash$` |
| `[abc]` / `[^abc]` | Un caractère de / hors de la liste | `[0-9]`, `[^a-z]` |
| <code>&#124;</code> | Alternative (ERE) | <code>erreur&#124;warning</code> |
| `( )` | Groupe (ERE) | `(ab)+` |
| `{n,m}` | Répétitions (ERE) | `[0-9]{1,3}` |
| `\b` | Frontière de mot (GNU) | `\broot\b` |
| `\d` | Non supporté en ERE : utilisez `[0-9]` | |

Classes POSIX : `[[:digit:]]`, `[[:alpha:]]`, `[[:space:]]`, `[[:upper:]]`.

> 💡 **Conseil** : testez vos regex sur un petit exemple avant de les appliquer à un gros fichier. Ne les confondez pas avec les **jokers** du shell (`*.txt`) : ce sont deux syntaxes différentes.

## 2. `grep` en profondeur

```bash
grep "motif" fichier              # lignes correspondantes
grep -i "motif" f                 # insensible à la casse
grep -v "motif" f                 # inverse
grep -n "motif" f                 # numéros de ligne
grep -c "motif" f                 # compte les lignes
grep -o "motif" f                 # n'affiche que la partie correspondante
grep -w "root" f                  # mot entier
grep -x "ligne exacte" f          # ligne entière
grep -E "erreur|fatal" f          # ERE
grep -r "motif" /etc/             # récursif
grep -rl "motif" /etc/ 2>/dev/null   # seulement les noms de fichiers
grep -A2 -B1 "motif" f            # 2 lignes après, 1 avant (contexte)
grep -F "a.b" f                   # chaîne littérale (aucune regex)
grep -q "motif" f && echo "présent"   # silencieux, utile dans les scripts
grep -P '\d{3}-\d{4}' f           # PCRE (Perl) : \d, lookahead...
```

Exemples réalistes :

```bash
grep -E "^[0-9]{1,3}(\.[0-9]{1,3}){3}" acces.log        # lignes qui commencent par une IPv4
grep -oE "[0-9]{1,3}(\.[0-9]{1,3}){3}" acces.log | sort | uniq -c | sort -nr | head
grep -vE '^\s*(#|$)' /etc/ssh/sshd_config                # config sans commentaires ni lignes vides
```

## 3. `sed` : l'éditeur de flux

`sed` lit un flux **ligne par ligne**, applique des commandes, et affiche le résultat. Par défaut, il **ne modifie pas** le fichier.

### Substitution

Syntaxe : `s/motif/remplacement/drapeaux`

```bash
echo "bonjour monde" | sed 's/monde/Linux/'
sed 's/chat/chien/' f.txt              # première occurrence de chaque ligne
sed 's/chat/chien/g' f.txt             # toutes les occurrences (g = global)
sed 's/chat/chien/gI' f.txt            # insensible à la casse (GNU)
sed -E 's/([0-9]+)-([0-9]+)/\2-\1/' f  # groupes capturés : \1, \2
sed 's#/usr/local#/opt#g' f            # autre délimiteur pratique pour les chemins
sed 's/&/[&]/' f                       # & = tout le texte correspondant
```

### Adresses : sur quelles lignes ?

```bash
sed -n '5p' f                 # affiche seulement la ligne 5 (-n = silence)
sed -n '5,10p' f              # lignes 5 à 10
sed -n '$p' f                 # dernière ligne
sed '1d' f                    # supprime la 1re ligne
sed '/^#/d' f                 # supprime les commentaires
sed '/^$/d' f                 # supprime les lignes vides
sed '/debug/s/false/true/' f  # substitue seulement sur les lignes contenant « debug »
sed '2i\Texte inséré avant' f # insère avant la ligne 2
sed '2a\Texte ajouté après' f # ajoute après la ligne 2
sed -n '/début/,/fin/p' f     # plage entre deux motifs
```

### Modification en place

```bash
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i.bak 's/ancien/nouveau/g' fichier     # crée fichier.bak (recommandé)
```

> ⚠️ **Attention** : `sed -i` modifie le fichier sans possibilité d'annulation. Testez d'abord sans `-i`, puis ajoutez `-i.bak`. Sur macOS, la syntaxe diffère (`-i ''`) : ce cours cible Ubuntu.

## 4. `awk` : extraire et calculer

`awk` lit ligne par ligne, découpe chaque ligne en **champs** (`$1`, `$2`, …, `$NF` = dernier, `$0` = ligne entière) et exécute un programme. Structure :

```text
awk 'BEGIN { avant }   motif { action }   END { après }' fichier
```

### Variables intégrées

| Variable | Contenu |
|---|---|
| `$1`…`$NF` | Champs de la ligne |
| `NF` | Nombre de champs |
| `NR` | Numéro de la ligne courante |
| `FS` | Séparateur d'entrée (défaut : blancs) |
| `OFS` | Séparateur de sortie |

### Exemples

```bash
awk '{print $1}' acces.log                   # 1re colonne
awk '{print $1, $NF}' acces.log              # 1re et dernière
awk -F: '{print $1, $3}' /etc/passwd         # séparateur « : »
awk -F: '$3 >= 1000 {print $1}' /etc/passwd  # utilisateurs humains (UID ≥ 1000)
awk '$4 == 404' acces.log                    # filtre sur un champ
awk '/erreur/ {n++} END {print n+0, "erreurs"}' f
awk 'NR>1 && NR<=5' f                        # lignes 2 à 5
awk '{s += $2} END {print "Total :", s}' f   # somme d'une colonne
awk '{s += $2} END {printf "Moyenne : %.2f\n", s/NR}' f
awk '{c[$1]++} END {for (k in c) print c[k], k}' acces.log | sort -nr   # comptage par clé
awk 'BEGIN{OFS=";"} {$1=$1; print}' f        # remplace les blancs par des « ; »
df -h | awk 'NR>1 {gsub("%","",$5); if ($5+0 > 80) print $6, $5"%"}'    # disques > 80 %
```

> 📌 **À retenir** : `awk '{c[$1]++} END {...}'` (tableau associatif) est la recette pour « compter par catégorie ». C'est l'équivalent d'un `GROUP BY` SQL.

## 5. Autres outils complémentaires

```bash
cut -d, -f1,3 data.csv              # colonnes d'un CSV simple
sort -t, -k2 -n data.csv            # tri sur la 2e colonne, numérique
sort -u f                           # tri + dédoublonnage
uniq -c                             # compte les doublons consécutifs
tr -d '\r' < windows.txt > unix.txt # supprime les retours chariot Windows
tr -s ' ' < f                       # compresse les espaces répétés
paste a.txt b.txt                   # fusionne des fichiers colonne par colonne
join f1 f2                          # jointure sur un champ commun (fichiers triés)
column -t -s, data.csv              # affichage en tableau aligné
xargs                               # transforme l'entrée standard en arguments
find . -name "*.log" -print0 | xargs -0 grep -l "ERROR"   # chaîne sûre avec espaces
```

Pour du JSON, utilisez `jq` (`sudo apt install -y jq`) :

```bash
echo '{"nom":"Awa","age":30}' | jq '.nom'
```

## 6. Analyser des journaux : recettes

Fichier de log type (format Apache/nginx *combined*, simplifié) :

```text
192.168.1.10 - - [24/Nov/2025:10:15:32 +0000] "GET /index.html HTTP/1.1" 200 1024
```

```bash
# Top 5 des IP
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -5

# Répartition des codes HTTP (champ 9)
awk '{c[$9]++} END {for (k in c) print k, c[k]}' access.log | sort

# Volume transféré en Mo
awk '{s += $10} END {printf "%.2f Mo\n", s/1024/1024}' access.log

# Pages en erreur 5xx
awk '$9 ~ /^5/ {print $7}' access.log | sort | uniq -c | sort -nr

# Échecs SSH par IP
grep "Failed password" /var/log/auth.log | grep -oE "from [0-9.]+" | sort | uniq -c | sort -nr | head
```

## 7. Pipelines : bonnes pratiques

1. Construisez le pipeline **étape par étape**, en vérifiant la sortie à chaque `|`.
2. Placez les filtres les plus sélectifs (`grep`) en premier pour réduire le volume.
3. Pour `uniq -c`, triez toujours **avant** (`sort | uniq -c`).
4. Utilisez `LC_ALL=C` devant `sort`/`grep` pour accélérer sur de gros fichiers (`LC_ALL=C sort f`).
5. N'utilisez pas `cat f | grep x` : écrivez `grep x f`.

## Résumé

- **Regex** : `.`, `*`, `+`, `?`, `^`, `$`, `[ ]`, `( )`, `{n,m}` ; utilisez `grep -E`.
- **grep** : trouver (`-i -v -n -c -o -r -A -B -q`).
- **sed** : transformer (`s/a/b/g`, `d`, `p`, adresses, `-i.bak`).
- **awk** : colonnes (`$1`, `NF`), conditions, calculs, comptage avec tableaux associatifs.
- Combinez-les par pipes pour analyser logs et configurations.

## Pour aller plus loin

- `man grep`, `man sed`, `info sed`, `man awk` (gawk : *GAWK: Effective AwkProgramming*).
- Expressions régulières interactives (outils en ligne type regex101, mode PCRE).
- `jq` pour JSON, `yq` pour YAML, `miller` (`mlr`) pour CSV.
- Atelier associé : [awk, sed, grep](../ateliers/atelier-02-awk-sed-grep.md).
- Cours suivant : [Stockage et LVM](03-stockage-lvm.md).
