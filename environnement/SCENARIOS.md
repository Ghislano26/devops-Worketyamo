# 🎬 Scénarios concrets : que faire quand… ?

> Huit situations réelles, chacune avec **symptôme → diagnostic → solution → prévention**.
> Guide complet : [`GUIDE-ENVIRONNEMENT.md`](../GUIDE-ENVIRONNEMENT.md) · Aide-mémoire : [`CHEATSHEET.md`](CHEATSHEET.md)

| # | Situation |
|---|---|
| 1 | [Je veux commencer l'atelier X du module Y](#scénario-1--je-veux-commencer-latelier-x-du-module-y) |
| 2 | [J'ai fait une erreur et je veux revenir en arrière](#scénario-2--jai-fait-une-erreur-et-je-veux-revenir-en-arrière) |
| 3 | [Ma VM ne démarre plus](#scénario-3--ma-vm-ne-démarre-plus) |
| 4 | [Je veux sauvegarder mon travail avant de tester quelque chose de risqué](#scénario-4--je-veux-sauvegarder-mon-travail-avant-de-tester-quelque-chose-de-risqué) |
| 5 | [Je dois transférer un fichier de mon Windows vers la VM](#scénario-5--je-dois-transférer-un-fichier-de-mon-windows-vers-la-vm) |
| 6 | [Je suis sur Mac ARM et je n'ai pas VirtualBox](#scénario-6--je-suis-sur-mac-arm-et-je-nai-pas-virtualbox) |
| 7 | [Je change d'ordinateur](#scénario-7--je-change-dordinateur) |
| 8 | [J'ai cassé ma VM et je veux repartir de zéro](#scénario-8--jai-cassé-ma-vm-et-je-veux-repartir-de-zéro) |

---

## Scénario 1 — Je veux commencer l'atelier X du module Y

**Symptôme** : tu ouvres le cours du jour (par exemple *module 02, atelier 03*) et tu ne sais pas par où commencer, ni dans quel terminal taper les commandes.

**Diagnostic** : trois questions.

1. La VM est-elle démarrée ? → `vagrant status` (hôte).
2. Suis-je dans la VM ? → `hostname` doit afficher `devops-lab`.
3. Ai-je un filet de sécurité ? → `vagrant snapshot list` doit montrer au moins `clean`.

**Solution — le workflow complet**

*Sur l'hôte :*

```bash
cd devops-Worketyamo/environnement/vagrant
git -C ../.. pull                         # dernières corrections du cours
vagrant up                                # démarre (ou ne fait rien si déjà démarrée)
vagrant snapshot save avant-m02-a03       # filet de sécurité
vagrant ssh
```

*Dans la VM :*

```bash
hostname                                  # devops-lab : je suis au bon endroit
mkdir -p ~/ateliers/m02-a03 && cd ~/ateliers/m02-a03
less /vagrant/02-linux-intermediaire/ateliers/atelier-03-*.md    # lire l'énoncé (q pour quitter)
# ... réaliser l'atelier, en tapant chaque commande toi-même ...
cp -r ~/ateliers/m02-a03 /vagrant/mes-travaux/       # sauvegarde côté hôte
exit
```

*Sur l'hôte :*

```bash
vagrant halt
```

**Prévention** : prends l'habitude d'un nom de dossier `mXX-aYY` par atelier, d'un snapshot **avant** chaque atelier risqué et d'une sauvegarde dans `/vagrant/mes-travaux/` **après**. Vérifie à la fin avec la **checklist de compétences** du module.

---

## Scénario 2 — J'ai fait une erreur et je veux revenir en arrière

**Symptôme** : une commande a cassé quelque chose (mauvais `chmod -R`, `/etc/fstab` modifié, service supprimé, `rm` trop large) et tu veux simplement « annuler ».

**Diagnostic** : l'erreur est-elle **récupérable à la main** ?

| Situation | Récupérable ? | Action |
|---|---|---|
| Fichier de configuration modifié, tu as une copie `.bak` | Oui | `sudo cp fichier.bak fichier` |
| Mauvais `chmod`/`chown` récursif sur ton home | Parfois | Corriger les droits un à un, sinon snapshot |
| Paquet supprimé | Oui | `sudo dnf install -y <paquet>` |
| `/etc/fstab`, `sshd_config`, `sudoers` cassés, ou système qui ne démarre plus | Difficile | **Snapshot** |
| `rm -rf` sur des fichiers système | Non | **Snapshot** |

**Solution : restaurer le dernier bon snapshot**

```bash
# Hôte
vagrant snapshot list                       # quel snapshot avant la bêtise ?
```

Si ton travail récent est dans la VM, **copie-le avant** de restaurer (si la VM répond encore) :

```bash
vagrant ssh -c 'mkdir -p /vagrant/mes-travaux && cp -r ~/ateliers /vagrant/mes-travaux/avant-restauration'
vagrant snapshot restore avant-m02-a03      # ou « clean »
vagrant ssh
```

> ⚠️ Tout ce qui a été fait **après** le snapshot est perdu, y compris tes fichiers dans `~` (d'où la copie préalable dans `/vagrant`).

**Prévention** : snapshot avant LVM, pare-feu, durcissement, `fstab`, `sshd_config`, `sudoers`, `dnf update`. Pour les fichiers de configuration, fais **toujours** une copie avant de modifier : `sudo cp -a /etc/fstab /etc/fstab.bak`.

---

## Scénario 3 — Ma VM ne démarre plus

**Symptôme** : `vagrant up` échoue, reste bloqué sur `Waiting for machine to boot…`, ou `vagrant ssh` répond `Connection refused` / `timeout`.

**Diagnostic — étape par étape**

1. **Lire l'état** :

```bash
vagrant status                  # running / poweroff / aborted / not created
VBoxManage list runningvms      # la VM tourne-t-elle côté VirtualBox ?
```

2. **Lire l'erreur** en entier ; consulte la table du [guide § 10](../GUIDE-ENVIRONNEMENT.md#10-dépannage). Erreurs classiques : « VT-x is not available » (BIOS), « Hyper-V » (Windows), « box not found » (box non ajoutée), « Permission denied (publickey) » (`vagrant reload`).

3. **Voir la console de la VM** : dans le `Vagrantfile`, mets `vb.gui = true`, puis `vagrant reload`. Une fenêtre s'ouvre : tu vois si le système plante au démarrage (écran d'erreur, `fsck`, `emergency mode`).

4. **Journaux détaillés** :

```bash
vagrant up --debug 2>&1 | tee debug.log
tail -n 40 debug.log
```

5. **Machine fantôme ou verrou** : `vagrant global-status --prune`, puis dans VirtualBox, vérifie qu'aucune VM `devops-lab` en état « Aborted » ne bloque.

**Solution — du plus doux au plus radical**

| Ordre | Action | Commande |
|---|---|---|
| 1 | Redémarrer proprement | `vagrant halt` puis `vagrant up` |
| 2 | Forcer un rechargement | `vagrant reload` |
| 3 | Redémarrer l'ordinateur hôte | (règle beaucoup de problèmes de pilotes) |
| 4 | Restaurer un snapshot | `vagrant snapshot restore clean` |
| 5 | Recréer la VM | `vagrant destroy -f && vagrant up` (⚠️ perte des données de la VM) |
| 6 | Réinstaller la box | `vagrant box remove rocky9-devops` puis `vagrant box add …` |

**Prévention** : toujours **`vagrant halt`** (jamais de coupure brutale), garder un snapshot `clean`, ne pas laisser le disque se remplir (`df -h`), mettre à jour VirtualBox **avec** les pilotes, et sauvegarder tes travaux dans `/vagrant/mes-travaux/`.

---

## Scénario 4 — Je veux sauvegarder mon travail avant de tester quelque chose de risqué

**Symptôme** : tu vas lancer un atelier dangereux (LVM, pare-feu, modification de `sshd_config`, `chmod -R`) ou une expérience personnelle, et tu as peur de perdre ton travail.

**Diagnostic** : que veux-tu protéger ?

| À protéger | Outil | Rapidité |
|---|---|---|
| **L'état du système** (configuration, paquets) | Snapshot Vagrant | 10 s |
| **Tes fichiers** (ateliers, notes) | Archive dans `/vagrant/mes-travaux/` ou Git | 10 s |
| **Tout, de façon durable** (changement de machine) | Archive hors de l'ordinateur + `vagrant package` | quelques minutes |

**Solution — procédure « filet double »**

*Dans la VM : sauvegarde des fichiers*

```bash
mkdir -p /vagrant/mes-travaux
tar czf /vagrant/mes-travaux/backup-$(date +%F-%H%M).tar.gz -C ~ ateliers notes
ls -lh /vagrant/mes-travaux/backup-*.tar.gz
tar tzf /vagrant/mes-travaux/backup-*.tar.gz | head -n 5     # vérifier le contenu
exit
```

*Sur l'hôte : snapshot de l'état du système*

```bash
vagrant snapshot save avant-test-risque
vagrant snapshot list
vagrant ssh                                  # tu peux tester !
```

*Si ça tourne mal :*

```bash
vagrant snapshot restore avant-test-risque
vagrant ssh -c 'tar xzf /vagrant/mes-travaux/backup-*.tar.gz -C ~'     # remettre les fichiers récents
```

*Si tout s'est bien passé :* garde le snapshot jusqu'à la fin de l'atelier, puis supprime-le : `vagrant snapshot delete avant-test-risque`.

**Prévention** : fais de l'archive + snapshot un **réflexe** avant chaque atelier marqué « risqué » (LVM, durcissement, SELinux, pare-feu). Pense à `git push` pour tes scripts versionnés.

---

## Scénario 5 — Je dois transférer un fichier de mon Windows vers la VM

**Symptôme** : tu as un script, un énoncé ou un fichier de données sur ton PC Windows (`C:\Users\Moi\Documents\fichier.txt`) et tu en as besoin dans la VM.

**Diagnostic** : combien de fichiers, et à quelle fréquence ?

| Besoin | Méthode conseillée |
|---|---|
| Échanges **fréquents**, dossier de travail | Dossier synchronisé `/vagrant` |
| **Un fichier** de temps en temps | `vagrant upload` |
| **Quelques lignes** de script | Copier-coller dans le terminal |
| Fichiers **versionnés** | Git |

**Solution — trois méthodes**

*Méthode 1 : dossier synchronisé* — copie le fichier dans le dossier du dépôt côté Windows, par exemple `C:\formation\devops-Worketyamo\mes-travaux\fichier.txt`. Dans la VM :

```bash
ls /vagrant/mes-travaux/
cp /vagrant/mes-travaux/fichier.txt ~/ateliers/
```

*Méthode 2 : `vagrant upload`* — dans PowerShell, dossier du `Vagrantfile` :

```powershell
vagrant upload C:\Users\Moi\Documents\fichier.txt /home/vagrant/ateliers/fichier.txt
```

*Méthode 3 : copier-coller* — ouvre le fichier sous Windows, copie le contenu, puis dans la VM :

```bash
cat > ~/ateliers/script.sh <<'EOF'
(coller ici le contenu)
EOF
chmod +x ~/ateliers/script.sh
```

*Pour récupérer un fichier de la VM vers Windows* : copie-le dans `/vagrant/mes-travaux/` (il apparaît côté Windows), ou utilise `scp` avec les paramètres de `vagrant ssh-config`.

**Prévention** : crée dès le début `C:\formation\devops-Worketyamo\mes-travaux\` (partagé en `/vagrant/mes-travaux/`). Configure ton éditeur en **fins de ligne LF** pour les scripts ; sinon corrige avec `sed -i 's/\r$//' script.sh`. Ne modifie jamais le même fichier des deux côtés à la fois.

---

## Scénario 6 — Je suis sur Mac ARM et je n'ai pas VirtualBox

**Symptôme** : ton Mac a une puce Apple Silicon (M1/M2/M3/M4) ; VirtualBox ne fonctionne pas, ou la box `rocky9-devops` ne démarre pas (architecture x86_64).

**Diagnostic**

```bash
uname -m                    # arm64 → Apple Silicon ; x86_64 → Mac Intel (VirtualBox OK)
```

**Solution — par ordre de préférence**

1. **UTM + Rocky Linux 9 ARM64** (gratuit, même famille de distribution) :
   - `brew install --cask utm`
   - Télécharge l'ISO **Rocky Linux 9 aarch64** : <https://rockylinux.org/download>
   - Crée la VM (Virtualiser → Linux, 4 Go, 2 cœurs, 40 Go), installe Rocky, puis reproduis l'environnement :

```bash
sudo useradd -m -G wheel vagrant && sudo passwd vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
sudo hostnamectl set-hostname devops-lab
sudo dnf install -y git curl wget vim nano tmux jq tree rsync unzip tar python3
cat /etc/rocky-release && hostname          # contrôle
```

   - Prends un snapshot dans UTM (*Clone* ou *Save State*) comme référence.
   - Pas de `/vagrant` : utilise `scp` (`scp fichier vagrant@<IP-de-la-VM>:`), Git, ou le partage d'UTM.

2. **VMware Fusion + Vagrant `vmware_desktop`** (si ton formateur fournit une box ARM64 VMware).
3. **Killercoda uniquement** : tout dans le navigateur ([`KILLERCODA.md`](../KILLERCODA.md)) ; pas de persistance, mais aucune installation.

**Limites** : certaines images Docker n'existent qu'en `amd64` (`exec format error`) ; préfère des images multi-architecture ou `--platform linux/amd64` (émulation lente).

**Prévention** : avant d'acheter ou de configurer, vérifie `uname -m`. Signale ton architecture à ton formateur dès le début pour obtenir la bonne procédure.

---

## Scénario 7 — Je change d'ordinateur

**Symptôme** : nouvel ordinateur (ou réinstallation de Windows) ; tu dois retrouver ton environnement **et** ton travail.

**Diagnostic** : que dois-tu emporter ? **Seulement tes fichiers** (ateliers, notes, clés personnelles) : le système se recrée à partir de la box.

**Solution — migration complète**

*Sur l'ANCIENNE machine :*

```bash
vagrant up && vagrant ssh
# Dans la VM
mkdir -p /vagrant/mes-travaux
tar czf /vagrant/mes-travaux/backup-travail-$(date +%F).tar.gz -C ~ ateliers notes
tar tzf /vagrant/mes-travaux/backup-travail-*.tar.gz | head       # vérification
exit
```

Copie `backup-travail-….tar.gz` **hors de la machine** (clé USB, disque externe, cloud). Note ta **version de box** (`vagrant box list`) et tes réglages du `Vagrantfile` (RAM, CPU). Pousse tes dépôts Git (`git status` propre, `git push`).

*Sur la NOUVELLE machine :*

1. Active la **virtualisation** dans le BIOS, installe **VirtualBox 7.x** et **Vagrant 2.4+** ([guide, chapitre 2](../GUIDE-ENVIRONNEMENT.md#2-installation-de-lenvironnement)).
2. `git clone https://github.com/Ghislano26/devops-Worketyamo.git`
3. Télécharge la box sur [GitHub Releases](https://github.com/Ghislano26/devops-Worketyamo/releases), puis :

```bash
vagrant box add rocky9-devops rocky9-devops-1.0.0.box
cd devops-Worketyamo/environnement/vagrant
vagrant up
vagrant snapshot save clean
```

4. Restaure ton travail : place l'archive dans `mes-travaux/` puis, dans la VM :

```bash
tar xzf /vagrant/mes-travaux/backup-travail-2025-12-01.tar.gz -C ~
ls ~/ateliers ~/notes
```

**Variante lourde** : `vagrant package --output ma-vm.box` sur l'ancienne machine, puis `vagrant box add ma-vm ma-vm.box` (≈ 1,5 à 3 Go).

**Prévention** : sauvegarde **régulièrement** (Git ou archive) et pas seulement au moment de changer de machine. Conserve le fichier `.box` d'origine sur un disque externe.

---

## Scénario 8 — J'ai cassé ma VM et je veux repartir de zéro

**Symptôme** : la VM est dans un état incohérent (paquets cassés, système qui ne démarre pas, configuration irrécupérable) et aucun snapshot ne convient.

**Diagnostic** : avant de tout détruire, as-tu **récupéré ce qui a de la valeur** ?

```bash
vagrant status
vagrant ssh -c 'ls ~/ateliers ~/notes'      # la VM répond-elle encore ?
```

| Si la VM… | Alors |
|---|---|
| répond à `vagrant ssh` | Sauvegarde ses fichiers (ci-dessous) puis recrée |
| ne répond plus | Tente `vagrant reload` ; sinon accepte la perte (les fichiers dans `/vagrant/…` côté hôte sont intacts) |

**Solution**

```bash
# 1. Sauvegarde éventuelle (si la VM répond)
vagrant ssh -c 'mkdir -p /vagrant/mes-travaux && tar czf /vagrant/mes-travaux/avant-reset-$(date +%F).tar.gz -C ~ ateliers notes'

# 2. Destruction et recréation (⚠️ irréversible pour le contenu de la VM)
vagrant destroy -f
vagrant up

# 3. Nouvelle référence
vagrant ssh -c 'hostname && cat /etc/rocky-release'
vagrant snapshot save clean

# 4. Restauration du travail
vagrant ssh -c 'tar xzf /vagrant/mes-travaux/avant-reset-*.tar.gz -C ~ && ls ~/ateliers'
```

Si `vagrant up` échoue encore après la recréation : réinstalle la box.

```bash
vagrant box remove rocky9-devops
vagrant box add rocky9-devops rocky9-devops-1.0.0.box
vagrant up
```

**Prévention** : un snapshot `clean` pris juste après l'installation évite la plupart des remises à zéro (`vagrant snapshot restore clean` : 30 secondes). Sauvegarde ton travail dans `/vagrant/mes-travaux/` **avant** toute opération risquée.
