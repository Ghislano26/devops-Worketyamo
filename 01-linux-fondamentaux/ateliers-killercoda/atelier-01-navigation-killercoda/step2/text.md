# Étape 2 : trouver de l'aide et se faciliter la vie

Trois sources d'aide, de la plus rapide à la plus complète (voir le [cours Introduction](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/cours/01-introduction-linux.md)) :

```bash
ls --help | head -n 12
type cd
man ls | head -n 20
```{{exec}}

(Dans un `man`, `q` quitte, `/mot` cherche, `n` va à l'occurrence suivante.)

## À vous de jouer

**1.** Dans l'aide de `ls`, trouvez l'option longue qui affiche les tailles « lisibles par un humain » (`-h`), et enregistrez la ligne correspondante dans `/tmp/aide-ls.txt` :

```bash
ls --help | grep -- '--human-readable' > /tmp/aide-ls.txt
cat /tmp/aide-ls.txt
```{{exec}}

**2.** Créez l'alias **`ll`** = `ls -alh --color=auto` et rendez-le **persistant** en l'écrivant dans `~/.bashrc` (un alias tapé dans le terminal disparaît à la fermeture) :

```bash
echo "alias ll='ls -alh --color=auto'" >> ~/.bashrc
source ~/.bashrc
type ll
ll /tmp | head -n 5
```{{exec}}

> Pourquoi `source ~/.bashrc` ? Le fichier n'est lu qu'au démarrage du shell : `source` le relit dans le shell courant.

Cliquez sur **Vérifier**.
