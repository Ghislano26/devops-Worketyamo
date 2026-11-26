# grep, awk et sed

**Durée : ~10 minutes.** Compétence travaillée : filtrer, compter et transformer du texte, le quotidien d'un administrateur (journaux, configurations).

Prérequis : le cours [Traitement de texte avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/03-linux-avance/cours/02-traitement-texte-avance.md).

```text
grep  → TROUVER des lignes
awk   → EXTRAIRE et CALCULER sur des colonnes
sed   → TRANSFORMER des lignes
```

Vérifions les outils :

```bash
grep --version | head -n 1 ; awk --version 2>&1 | head -n 1 ; sed --version | head -n 1
```{{exec}}
