#!/usr/bin/env bash
# cron/respaldo.cron y systemd/respaldo.service+.timer deben apuntar al sitio
# real (mismo dominio de entrega.env), no a rutas de ejemplo genericas, y
# systemd debe traer las directivas minimas.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

ok=1

[ -s "entrega.env" ] || { echo "FAIL"; exit 0; }
set -a
# shellcheck disable=SC1091
source entrega.env 2>/dev/null || ok=0
set +a
[ -n "${DOMINIO:-}" ] || ok=0

CRON="cron/respaldo.cron"
SERVICE="systemd/respaldo.service"
TIMER="systemd/respaldo.timer"

[ -s "$CRON" ] || ok=0
[ -s "$SERVICE" ] || ok=0
[ -s "$TIMER" ] || ok=0

if [ "$ok" -eq 1 ]; then
  LINEA=$(grep -Ev '^[[:space:]]*(#|$)' "$CRON" | head -n1)
  [ -n "$LINEA" ] || ok=0

  read -r MIN HORA DIA MES SEMANA _RESTO <<< "$LINEA"
  for campo in "$MIN" "$HORA" "$DIA" "$MES" "$SEMANA"; do
    [[ "$campo" =~ ^[0-9*/,-]+$ ]] || ok=0
  done
  HORA_NUM=$(echo "$HORA" | grep -oE '^[0-9]+' || true)
  { [ -n "$HORA_NUM" ] && [ "$HORA_NUM" -le 5 ]; } || ok=0
  echo "$LINEA" | grep -q "respaldo" || ok=0

  grep -q '^\[Unit\]' "$SERVICE" || ok=0
  grep -q '^\[Service\]' "$SERVICE" || ok=0
  grep -qE '^ExecStart=.*respaldo.*\.sh' "$SERVICE" || ok=0

  grep -q '^\[Timer\]' "$TIMER" || ok=0
  grep -qE '^OnCalendar=' "$TIMER" || ok=0
  grep -q '^\[Install\]' "$TIMER" || ok=0
  grep -qE '^WantedBy=' "$TIMER" || ok=0

  # Deben referirse al sitio real (mismo dominio de entrega.env), no dejar
  # las rutas de ejemplo de la guia sin adaptar.
  grep -q "$DOMINIO" "$CRON" "$SERVICE" || ok=0
  grep -qE "/opt/proyecto|ruta_a_wordpress|ejemplo\.com" "$CRON" "$SERVICE" "$TIMER" && ok=0
fi

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
