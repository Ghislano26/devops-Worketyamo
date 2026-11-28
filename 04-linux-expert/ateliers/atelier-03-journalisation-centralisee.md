# Atelier 03 — Journalisation centralisée avec rsyslog

> 🐧 *Version Rocky Linux 9 : journaux dans `/var/log/messages` et `/var/log/secure`, service `sshd`, `chronyd` pour l'heure, `firewalld` pour le pare-feu.*

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
journalctl -u sshd --since "1 hour ago" --no-pager | tail -5
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
sudo grep suivi-colis /var/log/messages | tail -3
```

> ❓ **Question 2** : Pourquoi le même message se trouve-t-il à la fois dans `journalctl` et dans `/var/log/messages` ?

### Étape 3 — Rendre le journal persistant

> 🐧 Sous Rocky, `/var/log/journal` n'existe pas par défaut : `Storage=auto` garde alors le journal **en mémoire** (volatil). Ubuntu crée ce dossier à l'installation. Le `ls -ld` ci-dessous le montre.

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
rpm -q rsyslog || sudo dnf install -y rsyslog      # déjà installé et actif sur Rocky
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
> *(Si les messages sont absents, regardez `sudo journalctl -u rsyslog -n 20`, vérifiez la file dans `/var/lib/rsyslog/`.)*

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
    create 0640 root root
    sharedscripts
    postrotate
        /usr/bin/systemctl kill -s HUP rsyslog.service >/dev/null 2>&1 || true
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
chronyc tracking | head -5          # synchronisation assurée par chronyd sous Rocky
```

> ❓ **Question 8** : Pourquoi des horloges désynchronisées empêchent-elles de reconstituer un incident entre plusieurs serveurs ?

### Nettoyage

```bash
sudo rm -f /etc/rsyslog.d/10-serveur.conf /etc/rsyslog.d/90-client.conf /etc/logrotate.d/distant
sudo rm -rf /var/log/distant
sudo systemctl restart rsyslog
```

## Variante à deux VM (recommandée si possible)

1. Créez une seconde VM : copiez le dossier `environnement/vagrant`, changez `vb.name` et l'adresse du réseau privé (`192.168.56.11`) dans son `Vagrantfile`, puis `vagrant up` : les deux VM partagent le réseau privé `192.168.56.0/24`.
2. **Serveur** : remplacez `address="127.0.0.1"` par `address="0.0.0.0"` et ouvrez le port pour le client seulement : `sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<IP-client>" port port="514" protocol="tcp" accept' && sudo firewall-cmd --reload`.
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
- **Défi 2** : exposez les métriques système avec `node_exporter` (binaire officiel de Prometheus ; `curl localhost:9100/metrics`).
- **Défi 3** : écrivez un script qui lit les journaux centralisés et affiche les 5 erreurs les plus fréquentes du jour.
- **Défi 4** : déployez Loki + Grafana avec Docker (après le [module 05](../../05-devops-outils/cours/02-docker-fondamentaux.md)) et envoyez-y vos journaux.

---

## 🏆 Défi du jour

**Objectif** : Router les journaux d'une application vers **son propre fichier** avec une règle `rsyslog`, puis en configurer la **rotation**.

**Contexte** : L'équipe applicative envoie ses messages avec `logger -p local5.*`. Ils doivent atterrir dans `/var/log/defi.log` (et pas noyés dans `syslog`), et ce fichier ne doit pas grossir indéfiniment.

**Consignes** :
- Crée `/etc/rsyslog.d/30-defi.conf` avec la règle `local5.*  /var/log/defi.log`, recharge `rsyslog`.
- Émets trois messages : `logger -t defi-app -p local5.info`, `local5.warning` et `local5.err`, puis retrouve-les dans le fichier **et** avec `journalctl -t defi-app -p warning`.
- Crée `/etc/logrotate.d/defi` (hebdomadaire, 4 rotations, compressé, `create 0640 root root`, rechargement de rsyslog dans `postrotate`).
- Force la rotation avec `sudo logrotate -f /etc/logrotate.d/defi` et prouve qu'un `defi.log.1` existe et que `defi.log` est repartie vide ou presque.
- Nettoie (règle, configuration logrotate, fichiers).

**Indices** (à consulter seulement si bloqué) :
- `sudo systemctl restart rsyslog` après la création de la règle ; `sudo rsyslogd -N1` valide la syntaxe.
- `logger -p local5.warning -t defi-app "message"`.
- Dans `postrotate` : `/usr/bin/systemctl kill -s HUP rsyslog.service` (c'est ce que fait la configuration `logrotate` de Rocky pour rsyslog).

**Critères de réussite** :
- [ ] `grep -c defi-app /var/log/defi.log` affiche au moins `3` avant la rotation.
- [ ] `journalctl -t defi-app -p warning` affiche les messages `warning` et `err` (pas `info`).
- [ ] Après `logrotate -f`, `/var/log/defi.log.1` existe.
- [ ] Les fichiers et configurations de l'exercice sont supprimés à la fin.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
echo 'local5.*    /var/log/defi.log' | sudo tee /etc/rsyslog.d/30-defi.conf
sudo rsyslogd -N1 && sudo systemctl restart rsyslog

logger -t defi-app -p local5.info    "demarrage de l'application"
logger -t defi-app -p local5.warning "disque a 85 pour cent"
logger -t defi-app -p local5.err     "echec de la connexion a la base"
sleep 1
sudo grep -c defi-app /var/log/defi.log                      # 3
journalctl -t defi-app -p warning --no-pager                 # warning et err

sudo tee /etc/logrotate.d/defi > /dev/null <<'EOF'
/var/log/defi.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    postrotate
        /usr/bin/systemctl kill -s HUP rsyslog.service >/dev/null 2>&1 || true
    endscript
}
EOF
sudo logrotate -d /etc/logrotate.d/defi | head                # simulation
sudo logrotate -f /etc/logrotate.d/defi
ls -l /var/log/defi.log*                                      # defi.log et defi.log.1

# Nettoyage
sudo rm -f /etc/rsyslog.d/30-defi.conf /etc/logrotate.d/defi /var/log/defi.log*
sudo systemctl restart rsyslog
```

Le **filtre** `local5.*` choisit la facilité (`local0`…`local7` sont réservées aux applications) ; `delaycompress` laisse la dernière rotation non compressée tant que rsyslog peut encore y écrire ; `postrotate` lui demande de rouvrir son fichier.

</details>

---

Module suivant : [Git et workflow](../../05-devops-outils/cours/01-git-workflow.md).
