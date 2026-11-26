# Étape 2 : modifier un fichier sans le casser

Créez un faux fichier de configuration SSH :

```bash
cd /tmp/luc
cat > sshd_config.test <<'EOF'
# Configuration de test
Port 22
PermitRootLogin yes
PasswordAuthentication yes

#X11Forwarding yes
MaxAuthTries 6
EOF
```{{exec}}

**Règle d'or de `sed -i`** : modifier un fichier en place est **définitif**. On teste d'abord sans `-i`, puis on garde une sauvegarde avec `-i.bak` :

```bash
sed 's/^PermitRootLogin.*/PermitRootLogin no/' sshd_config.test      # aperçu seulement
```{{exec}}

## À vous de jouer

1. Copiez le fichier en `sshd_config.work` ;
2. Avec **un seul** `sed -i.bak`, passez `PermitRootLogin` et `PasswordAuthentication` à `no` (motif `^Directive.*` : robuste quelle que soit la valeur d'origine) ;
3. Produisez `sans-commentaires.txt` : le fichier modifié **sans les commentaires ni les lignes vides**.

```bash
cp sshd_config.test sshd_config.work
sed -i.bak -e 's/^PermitRootLogin.*/PermitRootLogin no/' -e 's/^PasswordAuthentication.*/PasswordAuthentication no/' sshd_config.work
diff sshd_config.work.bak sshd_config.work
sed '/^#/d;/^$/d' sshd_config.work > sans-commentaires.txt
cat sans-commentaires.txt
```{{exec}}

Cliquez sur **Vérifier**.
