# Étape 1 : un exporter

Un **exporter** expose, sur `/metrics`, les métriques d'un système qui ne parle pas Prometheus (voir le [cours 02](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/02-prometheus-fondamentaux.md)). **`node_exporter`** lit `/proc` et `/sys` pour exposer le CPU, la mémoire, les disques et le réseau de la machine.

Lancez-le dans un conteneur avec le réseau et les PID de l'hôte (pour voir la vraie machine, pas le conteneur) :

```bash
docker run -d --name node-exporter --restart unless-stopped \
  --network host --pid host -v /:/host:ro,rslave \
  prom/node-exporter:v1.8.2 --path.rootfs=/host
```{{exec}}

Vérifiez qu'il tourne et qu'il écoute sur le port **9100** :

```bash
docker ps --filter name=node-exporter
ss -tlnp | grep 9100
```{{exec}}

Lisez le **format texte** des métriques :

```bash
curl -s localhost:9100/metrics | grep -E "^# (HELP|TYPE) node_(cpu_seconds_total|memory_MemAvailable_bytes)"
curl -s localhost:9100/metrics | grep -E "^node_(cpu_seconds_total\{cpu=\"0\"|memory_MemAvailable_bytes)"
curl -s localhost:9100/metrics | wc -l
```{{exec}}

## Questions

- Quel est le **type** de `node_cpu_seconds_total` (ligne `# TYPE`) ? Pourquoi ne lit-on jamais sa valeur brute ? (counter : on utilisera `rate()`, [cours 03](https://github.com/Ghislano26/devops-Worketyamo/blob/main/10-monitoring-observabilite/cours/03-promql-et-metriques.md).)
- Quel est le type de `node_memory_MemAvailable_bytes` ? (gauge.)

Cliquez sur **Vérifier**.
