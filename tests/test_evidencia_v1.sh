#!/usr/bin/env bash
# La evidencia v1 (respaldo inicial subido a git) debe ser un respaldo real
# de SU sitio: el dump debe traer tablas de WordPress y mencionar su propio
# dominio (entrega.env), y el tar del sitio debe tener estructura de
# WordPress sin incluir wp-config.php (no se filtran credenciales a git).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

ok=1

[ -s "entrega.env" ] || { echo "FAIL"; exit 0; }
set -a
# shellcheck disable=SC1091
source entrega.env 2>/dev/null || ok=0
set +a
[ -n "${DOMINIO:-}" ] || ok=0

DB="evidencia/v1/respaldo_db.sql.gz"
SITIO="evidencia/v1/respaldo_sitio.tar.gz"
[ -s "$DB" ] || ok=0
[ -s "$SITIO" ] || ok=0

if [ "$ok" -eq 1 ]; then
  gzip -t "$DB" 2>/dev/null || ok=0
  CONTENIDO=$(zcat "$DB" 2>/dev/null)
  echo "$CONTENIDO" | grep -qi "wp_options\|wp_posts\|wp_users" || ok=0
  echo "$CONTENIDO" | grep -q "$DOMINIO" || ok=0

  tar -tzf "$SITIO" >/dev/null 2>&1 || ok=0
  LISTADO=$(tar -tzf "$SITIO" 2>/dev/null)
  echo "$LISTADO" | grep -qi "wp-content" || ok=0
  echo "$LISTADO" | grep -q "wp-config.php" && ok=0
fi

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
