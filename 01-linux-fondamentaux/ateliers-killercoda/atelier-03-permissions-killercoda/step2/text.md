# Étape 2 : deux dossiers partagés, deux comportements

Deux besoins différents :

| Besoin | Mécanisme | Mode attendu |
|---|---|---|
| Les fichiers créés dans un dossier de projet doivent **hériter du groupe** du dossier | **setgid** sur le dossier | **`2770`** |
| Un dépôt public où chacun écrit mais **ne peut supprimer que ses propres fichiers** | **sticky bit** (comme `/tmp`) | **`1777`** |

## À vous de jouer

1. Créez le groupe **`devs`** ;
2. Créez **`/srv/projet`** : propriétaire `root`, groupe `devs`, mode **`2770`** ;
3. Créez **`/srv/depot`** en mode **`1777`**.

```bash
groupadd devs
mkdir -p /srv/projet /srv/depot
chown root:devs /srv/projet
chmod 2770 /srv/projet
chmod 1777 /srv/depot
ls -ld /srv/projet /srv/depot
```{{exec}}

Observez les lettres : `drwxrws---` (le `s` du groupe = setgid) et `drwxrwxrwt` (le `t` final = sticky). Testez l'**héritage du groupe** :

```bash
touch /srv/projet/fichier-test
ls -l /srv/projet/fichier-test
```{{exec}}

Le fichier appartient au groupe **`devs`**, alors que votre groupe principal est `root` : c'est l'effet du setgid. Comparez avec `/srv/depot` :

```bash
ls -ld /tmp /srv/depot
```{{exec}}

Cliquez sur **Vérifier**.
