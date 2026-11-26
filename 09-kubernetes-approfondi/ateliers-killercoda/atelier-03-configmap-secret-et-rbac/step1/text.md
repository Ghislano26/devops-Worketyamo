# Étape 1 : configuration et secret

Créez un namespace dédié, puis un **ConfigMap** (configuration non sensible) et un **Secret** (donnée sensible) :

```bash
kubectl create namespace atelier
kubectl create configmap app-config -n atelier \
  --from-literal=APP_MODE=prod \
  --from-literal=LOG_LEVEL=info \
  --from-literal=app.properties='server.port=8080'
kubectl create secret generic app-secret -n atelier \
  --from-literal=DB_USER=app \
  --from-literal=DB_PASSWORD=MotDePasse123
```{{exec}}

Un Secret est **encodé en base64, pas chiffré** (voir le [cours 05](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/05-configuration-et-secrets.md)) : décodez-le pour vous en convaincre.

```bash
kubectl get secret app-secret -n atelier -o jsonpath='{.data.DB_PASSWORD}' ; echo
kubectl get secret app-secret -n atelier -o jsonpath='{.data.DB_PASSWORD}' | base64 -d ; echo
```{{exec}}

## Les consommer dans un Pod

Le pod **`demo`** reçoit `APP_MODE` et `DB_PASSWORD` en **variables d'environnement**, et monte le ConfigMap dans `/etc/config` et le Secret dans `/etc/secret` en **fichiers** :

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: demo
  namespace: atelier
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      env:
        - name: APP_MODE
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_MODE
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: DB_PASSWORD
      volumeMounts:
        - name: config
          mountPath: /etc/config
          readOnly: true
        - name: secret
          mountPath: /etc/secret
          readOnly: true
  volumes:
    - name: config
      configMap:
        name: app-config
    - name: secret
      secret:
        secretName: app-secret
        defaultMode: 0400
EOF
kubectl wait --for=condition=Ready pod/demo -n atelier --timeout=90s
```{{exec}}

Vérifiez les valeurs **dans** le conteneur :

```bash
kubectl exec -n atelier demo -- printenv APP_MODE DB_PASSWORD
kubectl exec -n atelier demo -- ls -l /etc/config /etc/secret
kubectl exec -n atelier demo -- cat /etc/config/app.properties
kubectl exec -n atelier demo -- cat /etc/secret/DB_PASSWORD ; echo
```{{exec}}

## Questions

- Chaque **clé** du ConfigMap est devenue un **fichier** dans `/etc/config`. Lesquels voyez-vous ?
- Modifiez le ConfigMap (`kubectl edit configmap app-config -n atelier`, changez `APP_MODE`). Que voit le pod dans la **variable** ? Et dans le **fichier** (attendez ~1 minute) ? (Variables : figées ; fichiers : mis à jour. Voir le [cours 05](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/05-configuration-et-secrets.md).)
- Pourquoi préférer un **fichier** à une variable d'environnement pour un mot de passe ?

Remettez `APP_MODE: prod` avant de cliquer sur **Vérifier**.
