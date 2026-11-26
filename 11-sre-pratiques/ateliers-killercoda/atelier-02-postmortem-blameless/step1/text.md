# Étape 1 : de notes brutes à un postmortem

Le fichier `~/postmortem/incident.md` contient les **notes brutes** d'un incident fictif (chronologie du scribe et constats après coup). Lisez-le :

```bash
cat ~/postmortem/incident.md
```{{exec}}

Votre mission : produire **`~/postmortem/postmortem.md`**, un postmortem **structuré** (voir le [cours 04](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/04-postmortem-blameless.md)) avec **exactement** ces sections de niveau 2 :

| Section | Contenu attendu |
|---|---|
| `## Résumé` | 3 à 5 phrases : quoi, impact, cause principale, correctif |
| `## Impact` | Chiffré : part des requêtes, durée, budget d'erreur consommé |
| `## Chronologie` | **Faits horodatés**, un par ligne au format `- HH:MM  fait` (au moins 6 lignes), **sans interprétation** |
| `## Causes` | Cause immédiate et facteurs, **décrits sur le système** |
| `## Actions` | **Au moins 3 actions** au format ci-dessous |

Format **obligatoire** d'une action (une par ligne) :

```text
- [ ] <description de l'action> | propriétaire: <équipe ou rôle> | échéance: AAAA-MM-JJ
```

> **Règle blameless** : n'écrivez **aucun nom de personne** (ni Jean, ni Awa, ni Binta, ni Marc) : utilisez des **rôles** (« l'ingénieur d'astreinte », « l'Incident Commander », « l'équipe API »).

Un squelette pour démarrer :

```bash
cat > ~/postmortem/postmortem.md <<'EOF'
# Postmortem — Incident #214 : échec des paiements après le déploiement 2.31

## Résumé
(à écrire en dernier : 3 à 5 phrases)

## Impact
- (chiffres : part des requêtes en échec, durée, budget d'erreur)

## Chronologie
- 14:02  (fait)

## Causes
- Cause immédiate : (…)
- (…)

## Actions
- [ ] (…) | propriétaire: (…) | échéance: 2025-12-12
EOF
nano ~/postmortem/postmortem.md
```{{exec}}

> Une bonne action est **précise, mesurable, assignée et datée** ; « faire plus attention » n'est **pas** une action.

Cliquez sur **Vérifier**.
