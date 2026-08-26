#!/usr/bin/env bash
# respaldo_db.sh debe fallar (exit != 0) si la ruta de WordPress no tiene
# wp-config.php, o si wp-config.php no tiene credenciales validas.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

SCRIPT="scripts/respaldo_db.sh"
[ -x "$SCRIPT" ] || { echo "FAIL"; exit 0; }

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

ok=1

# Caso 1: no existe wp-config.php
./"$SCRIPT" -w "$WORKDIR/no_es_wordpress_$$" -o "$WORKDIR/destino1" >/dev/null 2>&1
[ $? -ne 0 ] || ok=0

# Caso 2: wp-config.php sin credenciales utilizables
mkdir -p "$WORKDIR/wp_invalido"
cat > "$WORKDIR/wp_invalido/wp-config.php" <<'EOF'
<?php
// wp-config.php incompleto, sin define() de base de datos
EOF
./"$SCRIPT" -w "$WORKDIR/wp_invalido" -o "$WORKDIR/destino2" >/dev/null 2>&1
[ $? -ne 0 ] || ok=0

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
