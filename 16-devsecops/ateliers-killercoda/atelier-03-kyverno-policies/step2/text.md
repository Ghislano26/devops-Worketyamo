# Étape 2 : tester un pod conforme et des pods non conformes

## A. Un pod conforme

Un tag précis : la politique **laisse passer**.

```bash
kubectl run web-ok --image=nginx:1.27-alpine
kubectl wait --for=condition=Ready pod/web-ok --timeout=180s
kubectl get pod web-ok
```{{exec}}

## B. Deux pods non conformes

`:latest` explicite, puis **aucun tag** :

```bash
kubectl run web-latest --image=nginx:latest
kubectl run web-notag --image=nginx
kubectl get pods
```{{exec}}

Chaque création est **refusée** avec un message qui nomme la politique et la règle (`interdire-latest`, `pas-de-latest` / `tag-obligatoire`) : c'est le message **écrit pour le développeur**, pas pour l'administrateur. Aucun des deux pods n'existe.

> Pour tester **sans rien créer** (utile en CI) : `kubectl run test --image=nginx:latest --dry-run=server`. Le `dry-run=server` traverse **le vrai webhook**.

## C. Mode Audit : observer sans bloquer

Avant d'imposer une politique en production, on la déploie en **Audit** pour **mesurer** l'impact sans casser personne :

```bash
kubectl patch clusterpolicy interdire-latest --type merge -p '{"spec":{"validationFailureAction":"Audit"}}'
sleep 5
kubectl run audit-latest --image=nginx:latest
kubectl get pod audit-latest
```{{exec}}

Le pod est **créé** (Audit n'interdit rien) mais la violation est **consignée** dans un rapport de politique :

```bash
sleep 10
kubectl get policyreport -A
kubectl get policyreport -n default -o jsonpath='{range .items[*].results[?(@.result=="fail")]}{.policy}{" / "}{.rule}{"\n"}{end}'
```{{exec}}

## D. Retour en Enforce et nettoyage

On supprime le pod fautif et on **réactive** `Enforce` :

```bash
kubectl delete pod audit-latest --now
kubectl patch clusterpolicy interdire-latest --type merge -p '{"spec":{"validationFailureAction":"Enforce"}}'
sleep 5
kubectl run encore-latest --image=nginx:latest --dry-run=server; echo "code de sortie : $?"
kubectl get pods
```{{exec}}

Le `dry-run` est de nouveau **refusé** (code non nul).

## Questions

- Pourquoi ne pas passer directement en `Enforce` sur un cluster existant ? *(Des charges légitimes utilisent peut-être `:latest` : on mesure d'abord (Audit), on corrige, puis on bloque.)*
- Que se passe-t-il pour un pod **déjà en cours d'exécution** en `:latest` lorsque la politique passe en `Enforce` ? *(Il continue de tourner : l'admission ne s'applique qu'aux **nouvelles** requêtes ; il apparaît dans les rapports de fond.)*

Cliquez sur **Vérifier**.
