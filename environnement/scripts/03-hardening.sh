#!/usr/bin/env bash
# 03-hardening.sh — durcissement léger de la box + nettoyage avant empaquetage.
# Dernier script exécuté par Packer (root). Les réglages SSH s'appliquent au prochain démarrage
# afin de ne pas couper la session de Packer pendant le build.
set -euo pipefail

log() { echo "==> [03-hardening] $*"; }

# --- Pare-feu : firewalld actif, SSH autorisé --------------------------------------------------
log "firewalld : activation et ouverture de SSH (22)"
dnf install -y firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# --- SSH : pas de root, pas de mot de passe, clé publique uniquement --------------------------
# Un fichier de configuration « 00-… » est lu AVANT ceux de la distribution (50-redhat.conf) :
# avec sshd la première valeur rencontrée l'emporte.
log "sshd : durcissement (effectif au prochain démarrage)"
cat > /etc/ssh/sshd_config.d/00-worketyamo-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
EOF
chmod 0600 /etc/ssh/sshd_config.d/00-worketyamo-hardening.conf
sshd -t   # valide la configuration : échoue (et arrête le build) si elle est invalide

# --- SELinux : mode permissif persistant ----------------------------------------------------
# Choix pédagogique : en mode « permissive », SELinux journalise les refus sans bloquer, ce qui
# évite que les premiers ateliers échouent pour une raison que les étudiants ne maîtrisent pas
# encore. Les refus restent visibles (ausearch -m avc, journalctl).
# TODO : passer en « enforcing » quand les cours Rocky incluront une partie SELinux.
log "SELinux : mode permissif persistant"
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
setenforce 0 2>/dev/null || true

# --- Services inutiles ------------------------------------------------------------------------
if systemctl cat postfix.service &>/dev/null; then
  log "postfix : désactivation"
  systemctl disable --now postfix || true
fi

# --- Nettoyage avant empaquetage (box plus petite, pas de traces du build) -----------------------
log "Nettoyage"
dnf clean all
rm -rf /var/cache/dnf /var/tmp/*   # /tmp est laissé : Packer y dépose ses scripts
: > /etc/machine-id
rm -f /root/.bash_history /home/vagrant/.bash_history /root/ks-post.log
journalctl --rotate && journalctl --vacuum-time=1s || true
# Remplit l'espace libre de zéros puis le libère : le disque se compresse bien mieux.
dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true
rm -f /EMPTY
sync

log "Terminé : la VM va être éteinte par Packer"
