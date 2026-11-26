# Module 10 — Monitoring & Observabilité

## Pourquoi ce module ?

Déployer une application, c'est la moitié du travail ; **savoir comment elle se porte en production** en est l'autre moitié. Ce module clôt le cursus : il vous apprend à **observer, mesurer et
alerter** sur un système réel, avec les outils standards de l'écosystème cloud-native : **Prometheus**, **Grafana**, **Alertmanager**, **Loki** et **OpenTelemetry**.

> Ce module **ne répète pas** les bases : il mobilise ce que vous avez appris sur Linux (processus, journaux), les réseaux (DNS, ports, TLS), Docker (conteneurs, volumes) et Kubernetes (pods, services, namespaces) pour **observer** ces systèmes.

## Les trois piliers de l'observabilité

| Pilier | Question | Outil du module | Cours |
|---|---|---|---|
| 📈 **Métriques** | *Combien ? À quel rythme ? Est-ce normal ?* | Prometheus (+ Grafana, Alertmanager) | [02](cours/02-prometheus-fondamentaux.md), [03](cours/03-promql-et-metriques.md), [04](cours/04-grafana-visualisation.md), [05](cours/05-alertmanager-alertes.md) |
| 📜 **Logs** | *Que s'est-il passé, précisément ?* | Loki (+ Grafana) | [06](cours/06-logs-avec-loki.md) |
| 🔗 **Traces** | *Où est passé le temps ?* | OpenTelemetry, Tempo/Jaeger | [07](cours/07-traces-et-opentelemetry.md) |

Le cours [01](cours/01-introduction-observabilite.md) pose le cadre : monitoring vs observabilité, **SLI / SLO / SLA** et budget d'erreur, signaux d'or, méthodes **RED** et **USE**, pull vs push.

```text
 Applications ──► métriques ──► Prometheus ──┬─► Grafana
      │                                       └─► Alertmanager ─► Slack / astreinte
      ├──► logs ───────────────► Loki ───────────► Grafana
      └──► traces (OTLP) ──────► Tempo / Jaeger ─► Grafana        (corrélation par labels et trace_id)
```

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [01 → 04 Linux](../01-linux-fondamentaux/PARCOURS.md) | Processus, `journalctl`, `/proc`, performance ([cours noyau](../04-linux-expert/cours/01-noyau-performance.md)), logs ([cours observabilité](../04-linux-expert/cours/03-observabilite-logs.md)) |
| [06 Réseaux](../06-reseaux-devops/README.md) | Ports et sockets, DNS, TLS, diagnostic (comprendre un scrape qui échoue) |
| [08 Docker](../08-docker-approfondi/README.md) | Conteneurs, volumes, réseaux ; les ateliers 1 à 3 tournent en conteneurs |
| [09 Kubernetes](../09-kubernetes-approfondi/README.md) | Pods, Services, namespaces, Helm ; l'atelier 4 tourne sur un cluster |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Introduction à l'observabilité](cours/01-introduction-observabilite.md) | ⭐⭐ | 3 piliers, SLI/SLO/SLA, error budget, Golden Signals, RED/USE, pull vs push |
| 2 | [Prometheus : fondamentaux](cours/02-prometheus-fondamentaux.md) | ⭐⭐⭐ | Architecture, modèle de données, cardinalité, scrape, relabeling, exporters, TSDB, service discovery |
| 3 | [PromQL et métriques](cours/03-promql-et-metriques.md) | ⭐⭐⭐⭐ | Counter/gauge/histogram/summary, `rate()`, `histogram_quantile()`, agrégations, pièges, recording rules |
| 4 | [Grafana : visualisation](cours/04-grafana-visualisation.md) | ⭐⭐⭐ | Datasources, panels, variables, dashboards 1860/315, provisioning as code, drill-down |
| 5 | [Alertmanager et alertes](cours/05-alertmanager-alertes.md) | ⭐⭐⭐⭐ | Règles, routage, groupement, inhibition, silences, *alert fatigue*, burn rate |
| 6 | [Logs avec Loki](cours/06-logs-avec-loki.md) | ⭐⭐⭐ | Architecture, Promtail/Alloy, LogQL, corrélation logs ↔ métriques |
| 7 | [Traces et OpenTelemetry](cours/07-traces-et-opentelemetry.md) | ⭐⭐⭐⭐⭐ | Spans, propagation W3C, SDK/Collector, Tempo/Jaeger, exemplars, échantillonnage |

## Ateliers interactifs (Killercoda)

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — Prometheus et Grafana](ateliers-killercoda/atelier-01-prometheus-grafana-ubuntu/intro.md) (3 étapes) | `ubuntu` | ⭐⭐ | 2, 4 |
| [Atelier 02 — Requêtes PromQL](ateliers-killercoda/atelier-02-promql-requetes/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 3 |
| [Atelier 03 — Alertes avec Alertmanager](ateliers-killercoda/atelier-03-alertes-avec-alertmanager/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐⭐ | 5 |
| [Atelier 04 — Monitoring Kubernetes](ateliers-killercoda/atelier-04-monitoring-kubernetes/intro.md) (2 étapes) | `kubernetes-kubeadm-1node` | ⭐⭐⭐⭐ | 2, 4 |

### Lancer les ateliers sur Killercoda

1. Lisez le cours associé.
2. Ouvrez le scénario sur Killercoda (après avoir lié ce dépôt à votre profil : voir [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md)).
3. Suivez les étapes ; cliquez sur **Vérifier** à la fin de chacune.

Les ateliers 1 à 3 utilisent Docker sur une machine Ubuntu ; l'atelier 4 utilise un cluster Kubernetes prêt à l'emploi. Les commandes fonctionnent aussi sur votre propre VM ou cluster de test.

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 → Cours 03 → Atelier 02 → Cours 04 → Cours 05 → Atelier 03
        → Atelier 04 (Kubernetes) → Cours 06 (Loki) → Cours 07 (traces, OpenTelemetry)
```

> 💡 **Conseil** : les cours 06 et 07 (Loki, traces) sont **uniquement théoriques** dans ce module : les ateliers se concentrent sur la pile **métriques + alertes**, socle de tout le reste. Pour les pratiquer, déployez Loki et Tempo avec leurs charts Helm sur le cluster de l'atelier 4, ou avec Docker Compose sur votre VM.

> ⚠️ **Attention** : la pile de monitoring consomme des ressources (Prometheus surtout, en mémoire). Sur une VM de 4 Go, arrêtez les conteneurs de l'atelier précédent avant d'en lancer un nouveau (`docker rm -f $(docker ps -aq)`), et gardez un snapshot.

## Ce que vous saurez faire à la fin

- Choisir **quoi mesurer** (signaux d'or, RED/USE) et exprimer des **SLO** avec leur budget d'erreur.
- Déployer **Prometheus**, ses exporters et Grafana, et **interroger** les métriques en PromQL sans tomber dans les pièges classiques.
- Concevoir des **alertes utiles** (actionnables, hiérarchisées, avec runbook) et configurer **Alertmanager**.
- Centraliser des **logs** avec Loki et les **corréler** aux métriques ; comprendre le rôle des **traces** et d'**OpenTelemetry**.
- **Monitorer un cluster Kubernetes** avec `kube-prometheus-stack`.

## Navigation

- [← Module 09 — Kubernetes approfondi](../09-kubernetes-approfondi/README.md)
- [← README principal](../README.md)
