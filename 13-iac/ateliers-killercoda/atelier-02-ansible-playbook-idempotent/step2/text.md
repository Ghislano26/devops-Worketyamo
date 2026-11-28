# Étape 2 : prouver l'idempotence

## A. Le deuxième passage

Relancez **exactement** le même playbook, sans rien modifier, et gardez la trace :

```bash
cd ~/ansible-nginx
ansible-playbook site.yml | tee run2.log
grep -E 'changed=|failed=' run2.log
```{{exec}}

Le récapitulatif doit afficher **`changed=0`** : toutes les tâches sont `ok`, **rien** n'a été modifié, et le handler ne s'est pas déclenché. C'est la **preuve d'idempotence**.

## B. Simuler, puis corriger une dérive

Quelqu'un change le port **à la main** sur le serveur :

```bash
sed -i 's/listen 8080/listen 9090/' /etc/nginx/conf.d/atelier.conf
systemctl reload nginx
curl -s --max-time 3 http://localhost:8080 || echo "le port 8080 ne répond plus"
```{{exec}}

Avant de corriger, **simulez** avec `--check --diff` : Ansible montre **ce qu'il changerait**, sans rien modifier.

```bash
ansible-playbook site.yml --check --diff
```{{exec}}

Appliquez ensuite pour **remettre la machine dans l'état voulu**, puis relancez **encore une fois** : on doit revenir à `changed=0`.

```bash
ansible-playbook site.yml
ansible-playbook site.yml | tee run-final.log
grep -E 'changed=|failed=' run-final.log
curl -s http://localhost:8080
```{{exec}}

## Questions

- Au premier passage, combien de tâches étaient `changed` ? Au second ? Et après la correction de la dérive ? *(Une seule : la configuration, puis le handler.)*
- Pourquoi `--check` n'est-il pas toujours fiable ? *(Une tâche qui dépend du résultat d'une précédente non exécutée peut échouer en simulation.)*

Cliquez sur **Vérifier** : le script relance le playbook et contrôle `changed=0`.
