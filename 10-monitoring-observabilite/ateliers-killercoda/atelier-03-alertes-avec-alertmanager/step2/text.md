# Étape 2 : saturer le CPU

Provoquez la panne avec **`stress-ng`**, un générateur de charge, sur **tous** les cœurs pendant 4 minutes :

```bash
apt-get install -y -qq stress-ng >/dev/null
nohup stress-ng --cpu $(nproc) --timeout 240s >/dev/null 2>&1 &
sleep 2; uptime
```{{exec}}

Suivez l'alerte dans l'**API de Prometheus** (équivalent de la page `/alerts`) : elle passe par **`pending`** (condition vraie mais `for` non atteint), puis **`firing`** après environ **1 à 2 minutes** (scrape + évaluation + `for: 1m`).

```bash
watch -n 5 "curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | \"\(.labels.alertname)  \(.state)  valeur=\(.value)\"'"
```{{exec}}

(`Ctrl+C` pour quitter `watch` quand l'état affiche **firing**.) Vous pouvez aussi suivre l'évolution de l'utilisation CPU elle-même :

```bash
curl -s --data-urlencode 'query=100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle"}[1m])))' localhost:9090/api/v1/query | jq -r '.data.result[0].value[1]'
```{{exec}}

## Dans Alertmanager

Prometheus envoie l'alerte `firing` à **Alertmanager**, qui la **déduplique**, la **groupe** (`group_by: [alertname]`, `group_wait: 10s`) puis la **route** vers le receiver (ici un *webhook* local). Vérifiez :

```bash
curl -s localhost:9093/api/v2/alerts | jq -r '.[] | "\(.labels.alertname)  \(.status.state)  instance=\(.labels.instance)"'
curl -s localhost:9093/api/v2/status | jq -r '.cluster.status'
```{{exec}}

Le receiver a-t-il été notifié ? (Le petit serveur `webhook.py` écrit chaque notification dans `/tmp/webhook.log`.)

```bash
sleep 20; jq -r '.alerts[]? | "\(.status)  \(.labels.alertname)"' /tmp/webhook.log | sort | uniq -c
```{{exec}}

> Pourquoi la notification n'est-elle pas immédiate ? Le **`group_wait: 10s`** laisse le temps à d'autres alertes liées d'arriver pour les regrouper en un seul message. Voir le [cours 05](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/05-alertmanager-alertes.md).

## Questions

- Quelle différence entre l'état `pending` de Prometheus et `active` dans Alertmanager ? (`pending` : pas encore envoyée ; `active` : reçue, traitée par le routage.)
- Quand le stress s'arrête, que se passe-t-il ? (L'alerte passe à `resolved` ; une notification de résolution part car `send_resolved: true`.)

Cliquez sur **Vérifier** (l'alerte doit être en `firing` pendant la vérification : relancez `stress-ng` si besoin).
