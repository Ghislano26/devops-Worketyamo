# Étape 2 : manipuler les fichiers

Il n'y a **pas de corbeille** en ligne de commande : `rm` est définitif. Pensez-y avant chaque suppression.

Dans `/tmp/devops`, réalisez ces quatre opérations :

1. **Copier** `config/app.conf` vers `config/app.conf.bak` ;
2. **Renommer** `scripts/deploy.sh` en `scripts/deploy-v1.sh` ;
3. **Déplacer** `logs/app.log` dans un nouveau dossier `archive/` ;
4. **Supprimer** le dossier `logs/`, maintenant vide (avec `rmdir`, qui refuse un dossier non vide : c'est une sécurité).

```bash
cd /tmp/devops
cp config/app.conf config/app.conf.bak
mv scripts/deploy.sh scripts/deploy-v1.sh
mkdir archive && mv logs/app.log archive/
rmdir logs
find /tmp/devops | sort
```{{exec}}

Prouvez que la copie est identique à l'original :

```bash
cmp config/app.conf config/app.conf.bak && echo "copie identique"
```{{exec}}

## État final attendu

```text
/tmp/devops
├── archive/app.log
├── config/app.conf
├── config/app.conf.bak
└── scripts/deploy-v1.sh          (plus de deploy.sh, plus de dossier logs)
```

> Pourquoi `mv` sert-il à la fois à déplacer et à renommer ? Parce que, dans les deux cas, on change l'**entrée du répertoire** (nom et emplacement) sans toucher aux données.

Cliquez sur **Vérifier**.
