#!/usr/bin/env bash
# restaurar.sh -t sitio debe recuperar los archivos del sitio, incluida una
# imagen subida a wp-content/uploads, tal como quedaron en el respaldo.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESPALDO="$REPO_ROOT/scripts/respaldo_321.sh"
RESTAURAR="$REPO_ROOT/scripts/restaurar.sh"
source "$REPO_ROOT/tests/lib_fixture_wp.sh"
[ -x "$RESPALDO" ] || { echo "FAIL"; exit 0; }
[ -x "$RESTAURAR" ] || { echo "FAIL"; exit 0; }

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

WP="$WORKDIR/wordpress"
crear_fixture_wp "$WP"
MARCA="imagen_marca_$$.jpg"
echo "contenido-imagen-$$" > "$WP/wp-content/uploads/2026/08/$MARCA"

DESTINO="$WORKDIR/respaldos"
"$RESPALDO" -s "$WP" -o "$DESTINO" >/dev/null 2>&1 || { echo "FAIL"; exit 0; }

BACKUP=$(find "$DESTINO" -type f ! -type l | head -n1)
[ -n "$BACKUP" ] || { echo "FAIL"; exit 0; }

RESTAURADO="$WORKDIR/restaurado"
mkdir -p "$RESTAURADO"
"$RESTAURAR" -t sitio -b "$BACKUP" -d "$RESTAURADO" >/dev/null 2>&1
CODE=$?

ARCHIVO_RECUPERADO=$(find "$RESTAURADO" -type f -name "$MARCA" | head -n1)

if [ "$CODE" -eq 0 ] && [ -n "$ARCHIVO_RECUPERADO" ] && grep -q "contenido-imagen-$$" "$ARCHIVO_RECUPERADO"; then
  echo "PASS"
else
  echo "FAIL"
fi
