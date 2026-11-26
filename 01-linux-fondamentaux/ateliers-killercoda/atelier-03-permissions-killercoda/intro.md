# Permissions, propriétaire, setgid et sticky bit

**Durée : ~10 minutes.** Compétence travaillée : lire et écrire des permissions, première ligne de défense d'un serveur.

Prérequis : le cours [Utilisateurs et permissions](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/cours/04-utilisateurs-permissions.md).

Rappel : chaque fichier a un **propriétaire**, un **groupe** et trois jeux de droits (**user / group / others**) : `rwx` = 4 + 2 + 1.

```bash
ls -l /etc/passwd /etc/shadow /usr/bin/passwd
id
```{{exec}}

Notez `/usr/bin/passwd` : le `s` à la place du `x` du propriétaire est le bit **setuid**.
