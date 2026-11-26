#!/bin/bash
# Étape 2 : cgroup /sys/fs/cgroup/luc avec les limites attendues et un processus dedans
[ "$(stat -fc %T /sys/fs/cgroup)" = "cgroup2fs" ] || { echo "Ce système n'utilise pas cgroup v2."; exit 1; }
g=/sys/fs/cgroup/luc
[ -d "$g" ] || { echo "Le cgroup $g n'existe pas."; exit 1; }
[ "$(cat $g/memory.max 2>/dev/null)" = "52428800" ] || { echo "memory.max doit valoir 52428800 (50M). Valeur : $(cat $g/memory.max 2>/dev/null)."; exit 1; }
[ "$(cat $g/pids.max 2>/dev/null)" = "20" ] || { echo "pids.max doit valoir 20. Valeur : $(cat $g/pids.max 2>/dev/null)."; exit 1; }
[ "$(cat $g/cpu.max 2>/dev/null)" = "20000 100000" ] || { echo "cpu.max doit valoir « 20000 100000 »."; exit 1; }
if [ -z "$(cat $g/cgroup.procs 2>/dev/null)" ]; then
  echo "Aucun processus dans le cgroup : lancez « sleep 300 & » puis écrivez son PID dans $g/cgroup.procs."
  exit 1
fi
echo "OK : cgroup luc limité (50 Mo, 20 processus, 20 % CPU) et utilisé."
exit 0
