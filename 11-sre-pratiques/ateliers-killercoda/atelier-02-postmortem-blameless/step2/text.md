# Étape 2 : « pourquoi le système l'a-t-il permis ? »

## A. Les facteurs contributifs

Dans un système complexe, une panne n'a presque jamais **une** cause : elle résulte de **plusieurs facteurs** qui se combinent. Créez **`~/postmortem/facteurs-contributifs.md`** listant au moins **4 facteurs**, **décrits sur le système** (jamais sur une personne), classés par catégorie :

| Catégorie | Question à se poser |
|---|---|
| **Déclencheur** | Quel changement a lancé l'incident ? |
| **Vulnérabilité latente** | Quel défaut existait déjà dans le système ? |
| **Détection** | Pourquoi n'a-t-on pas détecté plus tôt ? |
| **Réponse / mitigation** | Qu'est-ce qui a ralenti la remise en service ? |
| **Prévention** | Quel garde-fou aurait empêché ou limité l'incident ? |

```bash
cat > ~/postmortem/facteurs-contributifs.md <<'EOF'
## Facteurs contributifs

- **Déclencheur** : (…)
- **Vulnérabilité latente** : (…)
- **Détection** : (…)
- **Réponse** : (…)
- **Prévention** : (…)
EOF
nano ~/postmortem/facteurs-contributifs.md
```{{exec}}

Chaque ligne doit commencer par `- **Catégorie** :` et être **factuelle** (lisez les « constats après coup » de `incident.md`).

## B. Réécrire une phrase blâmante

Voici une phrase typique d'un compte rendu **avec blâme** :

> *« Jean a causé la panne en déployant sans vérifier les alertes, et Awa est responsable du retard car elle ne connaissait pas la commande de rollback. »*

Réécrivez-la en **version blameless** dans **`~/postmortem/reformulation.txt`** (une ou deux phrases) :

- **aucun nom de personne** ;
- ni « a causé », ni « est responsable » ;
- elle décrit **ce que le système permettait ou n'empêchait pas** (processus, pipeline, documentation, garde-fous).

```bash
echo "(votre reformulation ici)" > ~/postmortem/reformulation.txt
nano ~/postmortem/reformulation.txt
cat ~/postmortem/reformulation.txt
```{{exec}}

> Exemple d'esprit (à ne pas recopier) : *« Le pipeline de déploiement ne vérifiait pas … »*.

## Questions

- Pourquoi « erreur humaine » ne doit-elle **jamais** être la cause racine ? (Parce que le système aurait dû empêcher, détecter ou limiter l'erreur : cherchez le garde-fou manquant.)
- Que se passe-t-il dans une équipe où l'on blâme ? (Les gens cachent les erreurs : on perd l'information qui permet d'améliorer.)

Cliquez sur **Vérifier**.
