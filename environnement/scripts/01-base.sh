#!/usr/bin/env bash
# 01-base.sh — paquets de base, configuration du poste de travail, Guest Additions VirtualBox.
# Exécuté en root par Packer (voir execute_command dans rocky9-devops.pkr.hcl). Idempotent.
set -euo pipefail

echo "==> [01-base] Paquets de base"
dnf install -y \
  vim git curl wget tmux jq tree bash-completion \
  podman buildah skopeo \
  make gcc python3 python3-pip nano rsync unzip tar

# --- Guest Additions VirtualBox (dossier partagé /vagrant) -----------------------------------
# Packer envoie l'ISO dans /tmp/VBoxGuestAdditions.iso ; on l'installe si elle est présente
# et si les modules ne sont pas déjà chargés.
GA_ISO="/tmp/VBoxGuestAdditions.iso"
if ! lsmod | grep -q '^vboxsf' && [[ -f "$GA_ISO" ]]; then
  echo "==> [01-base] Installation des Guest Additions"
  dnf install -y kernel-devel kernel-headers elfutils-libelf-devel bzip2 perl
  mkdir -p /mnt/ga
  mount -o loop,ro "$GA_ISO" /mnt/ga
  # Le script d'installation retourne un code non nul si l'interface graphique est absente : normal.
  sh /mnt/ga/VBoxLinuxAdditions.run --nox11 || true
  umount /mnt/ga
  rmdir /mnt/ga
  rm -f "$GA_ISO"
else
  echo "==> [01-base] Guest Additions : déjà présentes ou ISO absente (étape ignorée)"
fi

# --- Git : identité par défaut pour l'utilisateur vagrant ------------------------------------
echo "==> [01-base] Configuration de git"
sudo -u vagrant git config --global user.name  "DevOps Student"
sudo -u vagrant git config --global user.email "student@worketyamo.local"
sudo -u vagrant git config --global init.defaultBranch main
sudo -u vagrant git config --global pull.rebase false

# --- Vim de base -----------------------------------------------------------------------------
echo "==> [01-base] Configuration de vim"
cat > /home/vagrant/.vimrc <<'EOF'
" Configuration vim minimale pour le cursus
syntax on
set number
set tabstop=4 shiftwidth=4 expandtab
set autoindent
set hlsearch incsearch
set background=dark
EOF
chown vagrant:vagrant /home/vagrant/.vimrc

# --- Prompt bash : rend l'environnement reconnaissable ----------------------------------------
echo "==> [01-base] Configuration du prompt bash"
cat > /etc/profile.d/worketyamo.sh <<'EOF'
# Prompt : [utilisateur@devops-lab dossier]$  (vert pour l'utilisateur, jaune pour le dossier)
if [ -n "${BASH_VERSION:-}" ] && [ "$(id -u)" -ne 0 ]; then
  PS1='\[\e[1;32m\]\u@\h\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\]\$ '
fi
alias ll='ls -lah --color=auto'
alias ..='cd ..'
export EDITOR=vim
EOF
chmod 0644 /etc/profile.d/worketyamo.sh

# Dossier de travail des étudiants
install -d -o vagrant -g vagrant /home/vagrant/ateliers /home/vagrant/notes

echo "==> [01-base] Terminé"
