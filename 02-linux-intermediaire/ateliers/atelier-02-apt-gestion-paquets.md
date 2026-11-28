# Atelier 02 — Gestion des paquets avec DNF

> 🐧 *Le nom du fichier (`apt-gestion-paquets`) est conservé pour ne pas casser les liens ; l'atelier utilise **DNF** et **rpm** sur Rocky Linux 9.*

## 🎯 Objectifs

- Installer, inspecter, mettre à jour et supprimer des paquets proprement.
- Comprendre ce que devient la configuration après `dnf remove` (`.rpmsave`) et l'effet de `dnf check-update`.
- Retrouver à quel paquet appartient un fichier.
- Figer une version et vérifier les mises à jour de sécurité automatiques.

## 📋 Prérequis

- Atelier [01](atelier-01-processus-systemd.md) terminé.
- Cours lu : [Gestion des paquets avec DNF](../cours/02-gestion-paquets.md).
- Accès Internet depuis la VM (`vagrant ssh`).

## 🧪 Scénario

Vous devez préparer un serveur web minimal pour *Kamer Logistics* : installer **nginx**, vérifier ce qui a
été déposé sur le disque, tester le service, puis simuler une désinstallation propre. Enfin, vous vérifiez que
les correctifs de sécurité peuvent s'appliquer automatiquement.

## Étapes

### Étape 1 — État initial

```bash
cat /etc/rocky-release
dnf list installed 2>/dev/null | wc -l
ls /etc/yum.repos.d/
dnf repolist
```

> ❓ **Question 1** : Quels dépôts sont actifs ? Que contiennent `baseos`, `appstream` et `epel` ?

### Étape 2 — Interroger les métadonnées

```bash
sudo dnf check-update | head ; echo "code de sortie : ${PIPESTATUS[0]}"
dnf list --upgrades 2>/dev/null | head
```

> ❓ **Question 2** : `dnf check-update` a-t-il installé quelque chose ? Que signifie le code de sortie `100` ? Pourquoi n'a-t-on pas besoin d'un « `update` » avant `install` comme sous Ubuntu ?

### Étape 3 — Inspecter avant d'installer

```bash
dnf info nginx | head -15
dnf repoquery --requires nginx | head
dnf repoquery --whatrequires nginx-core 2>/dev/null | head
dnf module list nginx
```

> ❓ **Question 3** : Quelle version de nginx sera installée et depuis quel dépôt ? Quels flux (*streams*) de module existent ?

### Étape 4 — Simuler puis installer

```bash
sudo dnf install --assumeno nginx | tail -15      # simulation : rien n'est installé
sudo dnf install -y nginx
systemctl is-active nginx                          # inactive : le service n'est pas démarré
sudo systemctl enable --now nginx
curl -sI http://localhost | head -3
```

> ❓ **Question 4** : Pourquoi nginx n'est-il **pas** démarré juste après l'installation, contrairement à Ubuntu ? *(Indice : politique des paquets RPM / presets systemd.)*

### Étape 5 — Ce que le paquet a installé

```bash
rpm -ql nginx | head -20
rpm -qc nginx                          # fichiers de configuration du paquet
rpm -qf /usr/sbin/nginx
rpm -qi nginx | grep -E "^(Name|Version|Release|Source RPM)"
which nginx
```

> ❓ **Question 5** : Quelle commande indique à quel paquet appartient `/etc/nginx/nginx.conf` ? Testez-la.

### Étape 6 — Modifier la configuration puis supprimer le paquet

```bash
echo "# modification locale de l'atelier" | sudo tee -a /etc/nginx/nginx.conf
sudo dnf remove -y nginx
ls -l /etc/nginx/nginx.conf*              # la configuration modifiée a été conservée sous un autre nom
rpm -q nginx                              # package nginx is not installed
sudo dnf autoremove -y
```

> ❓ **Question 6** : Quel suffixe a reçu la configuration modifiée ? Pourquoi les fichiers de configuration **non modifiés** disparaissent-ils ? Dans quel scénario réel ce comportement vous sauve-t-il ?

### Étape 7 — Historique et retour arrière

```bash
sudo dnf history | head -8
sudo dnf history undo last -y          # annule la dernière transaction (autoremove ou remove)
rpm -q nginx
```

> ❓ **Question 7** : Que fait `dnf history undo` ? En quoi est-ce plus puissant qu'un `apt install` de remplacement ?

### Étape 8 — Réinstaller et figer une version

```bash
sudo dnf install -y nginx python3-dnf-plugin-versionlock
sudo dnf versionlock add nginx
sudo dnf versionlock list
sudo dnf upgrade -y | tail -3
sudo dnf versionlock delete nginx
```

> ❓ **Question 8** : Pourquoi geler un paquet en production ? Quel risque cela fait-il courir sur le plan de la sécurité ?

### Étape 9 — Paquet local `.rpm`

```bash
cd /tmp
dnf download htop                      # télécharge le .rpm sans l'installer
ls -l htop-*.rpm
rpm -qpi htop-*.rpm | head -12         # métadonnées du fichier (p = package file)
rpm -qpl htop-*.rpm | head             # liste des fichiers
sudo dnf reinstall -y ./htop-*.rpm
rm htop-*.rpm
```

### Étape 10 — Correctifs de sécurité automatiques

```bash
systemctl is-enabled dnf-automatic-install.timer
grep -E '^(upgrade_type|apply_updates)' /etc/dnf/automatic.conf
sudo dnf upgrade --security --assumeno 2>&1 | tail -5
sudo dnf needs-restarting -r ; echo "code : $?"
```

> ❓ **Question 9** : Que valent `upgrade_type` et `apply_updates` par défaut ? Que signifie un code de sortie `1` pour `needs-restarting -r` ?

### Étape 11 — Nettoyage et espace disque

```bash
du -sh /var/cache/dnf
sudo dnf clean all
du -sh /var/cache/dnf
```

## ✅ Validation

- [ ] Vous avez installé nginx, l'avez démarré et obtenu une réponse HTTP (`HTTP/1.1 200 OK`).
- [ ] Vous avez trouvé le paquet propriétaire de `/usr/sbin/nginx` avec `rpm -qf`.
- [ ] Vous avez observé le fichier `nginx.conf.rpmsave` après `dnf remove`.
- [ ] `dnf versionlock list` a affiché `nginx` pendant le gel, puis plus rien après `delete`.
- [ ] `dnf upgrade --security --assumeno` s'est exécuté sans erreur.
- [ ] Vous savez expliquer la différence entre `dnf` et `rpm`.

## 💡 Pour aller plus loin

- **Défi 1** : listez les 10 plus gros paquets installés : `rpm -qa --queryformat '%{SIZE}\t%{NAME}\n' | sort -n | tail -10`.
- **Défi 2** : retrouvez l'historique des installations avec `sudo dnf history` et `/var/log/dnf.log`.
- **Défi 3** : ajoutez un dépôt tiers (par exemple celui d'un outil que vous utilisez) dans `/etc/yum.repos.d/` avec `gpgcheck=1` et `gpgkey=`.
- **Défi 4** : activez un autre flux de module (`dnf module list nodejs`, puis `dnf module enable nodejs:20`) et comparez les versions.

---

## 🏆 Défi du jour

**Objectif** : Retrouver l'**origine** d'un binaire et d'un fichier de configuration, puis maîtriser le cycle de gel avec `versionlock`.

**Contexte** : Un audit demande : « à quel paquet appartient `sshd`, dans quelle version est-il installé, et combien de paquets dépendent du client SSH ? » Tu dois répondre avec des commandes, pas de mémoire.

**Consignes** :
- Crée `~/defi-dnf.txt` avec 4 lignes générées par commandes : le **paquet** propriétaire de `/usr/sbin/sshd` ; le **paquet** propriétaire de `/etc/ssh/sshd_config` ; la ligne `Version` de `dnf info --installed openssh-server` ; le nombre de lignes renvoyées par `dnf repoquery --whatrequires openssh-clients`.
- Installe `zsh`, **gèle**-le avec `dnf versionlock add`, vérifie qu'il apparaît dans `dnf versionlock list`, puis **dégèle**-le.
- Supprime `zsh`, puis vérifie son état avec `rpm -q zsh`.

**Indices** (à consulter seulement si bloqué) :
- `rpm -qf /chemin` répond « quel paquet possède ce fichier ? ».
- `dnf info --installed paquet | grep -E '^(Version|Release)'`.
- `versionlock` est fourni par le paquet `python3-dnf-plugin-versionlock`.

**Critères de réussite** :
- [ ] `~/defi-dnf.txt` contient 4 lignes, la première mentionnant `openssh-server`.
- [ ] `dnf versionlock list` ne liste plus `zsh` à la fin.
- [ ] `rpm -q zsh` répond `package zsh is not installed`.
- [ ] Tu peux expliquer la différence entre `dnf` et `rpm`.

**Solution** (dans un bloc `<details>`) :

<details>
<summary>Voir la solution</summary>

```bash
{
  rpm -qf /usr/sbin/sshd
  rpm -qf /etc/ssh/sshd_config
  dnf info --installed openssh-server | grep -E '^Version'
  echo "whatrequires openssh-clients : $(dnf repoquery --whatrequires openssh-clients 2>/dev/null | wc -l) lignes"
} > ~/defi-dnf.txt
cat ~/defi-dnf.txt

sudo dnf install -y zsh python3-dnf-plugin-versionlock
sudo dnf versionlock add zsh
dnf versionlock list                   # zsh-...
sudo dnf versionlock delete zsh
dnf versionlock list                   # (vide ou sans zsh)

sudo dnf remove -y zsh
rpm -q zsh                             # package zsh is not installed
```

`rpm -qf` interroge la base des fichiers installés ; `dnf versionlock` empêche toute mise à jour du paquet (utile pour figer une version, au prix de ne plus recevoir ses correctifs de sécurité).

</details>

---

Atelier suivant : [Diagnostic réseau](atelier-03-diagnostic-reseau.md).
