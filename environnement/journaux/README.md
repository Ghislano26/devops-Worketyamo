# journaux/ — ton journal d'installation

## Principe

Chaque étudiant **documente la construction de sa propre VM** dans un fichier à son nom :

```bash
cd environnement/journaux
cp TEMPLATE.md <pseudo>.md          # par exemple : cp TEMPLATE.md awa.md
```

Puis il le remplit **au fur et à mesure** de l'installation (pas à la fin, de mémoire) : date et heure de chaque étape, statut, durée de `make up`, et surtout **chaque problème rencontré avec sa solution**.

## Pourquoi un journal de bord ?

- **Livrable du cours** : le journal est **à rendre au formateur**. Il montre que tu as réellement construit ta VM et que tu sais diagnostiquer.
- **Traçabilité** : chaque étudiant construit sa VM avec une machine, un système et des versions différentes (« divergence contrôlée »). Le journal permet de **comprendre une panne** en comparant les environnements.
- **Mémoire personnelle** : à la prochaine réinstallation (nouvel ordinateur, VM cassée), tu retrouves ce qui a marché.
- **Entraînement professionnel** : tenir un journal d'intervention est un réflexe d'administrateur système.

## Ce qu'on attend d'un bon journal

| ✅ Utile | ❌ Inutile |
|---|---|
| « `make up` s'est arrêté à `01-base` : `Could not resolve host`. VPN d'entreprise coupé → relancé : OK » | « Ça n'a pas marché, puis ça a marché » |
| Le message d'erreur **copié tel quel** | Une capture d'écran illisible |
| La commande de **diagnostic** et la **source** de la solution (forum, doc, camarade) | Une solution sans explication |
| Les versions (`VBoxManage --version`, `vagrant --version`, `vagrant box list`) | Rien sur ton système |

## Où le ranger et le rendre ?

- Le fichier est `environnement/journaux/<pseudo>.md` (un fichier **par étudiant**, jamais le `TEMPLATE.md` modifié).
- **Bonne pratique** : fais un **fork** du dépôt et commite ton journal **dans ton fork**. Ne l'envoie **pas** dans le dépôt principal : des dizaines de journaux au même endroit provoqueraient des conflits et mélangeraient les travaux.
- Pour le rendre : donne le lien vers ton fichier (fork) ou envoie le fichier au formateur, selon la consigne donnée en classe.

> 💡 **Conseil** : ne mets **jamais** de mot de passe, de jeton ou de clé privée dans ton journal.
