#!/bin/bash
# Étape 2 : /srv/projet en 2770 root:devs (héritage du groupe), /srv/depot en 1777
if ! getent group devs >/dev/null; then
  echo "Le groupe « devs » n'existe pas (groupadd devs)."
  exit 1
fi
[ -d /srv/projet ] || { echo "/srv/projet n'existe pas."; exit 1; }
[ -d /srv/depot ]  || { echo "/srv/depot n'existe pas."; exit 1; }
if [ "$(stat -c '%a %U %G' /srv/projet)" != "2770 root devs" ]; then
  echo "/srv/projet doit être en « 2770 root devs » (actuel : $(stat -c '%a %U %G' /srv/projet))."
  exit 1
fi
if [ "$(stat -c '%a' /srv/depot)" != "1777" ]; then
  echo "/srv/depot doit être en 1777 (actuel : $(stat -c '%a' /srv/depot))."
  exit 1
fi
t=/srv/projet/.verif-setgid
touch "$t"
g=$(stat -c '%G' "$t")
rm -f "$t"
if [ "$g" != "devs" ]; then
  echo "Un fichier créé dans /srv/projet n'hérite pas du groupe devs (setgid absent ?)."
  exit 1
fi
echo "OK : setgid (2770) et sticky bit (1777) en place."
exit 0
