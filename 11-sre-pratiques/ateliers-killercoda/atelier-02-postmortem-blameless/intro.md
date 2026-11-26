# Postmortem blameless

**Durée : ~25 minutes.** Compétence travaillée : transformer une panne en **apprentissage**, sans chercher de coupable.

Rappel du [cours Postmortem blameless](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/04-postmortem-blameless.md) :

```text
Postmortem = en-tête → résumé → impact chiffré → chronologie factuelle → causes et facteurs contributifs
             → ce qui a bien/mal fonctionné → actions SMART (propriétaire, échéance) → publication → suivi
Blameless  = on cherche les FAIBLESSES DU SYSTÈME, jamais un coupable
```

## Mise en place : l'incident fictif

Ce script crée le dossier `~/postmortem` avec les **notes brutes** d'un incident (déploiement défectueux, paiements en échec pendant 28 minutes) :

```bash
mkdir -p ~/postmortem && cd ~/postmortem
cat > incident.md <<'EOF'
# Incident #214 — notes brutes (prises par le scribe)

Date : 2025-11-24 (heures en UTC)
Service touché : API commandes et paiement du site e-commerce « Kamer Shop »

## Notes brutes

- 14:02  Jean déploie la version 2.31 de l'API commandes (pipeline automatique, 100 % des instances d'un coup).
- 14:05  Le taux d'erreurs 5xx passe de 0,1 % à 38 % (dashboard « API commandes »).
- 14:08  L'alerte ErrorBudgetBurn se déclenche ; Awa (astreinte) est paginée.
- 14:11  Awa accuse réception, constate que les paiements échouent, déclare un SEV1 et ouvre le canal #inc-214.
- 14:15  Binta est nommée Incident Commander ; Marc publie un premier message sur la status page.
- 14:22  Awa trouve dans les journaux : « pool de connexions à la base épuisé ». Hypothèse : le déploiement de 14:02.
- 14:26  Binta décide de faire un rollback vers la version 2.30.
- 14:33  Rollback terminé ; le taux d'erreurs redescend.
- 14:47  Taux d'erreurs sous 0,1 % depuis 15 minutes : incident résolu. Marc publie le message final.

## Constats après coup

- La version 2.31 ouvre une connexion à la base par requête sans la libérer (fuite), ce qui épuise le pool en quelques minutes sous charge réelle.
- Aucun test de charge ne couvre le pool de connexions ; les tests d'intégration passent car le trafic y est faible.
- Le déploiement s'est fait sur 100 % des instances en même temps : pas de déploiement progressif (canary).
- Il n'existe pas d'alerte sur la saturation du pool de connexions ; la détection s'est faite via le taux d'erreurs, 3 minutes après le début.
- Le runbook « rollback de l'API » existait mais indiquait une ancienne commande ; Awa a dû la retrouver de mémoire.
- Impact : environ 38 % des requêtes de paiement ont échoué pendant 28 minutes (14:05-14:33), soit environ 65 % du budget d'erreur mensuel de l'API.
EOF
wc -l incident.md
```{{exec}}

Lisez-le attentivement : il mélange **faits**, **noms de personnes** et **constats**. Votre travail est de **faire le tri** : les noms disparaissent (on parle de **rôles**), les faits deviennent une chronologie, les constats deviennent des **facteurs** et des **actions**.
