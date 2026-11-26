# Bravo !

Vous avez :

- décrit une pile multi-services dans un **fichier versionnable** ;
- observé le **DNS interne** (`127.0.0.11`) qui permet à `backend` de joindre `redis` par son nom ;
- ordonnancé le démarrage avec un **`healthcheck`** et `condition: service_healthy` ;
- **publié** un port (règle DNAT) et utilisé `docker compose exec`.

## Nettoyage

```bash
cd ~/atelier3 && docker compose down -v
```{{exec}}

## Pour aller plus loin

- Ajoutez un second réseau `front` et une image `nginx` qui ne joint que `front` et `backend` (isolation de la base).
- Passez le réseau en `internal: true` : le backend peut-il encore sortir sur Internet ?
- Passez au [module 09 : Kubernetes](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/README.md) : Deployments, Services et Ingress remplacent Compose à l'échelle d'un cluster.
