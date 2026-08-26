#!/usr/bin/env bash
# Verifica que existan los tres scripts (ejecutables), entrega.env completo,
# cron/systemd, la evidencia del trabajo en aula y las dos entregas de
# evidencia (v1 y v2).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

ok=1
[ -x "scripts/respaldo_db.sh" ] || ok=0
[ -x "scripts/respaldo_321.sh" ] || ok=0
[ -x "scripts/restaurar.sh" ] || ok=0
[ -s "practica/diseno_321.md" ] || ok=0
[ -s "cron/respaldo.cron" ] || ok=0
[ -s "systemd/respaldo.service" ] || ok=0
[ -s "systemd/respaldo.timer" ] || ok=0

[ -s "entrega.env" ] || ok=0
if [ -s "entrega.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source entrega.env 2>/dev/null || ok=0
  set +a
  [ -n "${CARNET:-}" ] || ok=0
  [ -n "${DOMINIO:-}" ] || ok=0
  [ "${DOMINIO:-}" != "tienda.tucarnet.duckdns.org" ] || ok=0
fi

for f in evidencia/v1/respaldo_db.sql.gz evidencia/v1/respaldo_sitio.tar.gz \
         evidencia/v2/respaldo_db.sql.gz evidencia/v2/respaldo_sitio.tar.gz; do
  [ -s "$f" ] || ok=0
done

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
