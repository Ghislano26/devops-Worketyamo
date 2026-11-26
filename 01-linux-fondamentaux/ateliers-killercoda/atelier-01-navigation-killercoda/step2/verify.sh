#!/bin/bash
# Étape 2 : aide de ls consultée et alias ll persistant
if ! grep -q -- '--human-readable' /tmp/aide-ls.txt 2>/dev/null; then
  echo "/tmp/aide-ls.txt doit contenir la ligne d'aide de --human-readable (ls --help | grep -- '--human-readable')."
  exit 1
fi
if ! grep -qE "^alias ll=" "$HOME/.bashrc" 2>/dev/null; then
  echo "L'alias ll n'est pas défini dans ~/.bashrc."
  exit 1
fi
if ! bash -ic 'alias ll' 2>/dev/null | grep -q 'ls'; then
  echo "L'alias ll ne fonctionne pas dans un nouveau shell interactif : vérifiez la syntaxe dans ~/.bashrc."
  exit 1
fi
echo "OK : aide consultée et alias ll persistant."
exit 0
