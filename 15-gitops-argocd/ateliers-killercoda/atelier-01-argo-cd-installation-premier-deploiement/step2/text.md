# Étape 2 : mot de passe admin, port-forward et CLI

## A. Mot de passe initial

Argo CD génère un mot de passe pour `admin` dans un Secret :

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```{{exec}}

> En production, on **change** ce mot de passe, on **supprime** ce Secret et on passe au **SSO** (voir le [cours architecture](https://github.com/Ghislano26/devops-Worketyamo/blob/main/15-gitops-argocd/cours/02-argo-cd-architecture.md)).

## B. Exposer le serveur

Le Service `argocd-server` est interne. On l'expose en **port-forward**, en arrière-plan :

```bash
nohup kubectl -n argocd port-forward svc/argocd-server --address 0.0.0.0 8080:443 > /tmp/port-forward.log 2>&1 &
sleep 3
curl -sk -o /dev/null -w "HTTP %{http_code}\n" https://localhost:8080/
```{{exec}}

Vous devez lire `HTTP 200` (l'interface web répond ; le certificat est auto-signé, d'où `-k`). Sur Killercoda, vous pouvez aussi ouvrir l'interface via le menu **Traffic / Ports** (port `8080`, protocole HTTPS) et vous connecter avec `admin` et le mot de passe ci-dessus.

## C. Installer et utiliser la CLI `argocd`

```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.13.3/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
argocd version --client
PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
argocd login localhost:8080 --username admin --password "$PASS" --insecure
argocd account get-user-info
argocd app list
```{{exec}}

`argocd app list` répond pour l'instant par une liste **vide** : aucune application n'est encore déclarée.

## Questions

- Pourquoi `--insecure` est-il acceptable **ici** et pas en production ? *(Certificat auto-signé sur un port-forward local ; en production, un Ingress avec un vrai certificat TLS.)*
- Que fait la CLI `argocd` à la place de `kubectl` ? *(Elle parle à l'**API d'Argo CD**, avec son authentification et son RBAC, pas à l'API Kubernetes.)*

Cliquez sur **Vérifier**.
