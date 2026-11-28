# Atelier 01 — Processus et services systemd

## 🎯 Objectifs

- Observer, prioriser et arrêter des processus (`ps`, `top`, `kill`, `nice`).
- Créer, activer et superviser un service systemd personnalisé.
- Provoquer une panne, la diagnostiquer avec `journalctl` et configurer le redémarrage automatique.

## 📋 Prérequis

- Modules 00 et 01 terminés ; snapshot de la VM pris.
- Cours lu : [Processus, signaux et services systemd](../cours/01-processus-services.md).
- Paquets : `htop` (EPEL, déjà installé dans la VM du cours), `python3` (présent par défaut).

## 🧪 Scénario

L'équipe de *Kamer Logistics* vous demande de déployer une petite API interne, `suivi-colis`. Vous devez
l'exécuter comme un vrai service : démarrage automatique, redémarrage en cas de plantage, journaux
consultables. Avant cela, un collègue signale que « le serveur rame » : vous devez trouver le coupable.

## Étapes

### Étape 1 — Observer le système

```bash
uptime
nproc
ps aux --sort=-%cpu | head -5
pstree -p | head -15
```

> ❓ **Question 1** : Quel est le PID du premier processus ? Quel programme est-ce ? Que signifie un `load average` supérieur à `nproc` ?

### Étape 2 — Provoquer et traquer une surcharge

Ouvrez **deux terminaux** (ou deux onglets). Dans le terminal A :

```bash
yes > /dev/null &        # consomme 100 % d'un cœur
echo $!                  # PID du dernier processus lancé en arrière-plan
```

Dans le terminal B :

```bash
ps aux --sort=-%cpu | head -3
top -b -n 1 | head -12
```

> ❓ **Question 2** : Pourquoi `yes > /dev/null` consomme-t-il du CPU mais pas de disque ?

### Étape 3 — Arrêter proprement

```bash
pgrep -a yes
kill $(pgrep yes)        # SIGTERM
sleep 1; pgrep -a yes || echo "yes est arrêté"
```

> ❓ **Question 3** : Pourquoi essaie-t-on `SIGTERM` (15) avant `SIGKILL` (9) ? Dans quel cas `kill -9` devient-il nécessaire ?

### Étape 4 — Priorités avec `nice`

```bash
nice -n 19 yes > /dev/null &
yes > /dev/null &
ps -o pid,ni,%cpu,cmd -C yes
sleep 5
ps -o pid,ni,%cpu,cmd -C yes
pkill yes
```

> ❓ **Question 4** : Avec plusieurs cœurs libres, les deux processus ont-ils des `%CPU` différents ? Pourquoi la différence ne se voit-elle vraiment que si le CPU est saturé ?
> *(Astuce : sur 4 vCPU, lancez 4 à 5 instances pour saturer.)*

### Étape 5 — Tâches d'arrière-plan

```bash
sleep 300
# Appuyez sur Ctrl+Z
jobs
bg %1
jobs
fg %1
# Ctrl+C
```

### Étape 6 — Écrire l'application

```bash
mkdir -p ~/suivi-colis
cat > ~/suivi-colis/api.py <<'EOF'
#!/usr/bin/env python3
"""API minimale de suivi de colis (démonstration)."""
from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        corps = json.dumps({"colis": "KL-1042", "statut": "en transit", "pid": os.getpid()}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(corps + b"\n")

HTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
EOF
chmod +x ~/suivi-colis/api.py
~/suivi-colis/api.py &
sleep 1
curl -s http://127.0.0.1:8000
kill %1
```

### Étape 7 — Créer l'unité systemd

```bash
sudo tee /etc/systemd/system/suivi-colis.service > /dev/null <<EOF
[Unit]
Description=API de suivi de colis (atelier)
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/python3 $HOME/suivi-colis/api.py
Restart=on-failure
RestartSec=2
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now suivi-colis
systemctl status suivi-colis --no-pager
curl -s http://127.0.0.1:8000
```

> ❓ **Question 5** : Pourquoi `daemon-reload` est-il nécessaire après avoir créé le fichier ? Quelle différence entre `enable` et `start` ?

### Étape 8 — Tester la résilience

```bash
systemctl show -p MainPID suivi-colis      # noter le PID
sudo kill -9 $(systemctl show -p MainPID --value suivi-colis)
sleep 3
systemctl status suivi-colis --no-pager | head -5
curl -s http://127.0.0.1:8000              # nouveau PID dans la réponse
```

> ❓ **Question 6** : Qu'est-ce qui a relancé le service ? Que se passerait-il avec `Restart=no` ?

### Étape 9 — Lire les journaux

```bash
journalctl -u suivi-colis --no-pager | tail -15
journalctl -u suivi-colis --since "5 minutes ago" -p warning
```

### Étape 10 — Panne volontaire et diagnostic

Cassez volontairement l'unité :

```bash
sudo sed -i 's#api.py#api-inexistant.py#' /etc/systemd/system/suivi-colis.service
sudo systemctl daemon-reload
sudo systemctl restart suivi-colis
systemctl status suivi-colis --no-pager
journalctl -xeu suivi-colis --no-pager | tail -15
systemctl --failed
```

Corrigez :

```bash
sudo sed -i 's#api-inexistant.py#api.py#' /etc/systemd/system/suivi-colis.service
sudo systemctl daemon-reload
sudo systemctl reset-failed suivi-colis
sudo systemctl restart suivi-colis
curl -s http://127.0.0.1:8000
```

> ❓ **Question 7** : Quelle ligne du journal vous indique précisément la cause (code de sortie 203/EXEC) ?

### Étape 11 — Évaluer la sécurité de l'unité

```bash
systemd-analyze security suivi-colis --no-pager | tail -5
```

## ✅ Validation

- [ ] `systemctl is-enabled suivi-colis` → `enabled`
- [ ] `systemctl is-active suivi-colis` → `active`
- [ ] `curl -s http://127.0.0.1:8000` renvoie du JSON.
- [ ] Après `kill -9`, le service revient avec un **nouveau PID**.
- [ ] Vous avez retrouvé la cause de la panne volontaire dans `journalctl`.
- [ ] Aucun processus `yes` ne tourne (`pgrep yes` ne renvoie rien).

## 💡 Pour aller plus loin

- **Défi 1** : après un `sudo reboot`, vérifiez que le service redémarre seul.
- **Défi 2** : ajoutez `MemoryMax=50M` et `CPUQuota=20%` dans `[Service]` ; vérifiez avec `systemctl show suivi-colis -p MemoryMax`.
- **Défi 3** : créez un `.timer` qui lance toutes les 5 minutes un service écrivant `date` dans `/tmp/heartbeat.log`.
- **Défi 4** : renforcez l'unité (`ProtectSystem=strict`, `ProtectHome=read-only`) et comparez le score de `systemd-analyze security`.

Nettoyage (optionnel) : `sudo systemctl disable --now suivi-colis && sudo rm /etc/systemd/system/suivi-colis.service && sudo systemctl daemon-reload`.

---

## 🏆 Défi du jour

**Objectif** : Créer un service systemd **résistant aux pannes**, le faire planter volontairement et ajuster son comportement avec un *drop-in*.

**Contexte** : Un script de « battement de cœur » doit écrire l'heure toutes les 5 secondes dans un fichier, pour que la supervision détecte que le serveur est vivant. Il ne doit **jamais** rester arrêté, même si quelqu'un le tue.

**Consignes** :
- Crée `/etc/systemd/system/heartbeat.service` : `ExecStart=/bin/bash -c 'while true; do date >> /tmp/heartbeat.log; sleep 5; done'`, `Restart=always`, `RestartSec=2`, `WantedBy=multi-user.target`.
- Active-le et démarre-le d'un coup ; vérifie que `/tmp/heartbeat.log` grandit.
- Note son `MainPID`, tue-le avec `kill -9`, attends 3 secondes et prouve que le service est reparti avec un **autre PID**.
- Avec `systemctl edit`, passe `RestartSec` à 5 secondes **sans toucher** au fichier d'origine, et vérifie la valeur avec `systemctl show -p RestartUSec`.
- Retrouve dans `journalctl -u heartbeat` la trace du redémarrage automatique.

**Indices** (à consulter seulement si bloqué) :
- `systemctl show -p MainPID --value heartbeat` affiche le PID principal.
- N'oublie pas `sudo systemctl daemon-reload` après avoir créé le fichier d'unité.
- `sudo systemctl edit heartbeat` ouvre un éditeur : écris `[Service]` puis `RestartSec=5`.

**Critères de réussite** :
- [ ] `systemctl is-active heartbeat` → `active` et `systemctl is-enabled heartbeat` → `enabled`.
- [ ] Après le `kill -9`, le PID principal a changé.
- [ ] `systemctl show -p RestartUSec heartbeat` affiche `5s`.
- [ ] Le journal contient une ligne `Scheduled restart job` (ou `Failed with result 'signal'`).

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
sudo tee /etc/systemd/system/heartbeat.service > /dev/null <<'EOF'
[Unit]
Description=Battement de coeur (defi)

[Service]
ExecStart=/bin/bash -c 'while true; do date >> /tmp/heartbeat.log; sleep 5; done'
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now heartbeat
tail -n 3 /tmp/heartbeat.log

AVANT=$(systemctl show -p MainPID --value heartbeat)
sudo kill -9 "$AVANT"
sleep 3
APRES=$(systemctl show -p MainPID --value heartbeat)
echo "avant=$AVANT après=$APRES"                    # deux PID différents

sudo systemctl edit heartbeat                       # saisir : [Service]  puis  RestartSec=5
systemctl show -p RestartUSec heartbeat             # RestartUSec=5s
journalctl -u heartbeat --no-pager | grep -iE "restart|signal" | tail -n 3
```

`Restart=always` : systemd relance le processus quelle que soit la cause de l'arrêt. Le *drop-in* (`/etc/systemd/system/heartbeat.service.d/override.conf`) modifie l'unité sans toucher au fichier d'origine.

</details>

---

Atelier suivant : [Gestion des paquets avec DNF](atelier-02-apt-gestion-paquets.md).
