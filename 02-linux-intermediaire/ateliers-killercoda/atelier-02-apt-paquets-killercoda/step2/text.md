# Étape 2 : le cycle de vie d'un paquet

Installez **nginx** (il laisse une configuration dans `/etc/nginx`) :

```bash
apt-get install -y nginx
ls /etc/nginx | head -n 5
dpkg -l nginx | tail -n 1
```{{exec}}

## À vous de jouer

1. **Supprimez** nginx avec `apt-get remove` : la configuration est **conservée** ;
2. Constatez l'état `rc` (*removed, config files remain*) et enregistrez-le dans `/tmp/etat-nginx.txt` ;
3. **Purgez** le paquet : la configuration est supprimée à son tour.

```bash
apt-get remove -y nginx
ls /etc/nginx | head -n 3
dpkg -l nginx | tail -n 1 | tee /tmp/etat-nginx.txt
```{{exec}}

```bash
apt-get purge -y nginx
apt-get autoremove -y
ls /etc/nginx 2>&1 | head -n 1
dpkg -l nginx 2>&1 | tail -n 1
```{{exec}}

> Quand préférer `remove` ? Pour réinstaller plus tard en gardant votre configuration. `purge` : pour repartir de zéro (ou ne rien laisser derrière soi).

Cliquez sur **Vérifier**.
