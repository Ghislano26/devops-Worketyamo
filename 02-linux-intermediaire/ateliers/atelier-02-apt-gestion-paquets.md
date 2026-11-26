# Atelier 02 — APT et gestion des paquets

## 🎯 Objectifs

- Installer, inspecter, mettre à jour et supprimer des paquets proprement.
- Comprendre `remove` vs `purge`, et l'effet de `apt update`.
- Retrouver à quel paquet appartient un fichier.
- Figer une version et vérifier les mises à jour de sécurité automatiques.

## 📋 Prérequis

- Atelier [01](atelier-01-processus-systemd.md) terminé.
- Cours lu : [Gestion des paquets avec APT](../cours/02-gestion-paquets.md).
- Accès Internet depuis la VM.

## 🧪 Scénario

Vous devez préparer un serveur web minimal pour *Kamer Logistics* : installer **nginx**, vérifier ce qui a
été déposé sur le disque, tester le service, puis simuler une désinstallation propre. Enfin, vous vérifiez que
les correctifs de sécurité s'appliquent automatiquement.

## Étapes

### Étape 1 — État initial

```bash
lsb_release -ds
apt list --installed 2>/dev/null | wc -l
cat /etc/apt/sources.list.d/ubuntu.sources
```

> ❓ **Question 1** : Quel nom de code apparaît dans `Suites` ? Que représentent `main` et `universe` ?

### Étape 2 — Rafraîchir l'index

```bash
sudo apt update
apt list --upgradable 2>/dev/null | head
```

> ❓ **Question 2** : `apt update` a-t-il installé quelque chose ? Pourquoi doit-il précéder `apt install` ?

### Étape 3 — Inspecter avant d'installer

```bash
apt show nginx | head -15
apt policy nginx
apt-cache depends nginx | head
apt-cache rdepends nginx | head
```

> ❓ **Question 3** : Quelle est la « version candidate » et depuis quel dépôt sera-t-elle installée ?

### Étape 4 — Simuler puis installer

```bash
sudo apt install -s nginx | tail -15      # -s : simulation, rien n'est installé
sudo apt install -y nginx
systemctl status nginx --no-pager | head -5
curl -sI http://localhost | head -3
```

> ❓ **Question 4** : Pourquoi nginx démarre-t-il immédiatement après l'installation ? *(Indice : scripts `postinst` des paquets Debian.)*

### Étape 5 — Ce que le paquet a installé

```bash
dpkg -L nginx | head -20
dpkg -L nginx-common | grep -E "etc|sites"
dpkg -S /usr/sbin/nginx
dpkg -s nginx | grep -E "Status|Version"
which nginx
```

> ❓ **Question 5** : Quelle commande indique à quel paquet appartient `/etc/nginx/nginx.conf` ? Testez-la.

### Étape 6 — Modifier la configuration puis comparer `remove` et `purge`

```bash
echo "# modification locale de l'atelier" | sudo tee -a /etc/nginx/nginx.conf
sudo apt remove -y nginx
ls /etc/nginx/nginx.conf                 # existe encore ?
dpkg -l nginx | tail -1                  # état « rc » = removed, config conservée
sudo apt purge -y nginx
ls /etc/nginx 2>&1 | head -2             # a disparu
sudo apt autoremove -y
```

> ❓ **Question 6** : Que signifie l'état `rc` dans `dpkg -l` ? Dans quel scénario réel préférez-vous `remove` à `purge` ?

### Étape 7 — Réinstaller et figer une version

```bash
sudo apt install -y nginx
sudo apt-mark hold nginx
apt-mark showhold
sudo apt upgrade -y | tail -3
sudo apt-mark unhold nginx
```

> ❓ **Question 7** : Pourquoi geler un paquet en production ? Quel risque cela fait-il courir sur le plan de la sécurité ?

### Étape 8 — Paquet local `.deb`

```bash
cd /tmp
apt download htop                      # télécharge le .deb sans l'installer
ls -l htop_*.deb
dpkg-deb -I htop_*.deb | head -15      # métadonnées
dpkg-deb -c htop_*.deb | head          # liste des fichiers
sudo apt install --reinstall ./htop_*.deb
rm htop_*.deb
```

### Étape 9 — Correctifs de sécurité automatiques

```bash
systemctl is-enabled unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades
sudo unattended-upgrade --dry-run --debug 2>&1 | tail -8
ls /var/log/unattended-upgrades/ 2>/dev/null
```

> ❓ **Question 8** : Que signifie `APT::Periodic::Unattended-Upgrade "1"` ? Quel fichier signale qu'un redémarrage est requis ?

### Étape 10 — Nettoyage et espace disque

```bash
du -sh /var/cache/apt/archives
sudo apt clean
du -sh /var/cache/apt/archives
sudo apt autoremove --purge -y
```

## ✅ Validation

- [ ] Vous avez installé nginx et obtenu une réponse HTTP (`HTTP/1.1 200 OK`).
- [ ] Vous avez trouvé le paquet propriétaire de `/usr/sbin/nginx` avec `dpkg -S`.
- [ ] Vous avez observé l'état `rc` après `remove`, puis sa disparition après `purge`.
- [ ] `apt-mark showhold` a affiché `nginx` pendant le gel, puis plus rien après `unhold`.
- [ ] `unattended-upgrade --dry-run` s'est exécuté sans erreur.
- [ ] Vous savez expliquer la différence entre `apt` et `dpkg`.

## 💡 Pour aller plus loin

- **Défi 1** : listez les 10 plus gros paquets installés : `dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -10`.
- **Défi 2** : retrouvez l'historique des installations dans `/var/log/apt/history.log` et `/var/log/dpkg.log`.
- **Défi 3** : ajoutez un dépôt tiers (par exemple celui d'un outil que vous utilisez) avec une clé dans `/etc/apt/keyrings/` et `Signed-By`.
- **Défi 4** : comparez l'installation de `btop` via `apt` et via `snap` (taille, emplacement, `snap list`).

---

## 🏆 Défi du jour

**Objectif** : Retrouver l'**origine** d'un binaire et d'un fichier de configuration, puis maîtriser le cycle `hold` / `unhold`.

**Contexte** : Un audit demande : « à quel paquet appartient `sshd`, dans quelle version est-il installé, et combien de paquets dépendent du client SSH ? » Tu dois répondre avec des commandes, pas de mémoire.

**Consignes** :
- Crée `~/defi-apt.txt` avec 4 lignes générées par commandes : le **paquet** propriétaire de `/usr/sbin/sshd` ; le **paquet** propriétaire de `/etc/ssh/sshd_config` ; la ligne `Installed:` de `apt policy openssh-server` ; le nombre de lignes renvoyées par `apt-cache rdepends openssh-client`.
- Installe `tree`, **gèle**-le avec `apt-mark hold`, vérifie qu'il apparaît dans `apt-mark showhold`, puis **dégèle**-le.
- Supprime `tree` en conservant la configuration, puis vérifie son état avec `dpkg -l tree` (indice : `ii` ou `rc`).

**Indices** (à consulter seulement si bloqué) :
- `dpkg -S /chemin` répond « quel paquet possède ce fichier ? ».
- `apt policy paquet | grep Installed`.
- `apt remove` garde la configuration, `apt purge` la supprime ; la première colonne de `dpkg -l` vaut `ii` (installé) ou `rc` (supprimé, configuration conservée).

**Critères de réussite** :
- [ ] `~/defi-apt.txt` contient 4 lignes, la première mentionnant `openssh-server`.
- [ ] `apt-mark showhold` ne liste plus `tree` à la fin.
- [ ] `dpkg -l tree` n'affiche pas `ii`.
- [ ] Tu peux expliquer la différence entre `remove` et `purge`.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
{
  dpkg -S /usr/sbin/sshd
  dpkg -S /etc/ssh/sshd_config
  apt policy openssh-server | grep Installed
  echo "rdepends openssh-client : $(apt-cache rdepends openssh-client | wc -l) lignes"
} > ~/defi-apt.txt
cat ~/defi-apt.txt

sudo apt install -y tree
sudo apt-mark hold tree
apt-mark showhold                      # tree
sudo apt-mark unhold tree
apt-mark showhold                      # (vide)

sudo apt remove -y tree
dpkg -l tree | tail -n 1               # « rc » : supprimé, configuration conservée ; « ii » = installé
```

`dpkg -S` interroge la base des fichiers installés ; `apt-mark hold` empêche toute mise à jour du paquet (utile pour figer une version, au prix de ne plus recevoir ses correctifs de sécurité).

</details>

---

Atelier suivant : [Diagnostic réseau](atelier-03-diagnostic-reseau.md).
