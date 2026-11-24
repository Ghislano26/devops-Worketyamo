# Navigation et commandes de base

## Pourquoi ce cours ?

Se déplacer, créer, copier, déplacer, lire et chercher des fichiers : ces gestes représentent
80 % de votre quotidien sur un serveur. Ce cours vous donne le vocabulaire, mais aussi la
mécanique du shell (redirections, pipes) qui fait la puissance de la console.

## 1. Se repérer et se déplacer

```bash
pwd                  # affiche le répertoire courant (Print Working Directory)
cd /var/log          # se déplacer (chemin absolu)
cd ..                # remonter d'un niveau
cd                   # retour au dossier personnel (équivaut à cd ~)
cd -                 # retour au répertoire précédent
ls                   # lister
ls -l                # format long : droits, propriétaire, taille, date
ls -a                # inclut les fichiers cachés
ls -lh               # tailles lisibles (K, M, G)
ls -lt               # tri par date de modification (récent en premier)
ls -lS               # tri par taille
ls -R                # récursif
tree -L 2 /etc       # arborescence sur 2 niveaux (paquet tree)
```

Lecture d'une ligne `ls -l` :

```text
-rw-r--r-- 1 etudiant etudiant 1420 nov. 24 10:12 notes.txt
│└─┬──┘   │    │         │       │       │          └ nom
│  │      │    │         │       │       └ date de modification
│  │      │    │         │       └ taille en octets
│  │      │    │         └ groupe propriétaire
│  │      │    └ utilisateur propriétaire
│  │      └ nombre de liens physiques
│  └ droits (propriétaire/groupe/autres)
└ type
```

## 2. Créer et organiser

```bash
mkdir projets                  # créer un dossier
mkdir -p projets/web/css       # -p : crée toute la chaîne, sans erreur si existe
touch fichier.txt              # crée un fichier vide (ou met à jour sa date)
cp source.txt copie.txt        # copier un fichier
cp -r dossier/ sauvegarde/     # copier un dossier (-r récursif)
cp -a dossier/ sauvegarde/     # copie « archive » : conserve droits, dates, liens
mv ancien.txt nouveau.txt      # renommer
mv fichier.txt ~/projets/      # déplacer
rm fichier.txt                 # supprimer un fichier
rm -r dossier/                 # supprimer un dossier et son contenu
rmdir dossier-vide             # supprime un dossier vide uniquement
```

> ⚠️ **Attention** : **il n'y a pas de corbeille** en ligne de commande. `rm` est définitif.
> Prenez l'habitude de `rm -i` (confirmation) et ne lancez jamais `rm -rf` avec une variable ou un chemin que vous n'avez pas relu. `rm -rf /` ou `rm -rf ~ ` sont des catastrophes.

> 💡 **Conseil** : `mv` et `cp` écrasent silencieusement la destination. Ajoutez `-i` (interactif) ou `-n` (ne pas écraser).

## 3. Lire le contenu d'un fichier

```bash
cat fichier.txt           # affiche tout
cat -n fichier.txt        # avec numéros de ligne
less /var/log/syslog      # lecture paginée (q quitter, / chercher, G fin, g début)
head -n 5 fichier.txt     # 5 premières lignes
tail -n 5 fichier.txt     # 5 dernières lignes
tail -f /var/log/syslog   # suit le fichier en direct (Ctrl+C pour arrêter)
wc -l fichier.txt         # nombre de lignes (-w mots, -c octets)
```

## 4. Entrées/sorties : flux et redirections

Chaque programme dispose de trois **flux** standard :

| Flux | Numéro | Rôle | Par défaut |
|---|---|---|---|
| `stdin` | 0 | Entrée | Clavier |
| `stdout` | 1 | Sortie normale | Écran |
| `stderr` | 2 | Messages d'erreur | Écran |

```bash
echo "bonjour" > a.txt          # > redirige stdout vers un fichier (ÉCRASE)
echo "suite"  >> a.txt          # >> ajoute à la fin
wc -l < a.txt                   # < lit l'entrée depuis un fichier
ls /inexistant 2> erreurs.txt   # 2> redirige stderr
ls /etc /inexistant > sortie.txt 2> erreurs.txt
ls /etc /inexistant > tout.txt 2>&1   # stdout ET stderr dans le même fichier
ls /inexistant 2> /dev/null     # jeter les erreurs (/dev/null = trou noir)
```

> 📌 **À retenir** : `2>&1` signifie « envoie stderr là où va déjà stdout ». L'ordre compte : `> fichier 2>&1`, et non l'inverse.

## 5. Les tubes (*pipes*)

Le symbole `|` branche la sortie d'une commande sur l'entrée de la suivante. C'est l'application directe de la philosophie Unix.

```text
cmd1  ──stdout──►  |  ──stdin──►  cmd2  ──stdout──►  |  ──►  cmd3
```

```bash
ls /etc | wc -l                         # combien d'éléments dans /etc ?
ls -l /etc | less                       # paginer une longue sortie
cat /etc/passwd | cut -d: -f1 | sort    # liste triée des noms d'utilisateurs
history | grep ssh | tail -3            # dernières commandes contenant « ssh »
ls -l | tee liste.txt | wc -l           # tee : écrit dans un fichier ET passe au suivant
```

## 6. Rechercher

### `grep` : chercher dans le contenu

```bash
grep "root" /etc/passwd              # lignes contenant « root »
grep -i "erreur" fichier.log         # insensible à la casse
grep -n "ssh" /etc/services          # avec numéro de ligne
grep -v "^#" /etc/ssh/sshd_config    # -v : inverse (exclut les commentaires)
grep -r "PermitRootLogin" /etc/ssh   # récursif
grep -c "nologin" /etc/passwd        # compte les lignes
grep -E "^(root|daemon)" /etc/passwd # expressions régulières étendues
```

### `find` : chercher des fichiers

```bash
find /etc -name "*.conf"                    # par nom
find /var/log -type f -size +1M             # fichiers de plus de 1 Mo
find ~ -type d -name "projets"              # dossiers
find /tmp -type f -mtime +7                 # modifiés il y a plus de 7 jours
find . -name "*.tmp" -delete                # recherche puis supprime
find . -name "*.log" -exec wc -l {} \;      # exécute une commande sur chaque résultat
```

### Autres

```bash
which ls              # chemin de l'exécutable
whereis bash          # binaire, sources et manuel
locate sshd_config    # index rapide (sudo updatedb pour rafraîchir)
```

## 7. Manipuler du texte simplement

```bash
sort fichier.txt             # tri alphabétique (-n numérique, -r inverse)
sort fichier.txt | uniq      # supprime les doublons consécutifs
sort | uniq -c | sort -nr    # compte les occurrences, les plus fréquentes d'abord
cut -d: -f1,3 /etc/passwd    # extrait les champs 1 et 3, séparateur « : »
tr 'a-z' 'A-Z' < a.txt       # convertit en majuscules
diff a.txt b.txt             # différences entre deux fichiers
```

## 8. Guillemets et substitution de commandes

```bash
nom="Awa"
echo "Bonjour $nom"          # guillemets doubles : la variable est développée
echo 'Bonjour $nom'          # guillemets simples : texte littéral
echo "Nous sommes le $(date +%d/%m/%Y)"   # $(...) : substitution de commande
```

## 9. Enchaîner les commandes

| Opérateur | Effet |
|---|---|
| `cmd1 ; cmd2` | Exécute les deux, quoi qu'il arrive |
| `cmd1 && cmd2` | Exécute `cmd2` **seulement si** `cmd1` a réussi |
| `cmd1 \|\| cmd2` | Exécute `cmd2` **seulement si** `cmd1` a échoué |
| `cmd &` | Lance en arrière-plan |

```bash
mkdir -p test && cd test && echo "ok"
ls /inexistant || echo "Le dossier n'existe pas"
echo $?     # code de retour de la dernière commande : 0 = succès, autre = échec
```

## Résumé

- Navigation : `pwd`, `cd`, `ls` (+ `-lah`), `tree`.
- Création/suppression : `mkdir -p`, `touch`, `cp`, `mv`, `rm` (**sans corbeille**).
- Lecture : `cat`, `less`, `head`, `tail -f`, `wc`.
- Flux : `>`, `>>`, `<`, `2>`, `2>&1`, `|`.
- Recherche : `grep` (contenu), `find` (fichiers).
- Chaînage : `&&`, `||`, `;` ; le code retour `$?` vaut 0 en cas de succès.

## Pour aller plus loin

- `man find`, `man grep`, `info coreutils`.
- Expressions régulières : `man 7 regex`.
- Prochain cours : [Utilisateurs et permissions](04-utilisateurs-permissions.md).
- Ateliers : [Navigation](../ateliers/atelier-01-navigation.md) et [Gestion de fichiers](../ateliers/atelier-02-gestion-fichiers.md).
