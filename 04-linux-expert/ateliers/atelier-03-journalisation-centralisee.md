# Atelier 03 — Journalisation centralisée avec rsyslog

## 🎯 Objectifs

- Maîtriser `journalctl` pour filtrer par unité, priorité et période.
- Émettre des journaux applicatifs avec `logger`.
- Mettre en place un **serveur de logs** et un **client** rsyslog.
- Configurer la rotation avec `logrotate` et la persistance du journal.

## 📋 Prérequis

- Atelier [02 — Namespaces et cgroups](atelier-02-namespaces-cgroups.md) terminé.
- Cours lu : [Observabilité et journalisation](../cours/03-observabilite-logs.md).
- Un seul poste suffit : le **serveur** et le **client** sont simulés sur la même VM avec deux instances (voir la variante à deux VM en fin d'atelier).

> ⚠️ **Attention** : le port 514 en clair ne doit jamais être exposé sur Internet. Ici, nous restons sur `127.0.0.1`.

## 🧪 Scénario

*Kamer Logistics* exploite plusieurs serveurs : `web01`, `db01`, `app01`. Après un incident, l'équipe a perdu les
journaux d'un serveur compromis. La direction exige que **tous les journaux soient envoyés en temps réel
vers un serveur central**. Vous construisez le prototype.

## Étapes

### Étape 1 — Explorer `journalctl`

```bash
journalctl -n 20 --no-pager
journalctl -u ssh --since "1 hour ago" --no-pager | tail -5
journalctl -p err -b --no-pager | tail -5
journalctl -k -n 5 --no-pager
journalctl -o json-pretty -n 1 --no-pager | head -25
journalctl --disk-usage
```

> ❓ **Question 1** : Quels champs voit-on dans la sortie JSON (`_PID`, `_SYSTEMD_UNIT`, `PRIORITY`…) ? En quoi cela rend-il le filtrage plus puissant que `grep` ?

### Étape 2 — Produire vos propres journaux

```bash
logger "Hello depuis l'atelier"
logger -t suivi-colis -p user.info "Colis KL-1042 livré"
logger -t suivi-colis -p user.err  "Colis KL-1043 introuvable"
logger -t suivi-colis -p user.warning "Colis KL-1044 en retard"
journalctl -t suivi-colis --no-pager
journalctl -t suivi-colis -p err --no-pager
grep suivi-colis /var/log/syslog | tail -3
```

> ❓ **Question 2** : Pourquoi le même message se trouve-t-il à la fois dans `journalctl` et dans `/var/log/syslog` ?

### Étape 3 — Rendre le journal persistant

```bash
ls -ld /var/log/journal 2>&1
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
journalctl --list-boots | tail -3
journalctl --disk-usage
```

Limitez sa taille :

```bash
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/50-taille.conf > /dev/null <<'EOF'
[Journal]
SystemMaxUse=200M
MaxRetentionSec=1month
EOF
sudo systemctl restart systemd-journald
```

> ❓ **Question 3** : Que se passe-t-il pour les journaux après un redémarrage si le stockage est volatil ? Pourquoi est-ce gênant lors d'un incident ?

### Étape 4 — Construire le serveur de logs

```bash
sudo apt install -y rsyslog
sudo tee /etc/rsyslog.d/10-serveur.conf > /dev/null <<'EOF'
module(load="imtcp")
input(type="imtcp" address="127.0.0.1" port="514")

template(name="ParHote" type="string"
         string="/var/log/distant/%HOSTNAME%/%PROGRAMNAME%.log")

# Messages reçus du réseau (jamais produits localement)
if ($inputname == "imtcp") then {
    action(type="omfile" dynaFile="ParHote" dirCreateMode="0750" fileCreateMode="0640")
    stop
}
EOF
sudo rsyslogd -N1
sudo systemctl restart rsyslog
ss -tlnp | grep :514
```

> ❓ **Question 4** : Pourquoi `address="127.0.0.1"` ? Que changerait `0.0.0.0` ? Pourquoi utiliser un modèle (`template`) avec `%HOSTNAME%` ?

### Étape 5 — Configurer le client

Le client envoie **une copie** de tous les journaux au serveur. Le serveur ignore ce qui vient de lui-même grâce à la condition `imtcp`.

```bash
sudo tee /etc/rsyslog.d/90-client.conf > /dev/null <<'EOF'
action(type="omfwd" target="127.0.0.1" port="514" protocol="tcp"
       action.resumeRetryCount="-1"
       queue.type="LinkedList" queue.size="10000"
       queue.filename="fwd-central" queue.saveOnShutdown="on")
EOF
sudo rsyslogd -N1
sudo systemctl restart rsyslog
```

> ❓ **Question 5** : À quoi servent `queue.filename` et `queue.saveOnShutdown` ? Que se passe-t-il pour les messages si le serveur central est indisponible pendant 10 minutes ?

### Étape 6 — Tester la chaîne complète

```bash
logger -t suivi-colis -p user.err "TEST central : incident simulé"
sleep 2
sudo ls -R /var/log/distant | head
sudo cat /var/log/distant/*/suivi-colis.log
```

Vous devez voir le message arrivé sous `/var/log/distant/<nom-d-hôte>/suivi-colis.log`.

### Étape 7 — Tester la résilience (file d'attente)

```bash
# Couper le « serveur » : on neutralise l'écoute en retirant sa configuration
sudo mv /etc/rsyslog.d/10-serveur.conf /root/10-serveur.conf.off
sudo systemctl restart rsyslog
for i in 1 2 3; do logger -t suivi-colis "message pendant la panne n°$i"; done
sleep 2
sudo cat /var/log/distant/*/suivi-colis.log | grep -c "panne"      # 0 : rien reçu
# Rétablir le serveur
sudo mv /root/10-serveur.conf.off /etc/rsyslog.d/10-serveur.conf
sudo systemctl restart rsyslog
sleep 5
sudo cat /var/log/distant/*/suivi-colis.log | grep "panne"
```

> ❓ **Question 6** : Les messages émis pendant la panne sont-ils arrivés après le rétablissement ? Quel mécanisme l'explique ? Que se passerait-il avec UDP ?
> *(Si les messages sont absents, regardez `sudo journalctl -u rsyslog -n 20`, vérifiez la file `/var/spool/rsyslog/`.)*

### Étape 8 — Rotation des journaux distants

```bash
sudo tee /etc/logrotate.d/distant > /dev/null <<'EOF'
/var/log/distant/*/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 syslog adm
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
sudo logrotate -d /etc/logrotate.d/distant 2>&1 | head -15       # simulation
sudo logrotate -f /etc/logrotate.d/distant
sudo ls -l /var/log/distant/*/
```

> ❓ **Question 7** : Pourquoi `delaycompress` ? Pourquoi demander à rsyslog de rouvrir ses fichiers après la rotation (`postrotate`) ?

### Étape 9 — Analyser les journaux centralisés

```bash
for i in $(seq 1 6); do logger -t suivi-colis -p user.err "Erreur base de données (essai $i)"; done
for i in $(seq 1 3); do logger -t suivi-colis -p user.info "Colis livré $i"; done
sleep 2
F=$(sudo find /var/log/distant -name "suivi-colis.log" | head -1)
sudo grep -c "Erreur" "$F"
sudo awk '{print $5}' "$F" | sort | uniq -c | sort -nr | head
sudo tail -5 "$F"
```

### Étape 10 — Synchronisation du temps et corrélation

```bash
timedatectl | grep -E "synchronized|NTP|Time zone"
timedatectl timesync-status 2>/dev/null | head -5
```

> ❓ **Question 8** : Pourquoi des horloges désynchronisées empêchent-elles de reconstituer un incident entre plusieurs serveurs ?

### Nettoyage

```bash
sudo rm -f /etc/rsyslog.d/10-serveur.conf /etc/rsyslog.d/90-client.conf /etc/logrotate.d/distant
sudo rm -rf /var/log/distant
sudo systemctl restart rsyslog
```

## Variante à deux VM (recommandée si possible)

1. Clonez la VM (ou créez-en une seconde) et mettez-les sur un réseau commun (VirtualBox : réseau *Host-only* ; VMware : *Host-only* / *LAN segment*).
2. **Serveur** : remplacez `address="127.0.0.1"` par `address="0.0.0.0"` et ouvrez `ufw allow from <IP-client> to any port 514 proto tcp`.
3. **Client** : mettez `target="<IP-serveur>"` dans `90-client.conf`.
4. Changez le nom d'hôte du client (`sudo hostnamectl set-hostname web01`) et vérifiez la création de `/var/log/distant/web01/`.

## ✅ Validation

- [ ] `journalctl -t suivi-colis -p err` ne renvoie que les messages d'erreur.
- [ ] `sudo ss -tlnp | grep :514` montre rsyslog à l'écoute.
- [ ] Le message de test apparaît dans `/var/log/distant/<hôte>/suivi-colis.log`.
- [ ] Les messages émis pendant la « panne » sont arrivés après le rétablissement.
- [ ] `logrotate -f` a produit un fichier `.log.1` dans le dossier distant.
- [ ] Vous savez expliquer pourquoi un journal local seul est insuffisant face à un attaquant.

## 💡 Pour aller plus loin

- **Défi 1** : passez en **TLS** (`gtls`, port 6514) avec un certificat autosigné.
- **Défi 2** : exposez les métriques système avec `prometheus-node-exporter` (`curl localhost:9100/metrics`).
- **Défi 3** : écrivez un script qui lit les journaux centralisés et affiche les 5 erreurs les plus fréquentes du jour.
- **Défi 4** : déployez Loki + Grafana avec Docker (après le [module 05](../../05-devops-outils/cours/02-docker-fondamentaux.md)) et envoyez-y vos journaux.

Module suivant : [Git et workflow](../../05-devops-outils/cours/01-git-workflow.md).
