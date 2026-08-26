#!/usr/bin/env bash
# respaldo_321.sh debe (a) fallar si la ruta de WordPress no existe, y
# (b) cuando existe, cumplir la regla 3-2-1 (2 copias reales e identicas en
# 2 medios) sin filtrar jamas wp-config.php dentro del respaldo.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/respaldo_321.sh"
source "$REPO_ROOT/tests/lib_fixture_wp.sh"
[ -x "$SCRIPT" ] || { echo "FAIL"; exit 0; }

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

ok=1

# Caso 1: la ruta de WordPress no existe -> exit != 0
"$SCRIPT" -s "$WORKDIR/wordpress_inexistente_$$" -o "$WORKDIR/respaldos_error" >/dev/null 2>&1
[ $? -ne 0 ] || ok=0

# Caso 2: regla 3-2-1 sobre una instalacion real
WP="$WORKDIR/wordpress"
crear_fixture_wp "$WP"
DESTINO="$WORKDIR/respaldos"

"$SCRIPT" -s "$WP" -o "$DESTINO" >/dev/null 2>&1
[ $? -eq 0 ] || ok=0

SUBDIRS=$(find "$DESTINO" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
[ "$SUBDIRS" -ge 2 ] || ok=0

FILES=$(find "$DESTINO" -mindepth 2 -type f ! -type l 2>/dev/null)
FILE_COUNT=0
[ -n "$FILES" ] && FILE_COUNT=$(echo "$FILES" | grep -c .)
[ "$FILE_COUNT" -ge 2 ] || ok=0

LINK_COUNT=$(find "$DESTINO" -mindepth 2 -type l 2>/dev/null | wc -l)
[ "$LINK_COUNT" -eq 0 ] || ok=0

if [ "$ok" -eq 1 ]; then
  SUMS=$(echo "$FILES" | xargs -I{} sha256sum {} | awk '{print $1}' | sort -u | wc -l)
  [ "$SUMS" -eq 1 ] || ok=0
fi

# Seguridad: wp-config.php NUNCA debe aparecer dentro del respaldo.
if [ "$ok" -eq 1 ]; then
  PRIMER_ARCHIVO=$(echo "$FILES" | head -n1)
  if tar -tzf "$PRIMER_ARCHIVO" 2>/dev/null | grep -q "wp-config.php"; then
    ok=0
  fi
fi

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
