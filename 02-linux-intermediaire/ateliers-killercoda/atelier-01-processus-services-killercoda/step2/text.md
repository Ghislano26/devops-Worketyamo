# Étape 2 : créer une unité systemd

Créez le service **`heartbeat`** : il écrit l'heure toutes les 5 secondes dans `/tmp/heartbeat.log`, et **systemd le relance** s'il s'arrête.

```bash
cat > /etc/systemd/system/heartbeat.service <<'EOF'
[Unit]
Description=Battement de coeur (atelier)

[Service]
ExecStart=/bin/bash -c 'while true; do date >> /tmp/heartbeat.log; sleep 5; done'
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
```{{exec}}

Faites relire les unités à systemd, puis **activez** (démarrage au boot) **et démarrez** (maintenant) :

```bash
systemctl daemon-reload
systemctl enable --now heartbeat
systemctl status heartbeat --no-pager | head -n 8
```{{exec}}

Testez la résilience : tuez brutalement le processus et constatez que systemd le relance avec un **nouveau PID** :

```bash
AVANT=$(systemctl show -p MainPID --value heartbeat)
kill -9 "$AVANT"
sleep 4
APRES=$(systemctl show -p MainPID --value heartbeat)
echo "avant=$AVANT apres=$APRES"
tail -n 3 /tmp/heartbeat.log
journalctl -u heartbeat --no-pager | tail -n 5
```{{exec}}

> `start/stop` agissent **maintenant**, `enable/disable` au **prochain démarrage** : deux choses indépendantes. `enable --now` fait les deux.

Cliquez sur **Vérifier**.
