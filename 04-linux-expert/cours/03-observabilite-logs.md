# Observabilité et journalisation

## Pourquoi ce cours ?

En production, vous ne pouvez pas vous connecter sur chaque machine pour lire des fichiers de log. Quand un
incident survient à 3 h du matin sur l'un de vos 50 serveurs, il faut **centraliser** les journaux, les
**corréler** et être **alerté**. L'observabilité, c'est la capacité de comprendre l'état interne d'un système à
partir de ce qu'il émet : **logs, métriques, traces**.

```text
Les trois piliers de l'observabilité
┌──────────┬────────────────────────────┬────────────────────────────┐
│ Logs     │ Événements horodatés       │ « Que s'est-il passé ? »   │
│ Métriques│ Séries numériques          │ « Combien ? À quel rythme ?»│
│ Traces   │ Parcours d'une requête     │ « Où est le temps perdu ? » │
└──────────┴────────────────────────────┴────────────────────────────┘
```

## 1. Les journaux sous Linux : deux mondes qui cohabitent

| Système | Format | Consultation | Emplacement |
|---|---|---|---|
| **systemd-journald** | Binaire indexé | `journalctl` | `/var/log/journal/` (persistant) ou `/run/log/journal/` (volatil) |
| **rsyslog** | Texte | `less`, `grep`, `tail` | `/var/log/syslog`, `/var/log/auth.log`… |

Sur Ubuntu, `journald` collecte tout (noyau, services, stdout des unités) et **transmet** à `rsyslog`, qui écrit les fichiers texte classiques et peut les expédier vers un serveur distant.

```text
 Applications ─┬─ syslog() ──────┐
 Services  ────┤ stdout/stderr ──┼─► journald ─► (journal binaire)
 Noyau (kmsg) ─┘                 │        └───► rsyslog ─► /var/log/*.log
                                 │                  └────► serveur distant (TCP 514)
```

### Fichiers de journaux usuels

| Fichier | Contenu |
|---|---|
| `/var/log/syslog` | Messages généraux |
| `/var/log/auth.log` | Authentifications, `sudo`, SSH |
| `/var/log/kern.log` | Messages du noyau |
| `/var/log/dpkg.log`, `/var/log/apt/` | Installations |
| `/var/log/nginx/` | Journaux des applications |

## 2. `journalctl` en profondeur

```bash
journalctl                                 # tout
journalctl -n 50                           # 50 dernières lignes
journalctl -f                              # suivi en direct
journalctl -u ssh                          # une unité
journalctl -u ssh -u nginx                 # plusieurs unités
journalctl -p err                          # priorité erreur et plus grave
journalctl -p warning..err                 # intervalle de priorités
journalctl --since "2025-11-24 08:00" --until "2025-11-24 09:00"
journalctl --since "1 hour ago"
journalctl -b                              # depuis le démarrage actuel ; -b -1 : précédent
journalctl -k                              # messages du noyau
journalctl _PID=1234                       # par PID
journalctl _UID=1000                       # par utilisateur
journalctl -o json-pretty -n 1             # format JSON, riche en champs
journalctl -o short-iso                    # horodatage ISO 8601
journalctl --disk-usage
sudo journalctl --vacuum-time=7d           # purge de ce qui a plus de 7 jours
sudo journalctl --vacuum-size=200M
```

Niveaux de **priorité** (syslog) :

| Valeur | Nom | Usage |
|---|---|---|
| 0 | `emerg` | Système inutilisable |
| 1 | `alert` | Action immédiate requise |
| 2 | `crit` | Critique |
| 3 | `err` | Erreur |
| 4 | `warning` | Avertissement |
| 5 | `notice` | Normal mais significatif |
| 6 | `info` | Information |
| 7 | `debug` | Débogage |

### Rendre le journal persistant

Par défaut sur certaines installations, le journal est volatil (perdu au redémarrage). Pour le conserver :

```bash
sudo mkdir -p /var/log/journal
sudo sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
journalctl --list-boots
```

## 3. Émettre ses propres journaux

```bash
logger "Déploiement terminé"                         # priorité user.notice
logger -p local0.warning -t monapp "Disque à 85 %"   # -t : étiquette, -p : facilité.priorité
journalctl -t monapp
```

Dans un script, `logger` envoie vers journald/rsyslog : c'est plus propre qu'un `echo >> fichier`.

## 4. rsyslog : routage et expédition

La configuration est dans `/etc/rsyslog.conf` et `/etc/rsyslog.d/*.conf`.

Chaque règle suit le schéma `facilité.priorité   destination` :

```text
auth,authpriv.*      /var/log/auth.log
*.*;auth,authpriv.none  -/var/log/syslog
kern.*               -/var/log/kern.log
local0.*             /var/log/monapp.log
```

**Facilités** : `auth`, `authpriv`, `cron`, `daemon`, `kern`, `mail`, `syslog`, `user`, `local0`…`local7`.

### Journalisation centralisée

```text
 Clients (web01, db01…)  ──── TCP 514 ────►  Serveur de logs (loghost)
   rsyslog (omfwd)                              rsyslog (imtcp)
                                                /var/log/distant/<hôte>/<programme>.log
```

**Serveur** — `/etc/rsyslog.d/10-serveur.conf` :

```text
module(load="imtcp")
input(type="imtcp" port="514")

template(name="ParHote" type="string" string="/var/log/distant/%HOSTNAME%/%PROGRAMNAME%.log")
if ($fromhost-ip != '127.0.0.1') then {
    action(type="omfile" dynaFile="ParHote")
    stop
}
```

**Client** — `/etc/rsyslog.d/90-client.conf` :

```text
*.* action(type="omfwd" target="192.168.56.10" port="514" protocol="tcp"
           action.resumeRetryCount="100"
           queue.type="linkedList" queue.size="10000" queue.filename="fwdq" queue.saveOnShutdown="on")
```

Les paramètres `queue.*` créent une **file d'attente sur disque** : si le serveur tombe, aucun message n'est perdu.

```bash
sudo rsyslogd -N1                    # valide la configuration
sudo systemctl restart rsyslog
ss -tlnp | grep :514
logger -p user.notice "test depuis $(hostname)"
```

> ⚠️ **Attention** : syslog sur TCP/514 est **en clair**. En production, utilisez **TLS** (module `gtls`, port 6514) et restreignez les sources par pare-feu. Les journaux contiennent des informations sensibles.

> 💡 **Conseil** : UDP (`@`) est plus simple mais **sans garantie de livraison** ; TCP (`@@`) est préférable pour des journaux d'audit.

## 5. Rotation des journaux : `logrotate`

Sans rotation, `/var/log` finit par saturer le disque.

```bash
cat /etc/logrotate.conf
ls /etc/logrotate.d/
```

Exemple `/etc/logrotate.d/monapp` :

```text
/var/log/monapp.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 syslog adm
    postrotate
        systemctl kill -s HUP rsyslog.service
    endscript
}
```

```bash
sudo logrotate -d /etc/logrotate.d/monapp     # simulation (debug)
sudo logrotate -f /etc/logrotate.d/monapp     # forcer
```

## 6. Les métriques

Un journal décrit un événement ; une **métrique** est une valeur numérique échantillonnée dans le temps (CPU, requêtes/s, latence).

| Outil | Rôle |
|---|---|
| `node_exporter` | Expose les métriques système (CPU, mémoire, disque, réseau) |
| **Prometheus** | Collecte (*scrape*) et stocke des séries temporelles ; langage PromQL |
| **Grafana** | Tableaux de bord et alertes |
| **Alertmanager** | Routage des alertes (e-mail, chat) |

Exemple :

```bash
curl -s localhost:9100/metrics | grep -E "^node_load1|^node_memory_MemAvailable_bytes"
```

Méthodes de lecture : **RED** pour un service (*Rate*, *Errors*, *Duration*) et **USE** pour une ressource (voir le [cours noyau](01-noyau-performance.md)).

## 7. Piles de journalisation modernes

| Pile | Composants |
|---|---|
| **ELK / Elastic** | Elasticsearch + Logstash/Beats + Kibana |
| **Loki** | Grafana Loki + Promtail/Alloy + Grafana (indexe seulement les étiquettes) |
| **Graylog** | Serveur de journaux avec interface web |
| **OpenTelemetry** | Standard ouvert pour logs, métriques et traces |

Principes d'un **bon journal** :

1. **Horodatage** précis, en UTC et en ISO 8601.
2. **Niveaux** cohérents (`INFO`, `WARN`, `ERROR`).
3. Format **structuré** (JSON) pour faciliter l'analyse.
4. **Identifiant de corrélation** (*request id*) pour suivre une requête entre services.
5. **Jamais** de secrets ni de données personnelles en clair.

Exemple de ligne structurée :

```json
{"ts":"2025-11-24T09:15:32Z","level":"error","service":"api","request_id":"a1b2c3","msg":"timeout base de données","duration_ms":5003}
```

```bash
journalctl -u api -o cat | jq 'select(.level=="error")'
```

## 8. Temps et synchronisation

Corréler des journaux de plusieurs machines exige des **horloges synchronisées**.

```bash
timedatectl                               # synchronisation NTP : « System clock synchronized: yes »
timedatectl timesync-status               # serveur NTP, décalage
chronyc tracking 2>/dev/null              # si chrony est utilisé
```

## 9. Audit et sécurité des journaux

- Protégez les journaux contre l'altération (droits `640`, envoi en temps réel vers un serveur distant : un attaquant qui compromet une machine peut effacer ses traces locales).
- `auditd` : trace les accès fichiers et appels système (`ausearch`, `aureport`).
- Conservation : respectez les exigences légales (durée, RGPD).

```bash
sudo aureport --summary 2>/dev/null | head
last -a | head -5
```

> 📌 **À retenir** : un journal qui reste sur la machine compromise n'est pas fiable. **Envoyez les journaux ailleurs, en temps réel** : c'est la seule manière de conserver la trace d'une intrusion.

## Résumé

- Trois piliers : **logs, métriques, traces**.
- `journald` (binaire, `journalctl`) et `rsyslog` (texte, expédition) cohabitent.
- `journalctl` : `-u`, `-p`, `--since`, `-b`, `-k`, `-f`, `-o json`.
- Centralisation : clients → TCP (idéalement TLS) → serveur `rsyslog` avec file d'attente sur disque.
- `logrotate` évite la saturation ; `logger` émet depuis les scripts.
- Journaux **structurés**, horloges **synchronisées**, **jamais** de secrets dans les logs.

## Pour aller plus loin

- `man journalctl`, `man journald.conf`, `man rsyslog.conf`, `man logrotate`, `man logger`.
- Prometheus + Grafana, Loki, OpenTelemetry.
- Politique de conservation et RGPD.
- Atelier associé : [Journalisation centralisée](../ateliers/atelier-03-journalisation-centralisee.md).
- Module suivant : [Git et workflow](../../05-devops-outils/cours/01-git-workflow.md).
