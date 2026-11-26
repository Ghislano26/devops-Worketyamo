# Atelier 02 — `awk`, `sed` et `grep` : enquête sur des journaux

## 🎯 Objectifs

- Filtrer des journaux avec `grep` et des expressions régulières.
- Transformer des fichiers de configuration avec `sed` en toute sécurité.
- Extraire, compter et calculer avec `awk`.
- Produire un rapport d'incident chiffré à partir de journaux bruts.

## 📋 Prérequis

- Atelier [01 — Scripts](atelier-01-scripts-automatisation.md) terminé.
- Cours lu : [Traitement de texte avancé](../cours/02-traitement-texte-avance.md).

## 🧪 Scénario

Le site web de *Kamer Logistics* a été lent hier soir, et le responsable sécurité soupçonne une attaque par
force brute sur SSH. On vous remet un extrait des journaux d'accès web et d'authentification. Vous devez
répondre à ces questions : **qui a généré le plus de trafic ? quelles pages ont échoué ? quelle IP a attaqué SSH ?
quel volume de données a été servi ?**

## Préparation : fabriquer les journaux

```bash
mkdir -p ~/atelier-texte && cd ~/atelier-texte

cat > access.log <<'EOF'
192.168.1.10 - - [23/Nov/2025:21:00:01 +0000] "GET /index.html HTTP/1.1" 200 1500
192.168.1.11 - - [23/Nov/2025:21:00:05 +0000] "GET /produits.html HTTP/1.1" 200 3200
203.0.113.7 - - [23/Nov/2025:21:01:10 +0000] "POST /login HTTP/1.1" 401 210
203.0.113.7 - - [23/Nov/2025:21:01:12 +0000] "POST /login HTTP/1.1" 401 210
203.0.113.7 - - [23/Nov/2025:21:01:15 +0000] "POST /login HTTP/1.1" 401 210
192.168.1.10 - - [23/Nov/2025:21:02:00 +0000] "GET /panier.html HTTP/1.1" 200 2800
198.51.100.4 - - [23/Nov/2025:21:02:30 +0000] "GET /admin HTTP/1.1" 403 180
192.168.1.12 - - [23/Nov/2025:21:03:01 +0000] "GET /api/colis/42 HTTP/1.1" 500 95
192.168.1.12 - - [23/Nov/2025:21:03:05 +0000] "GET /api/colis/43 HTTP/1.1" 500 95
192.168.1.11 - - [23/Nov/2025:21:04:00 +0000] "GET /contact.html HTTP/1.1" 404 120
192.168.1.10 - - [23/Nov/2025:21:05:00 +0000] "GET /index.html HTTP/1.1" 200 1500
192.168.1.13 - - [23/Nov/2025:21:05:20 +0000] "GET /produits.html HTTP/1.1" 200 3200
EOF

cat > auth.log <<'EOF'
Nov 23 21:00:10 srv sshd[1201]: Failed password for root from 203.0.113.7 port 51022 ssh2
Nov 23 21:00:12 srv sshd[1203]: Failed password for root from 203.0.113.7 port 51024 ssh2
Nov 23 21:00:14 srv sshd[1205]: Failed password for invalid user admin from 203.0.113.7 port 51026 ssh2
Nov 23 21:00:20 srv sshd[1207]: Failed password for invalid user test from 198.51.100.4 port 40110 ssh2
Nov 23 21:00:40 srv sshd[1210]: Accepted publickey for etudiant from 192.168.1.10 port 52000 ssh2
Nov 23 21:01:02 srv sshd[1212]: Failed password for root from 203.0.113.7 port 51030 ssh2
Nov 23 21:01:20 srv sshd[1215]: Failed password for ubuntu from 203.0.113.7 port 51034 ssh2
Nov 23 21:02:00 srv sudo: etudiant : TTY=pts/0 ; PWD=/home/etudiant ; USER=root ; COMMAND=/usr/bin/apt update
EOF

cat > sshd_config.test <<'EOF'
# Configuration de test
Port 22
PermitRootLogin yes
PasswordAuthentication yes

#X11Forwarding yes
MaxAuthTries 6
EOF

cat > ventes.csv <<'EOF'
region,produit,quantite,prix
Douala,riz,100,500
Yaounde,riz,80,500
Douala,huile,40,1200
Yaounde,huile,60,1200
Douala,sucre,70,700
EOF
wc -l *.log *.csv
```

## Étapes

### Partie A — `grep` : trouver

```bash
grep "404" access.log                          # contient 404
grep -c " 200 " access.log                     # nombre de succès
grep -v " 200 " access.log                     # tout sauf les succès
grep -E '" (4|5)[0-9]{2} ' access.log          # codes 4xx et 5xx
grep -n "POST" access.log                      # avec numéros de ligne
grep -oE "^[0-9]{1,3}(\.[0-9]{1,3}){3}" access.log | sort -u     # IP uniques
grep -B1 -A1 "500" access.log                  # contexte autour des erreurs 500
```

> ❓ **Question 1** : Quelle différence entre `grep "404"` et `grep ' 404 '` ? Quel faux positif pourrait produire la première forme ?

### Partie B — `awk` : extraire et compter

```bash
awk '{print $1}' access.log | sort | uniq -c | sort -nr          # trafic par IP (méthode pipe)
awk '{c[$1]++} END {for (ip in c) print c[ip], ip}' access.log | sort -nr   # même résultat en awk pur
awk '{c[$9]++} END {for (k in c) print k, c[k]}' access.log | sort          # codes HTTP
awk '{s += $10} END {printf "Volume servi : %.2f Ko\n", s/1024}' access.log
awk '$9 >= 500 {print $1, $7, $9}' access.log                    # erreurs serveur
awk '$9 == 401 {c[$1]++} END {for (ip in c) if (c[ip] >= 3) print "SUSPECT :", ip, c[ip]}' access.log
```

> ❓ **Question 2** : Pourquoi `$9` et `$10` ? Numérotez à la main les champs de la première ligne pour le vérifier.
> ❓ **Question 3** : Que fait `c[$1]++` ? À quelle clause SQL est-ce comparable ?

### Partie C — SSH : identifier l'attaquant

```bash
grep "Failed password" auth.log | wc -l
grep "Failed password" auth.log | grep -oE "from [0-9.]+" | cut -d' ' -f2 | sort | uniq -c | sort -nr
grep "invalid user" auth.log | awk '{print $11}' | sort -u            # noms testés
awk '/Accepted/ {print $9, "depuis", $11}' auth.log                   # connexions légitimes
```

> ❓ **Question 4** : Quelle IP concentre le plus de tentatives ? Quels comptes visait-elle ?

### Partie D — `sed` : transformer sans casser

Toujours **tester sans `-i`** d'abord.

```bash
sed 's/PermitRootLogin yes/PermitRootLogin no/' sshd_config.test           # aperçu seulement
diff sshd_config.test <(sed 's/PermitRootLogin yes/PermitRootLogin no/' sshd_config.test)
cp sshd_config.test sshd_config.work
sed -i.bak -e 's/^PermitRootLogin.*/PermitRootLogin no/' \
           -e 's/^PasswordAuthentication.*/PasswordAuthentication no/' sshd_config.work
diff sshd_config.work.bak sshd_config.work
sed '/^#/d;/^$/d' sshd_config.work                                         # sans commentaires ni lignes vides
sed -n '2,4p' sshd_config.work                                             # lignes 2 à 4
sed 's/^#\(X11Forwarding\) yes/\1 no/' sshd_config.work                    # groupe capturé \1
```

> ❓ **Question 5** : Pourquoi `s/^PermitRootLogin.*/…/` est-il plus robuste que `s/PermitRootLogin yes/…/` ? Que se passerait-il si la valeur d'origine était `without-password` ?
> ❓ **Question 6** : À quoi sert l'option `-i.bak` ?

### Partie E — Combiner : analyse d'un CSV

```bash
awk -F, 'NR>1 {t[$1] += $3 * $4} END {for (r in t) print r, t[r]}' ventes.csv          # CA par région
awk -F, 'NR>1 {q[$2] += $3} END {for (p in q) print p, q[p]}' ventes.csv | sort -k2 -nr # quantité par produit
awk -F, 'NR>1 && $3*$4 > 50000 {print $1, $2, $3*$4}' ventes.csv                       # grosses ventes
column -t -s, ventes.csv
```

### Partie F — Le rapport d'incident

```bash
{
  echo "=== Rapport d'incident du 23/11/2025 ==="
  echo "Requêtes totales : $(wc -l < access.log)"
  echo "Erreurs 4xx/5xx  : $(awk '$9 >= 400' access.log | wc -l)"
  echo "IP la plus active : $(awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -1)"
  echo "Tentatives SSH échouées : $(grep -c 'Failed password' auth.log)"
  echo "IP la plus agressive : $(grep 'Failed password' auth.log | grep -oE 'from [0-9.]+' | sort | uniq -c | sort -nr | head -1)"
  echo "Volume servi : $(awk '{s+=$10} END {printf "%.1f Ko", s/1024}' access.log)"
} | tee rapport.txt
```

## ✅ Validation

- [ ] Le nombre de réponses `200` vaut **5**.
- [ ] Les codes HTTP comptés : 200 → 5, 401 → 3, 403 → 1, 404 → 1, 500 → 2.
- [ ] L'IP suspecte repérée en 401 est **203.0.113.7**, avec 3 tentatives.
- [ ] Il y a **6** `Failed password` dans `auth.log`, dont 5 depuis `203.0.113.7`.
- [ ] `sshd_config.work` contient `PermitRootLogin no` et `PasswordAuthentication no`, et `sshd_config.work.bak` conserve l'original.
- [ ] Le CA de Douala est **147 000** (`100×500 + 40×1200 + 70×700`).
- [ ] `rapport.txt` est généré.

## 💡 Pour aller plus loin

- **Défi 1** : produisez un classement des pages les plus demandées avec leur taille totale servie.
- **Défi 2** : écrivez un script `detecte-brute-force.sh` qui lit `auth.log` et affiche les IP avec plus de 3 échecs.
- **Défi 3** : avec `sed`, anonymisez les IP des journaux (`s/[0-9]\+\.[0-9]\+$/X.X/`) avant de les partager.
- **Défi 4** : travaillez sur le vrai `/var/log/auth.log` de la VM : `sudo grep -c "session opened" /var/log/auth.log`.

---

## 🏆 Défi du jour

**Objectif** : Analyser un journal web avec `awk`, `grep` et `sed`, puis l'**anonymiser** avant de le partager.

**Contexte** : Un prestataire externe doit analyser ton trafic, mais tu n'as pas le droit de lui transmettre les adresses IP complètes des visiteurs. Tu dois lui fournir un résumé chiffré et une version anonymisée du journal.

**Consignes** :
- Crée le fichier de test :
  ```bash
  mkdir -p ~/defi-texte && cd ~/defi-texte
  cat > acces.log <<'EOF'
10.0.0.5 GET /a 200
10.0.0.7 GET /b 404
10.0.0.5 POST /login 401
10.0.0.9 GET /a 200
10.0.0.5 GET /c 500
10.0.0.7 GET /a 200
10.0.0.9 POST /login 401
10.0.0.5 GET /a 200
10.0.0.12 GET /b 404
10.0.0.7 GET /c 200
10.0.0.9 GET /a 200
10.0.0.5 GET /b 200
  EOF
  ```
- `awk` : écris dans `resume.txt` l'**IP la plus active** avec son nombre de requêtes (format `NOMBRE IP`).
- `awk` : ajoute à `resume.txt` une ligne `Erreurs : N sur 12 (P %)` où N est le nombre de requêtes dont le code (4e champ) est **≥ 400**, et P le pourcentage arrondi à une décimale.
- `sed` : produis `acces-anonyme.log` où le **dernier octet** de chaque IP est remplacé par `x` (`10.0.0.5` → `10.0.0.x`).
- `grep` : affiche (sans fichier) le nombre de lignes `POST` dans `acces.log`.

**Indices** (à consulter seulement si bloqué) :
- `awk '{c[$1]++} END {for (i in c) print c[i], i}' acces.log | sort -nr | head -n 1`.
- `awk '$4 >= 400 {n++} END {printf "Erreurs : %d sur %d (%.1f %%)\n", n, NR, 100*n/NR}' acces.log`.
- `sed 's/\.[0-9]* / x /'` ne convient pas tel quel : cible le **dernier** nombre de la première colonne, par ex. `sed 's/^\([0-9]*\.[0-9]*\.[0-9]*\)\.[0-9]*/\1.x/'`.

**Critères de réussite** :
- [ ] `resume.txt` contient la ligne `5 10.0.0.5`.
- [ ] `resume.txt` contient `Erreurs : 5 sur 12 (41.7 %)`.
- [ ] `acces-anonyme.log` ne contient plus aucune adresse complète (`grep -E '10\.0\.0\.[0-9]+ ' acces-anonyme.log` ne renvoie rien).
- [ ] `grep -c POST acces.log` affiche `2`.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
cd ~/defi-texte
awk '{c[$1]++} END {for (i in c) print c[i], i}' acces.log | sort -nr | head -n 1 > resume.txt
awk '$4 >= 400 {n++} END {printf "Erreurs : %d sur %d (%.1f %%)\n", n, NR, 100*n/NR}' acces.log >> resume.txt
sed 's/^\([0-9]*\.[0-9]*\.[0-9]*\)\.[0-9]*/\1.x/' acces.log > acces-anonyme.log
grep -c POST acces.log

cat resume.txt           # 5 10.0.0.5   puis   Erreurs : 5 sur 12 (41.7 %)
head -n 3 acces-anonyme.log
```

`awk` compte avec un tableau associatif (équivalent d'un `GROUP BY`) ; `sed` capture les trois premiers octets dans un groupe `\(...\)` et les réutilise avec `\1` ; `grep -c` compte les lignes correspondantes.

</details>

---

Atelier suivant : [LVM](atelier-03-lvm.md).
