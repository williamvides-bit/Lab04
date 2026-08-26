#!/usr/bin/env bash
# La evidencia v2 debe demostrar un cambio incremental real: se agrego un
# producto nuevo en la base de datos y se subio una imagen nueva al sitio,
# y la segunda entrega (v2) se subio a git DESPUES de la primera (v1), con
# una separacion minima de tiempo real entre ambas (no un solo lote).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

GAP_MINIMO_SEGUNDOS=300

ok=1

DB_V1="evidencia/v1/respaldo_db.sql.gz"
DB_V2="evidencia/v2/respaldo_db.sql.gz"
SITIO_V1="evidencia/v1/respaldo_sitio.tar.gz"
SITIO_V2="evidencia/v2/respaldo_sitio.tar.gz"

for f in "$DB_V1" "$DB_V2" "$SITIO_V1" "$SITIO_V2"; do
  [ -s "$f" ] || { echo "FAIL"; exit 0; }
done

# El respaldo debe haber cambiado de verdad (no es una copia del mismo archivo).
SHA_DB_V1=$(sha256sum "$DB_V1" | awk '{print $1}')
SHA_DB_V2=$(sha256sum "$DB_V2" | awk '{print $1}')
[ "$SHA_DB_V1" != "$SHA_DB_V2" ] || ok=0

SHA_SITIO_V1=$(sha256sum "$SITIO_V1" | awk '{print $1}')
SHA_SITIO_V2=$(sha256sum "$SITIO_V2" | awk '{print $1}')
[ "$SHA_SITIO_V1" != "$SHA_SITIO_V2" ] || ok=0

# La base de datos debe reflejar un producto nuevo: mas apariciones de
# 'product' en el dump v2 que en el v1 (heuristica: post_type='product').
if [ "$ok" -eq 1 ]; then
  CONTEO_V1=$(zcat "$DB_V1" 2>/dev/null | grep -o "'product'" | wc -l)
  CONTEO_V2=$(zcat "$DB_V2" 2>/dev/null | grep -o "'product'" | wc -l)
  [ "$CONTEO_V2" -gt "$CONTEO_V1" ] || ok=0
fi

# El sitio debe tener al menos un archivo nuevo bajo wp-content/uploads con
# pinta de imagen (la evidencia de que subieron una imagen nueva).
if [ "$ok" -eq 1 ]; then
  NUEVOS=$(comm -13 <(tar -tzf "$SITIO_V1" 2>/dev/null | sort) <(tar -tzf "$SITIO_V2" 2>/dev/null | sort))
  echo "$NUEVOS" | grep -iqE 'uploads.*\.(jpg|jpeg|png|gif|webp)$' || ok=0
fi

# Orden temporal: v2 se debe haber subido a git despues de v1, con una
# separacion minima real entre ambas entregas.
if [ "$ok" -eq 1 ]; then
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ok=0
  else
    T1=$(git log --diff-filter=A --follow --format=%at -- "$DB_V1" 2>/dev/null | tail -n1)
    T2=$(git log --diff-filter=A --follow --format=%at -- "$DB_V2" 2>/dev/null | tail -n1)
    if [ -z "$T1" ] || [ -z "$T2" ]; then
      ok=0
    else
      DIFF=$((T2 - T1))
      [ "$DIFF" -ge "$GAP_MINIMO_SEGUNDOS" ] || ok=0
    fi
  fi
fi

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
