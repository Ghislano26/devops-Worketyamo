# Bravo !

Vous avez enchaîné toute la logique d'un SLO :

| Étape | Résultat |
|---|---|
| SLI | 99,85 % sur 7 jours (`increase()` sur un *counter*) |
| SLO | 99,9 % sur 30 jours, décrit dans `slo.yml` |
| Budget d'erreur | 43,2 min au total ; **50 % restants = 21,6 min** sur le jeu de 30 jours |
| Décision | Politique écrite : release si budget > 0, gel sinon |

Et vous avez **testé vos règles** avec `promtool test rules`, comme on le fait en CI.

## Défi bonus : un SLO pour un service réel

Choisissez un service que vous connaissez (le vôtre, une API publique) et :

1. décrivez son **parcours critique** et choisissez **un SLI** (disponibilité ou latence) ;
2. fixez un **objectif réaliste** en partant de l'historique (pas « cinq neuf » par principe) ;
3. calculez le **budget en minutes** pour 30 jours ;
4. écrivez la **politique** de budget et faites-la lire à un collègue.

## Pour aller plus loin

- [SLI, SLO et error budget](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/02-slo-sli-error-budget.md) · [PromQL](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/03-promql-et-metriques.md) · [Alertes et burn rate](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/05-alertmanager-alertes.md).
- Alertes **multi-fenêtres de burn rate** (14,4 / 6 / 1), outils **Sloth** et **Pyrra**.
- Suite : [atelier 2 — postmortem blameless](https://github.com/Ghislano26/devops-Worketyamo/tree/main/11-sre-pratiques/ateliers-killercoda/atelier-02-postmortem-blameless).
