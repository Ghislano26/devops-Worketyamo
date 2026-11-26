# Étape 1 : lancer un serveur web

Un conteneur se lance depuis une **image**. Ici, l'image officielle `nginx` (version précise, jamais `latest` : voir le [cours 02](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/02-images-et-couches.md)).

Lancez nginx en arrière-plan, nommé **`web`**, en publiant son port 80 sur le **port 8080** de la machine :

```bash
docker run -d --name web -p 8080:80 nginx:1.27
```{{exec}}

Vérifiez qu'il tourne et quel port est publié :

```bash
docker ps
docker port web
```{{exec}}

Interrogez-le depuis la machine :

```bash
curl -s localhost:8080 | head -n 5
```{{exec}}

Vous devez voir la page « Welcome to nginx! ».

## Pour comprendre

Observez le conteneur comme un processus de l'hôte et la règle de publication de port (DNAT) créée par Docker :

```bash
docker inspect -f 'PID={{.State.Pid}} IP={{.NetworkSettings.IPAddress}}' web
iptables -t nat -S DOCKER | grep 8080
```{{exec}}

> Pourquoi `-d` ? Sans lui, le conteneur occuperait le terminal (premier plan). Pourquoi `-p 8080:80` ? `EXPOSE` ne publie rien : seul `-p` crée la redirection. Voir le [cours 04](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/04-reseau-et-stockage-docker.md).

Quand c'est fait, cliquez sur **Vérifier**.
