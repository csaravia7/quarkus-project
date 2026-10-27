#!/usr/bin/env bash
# El contenedor del Codespace no corre systemd: el servicio OneAgent se arranca en cada inicio vía init.d.
set -euo pipefail

[[ -x /etc/init.d/oneagent ]] || exit 0

if ! pgrep -f oneagentwatchdog >/dev/null; then
  echo ">> Iniciando servicio OneAgent..."
  sudo /etc/init.d/oneagent start
fi

# OneAgent solo instrumenta procesos que arrancan después de él
for _ in $(seq 1 60); do
  if pgrep -f oneagentwatchdog >/dev/null; then
    echo ">> OneAgent activo."
    exit 0
  fi
  sleep 2
done
echo ">> OneAgent no confirmó arranque. Revisa /var/log/dynatrace/oneagent/" >&2
exit 1
