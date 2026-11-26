#!/bin/bash
# Étape 1 : jq installé, /tmp/jq-paquet.txt issu de dpkg -S
if ! dpkg -s jq 2>/dev/null | grep -q '^Status: install ok installed'; then
  echo "Le paquet jq n'est pas installé (apt-get install -y jq)."
  exit 1
fi
if ! grep -q '^jq.*: /usr/bin/jq' /tmp/jq-paquet.txt 2>/dev/null; then
  echo "/tmp/jq-paquet.txt doit contenir la sortie de « dpkg -S /usr/bin/jq » (jq: /usr/bin/jq)."
  exit 1
fi
echo "OK : jq installé et son paquet identifié."
exit 0
