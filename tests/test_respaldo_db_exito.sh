#!/usr/bin/env bash
# respaldo_db.sh debe generar un .sql.gz real con mysqldump, leyendo las
# credenciales de un wp-config.php, contra una base MariaDB de prueba con
# tablas al estilo WordPress (la levanta el workflow como "services:").
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/respaldo_db.sh"
[ -x "$SCRIPT" ] || { echo "FAIL"; exit 0; }

DB_HOST="${CET_DB_HOST:-127.0.0.1}"
DB_PORT="${CET_DB_PORT:-3306}"
ROOT_USER="${CET_DB_ROOT_USER:-root}"
ROOT_PASSWORD="${CET_DB_ROOT_PASSWORD:-root}"
MYSQL_SOCKET_ARGS=()
[ -n "${CET_DB_SOCKET:-}" ] && MYSQL_SOCKET_ARGS=(--socket="$CET_DB_SOCKET")

mysql_root() {
  mysql "${MYSQL_SOCKET_ARGS[@]}" --host="$DB_HOST" --port="$DB_PORT" \
    --user="$ROOT_USER" --password="$ROOT_PASSWORD" --protocol=TCP "$@"
}

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

DBNAME="cet_wp_test_$$"
DBUSER="cet_wp_user_$$"
DBPASS="clave_$$_segura"

mysql_root -e "CREATE DATABASE \`$DBNAME\`;" || { echo "FAIL"; exit 0; }
mysql_root -e "CREATE USER '$DBUSER'@'%' IDENTIFIED BY '$DBPASS'; GRANT ALL ON \`$DBNAME\`.* TO '$DBUSER'@'%'; FLUSH PRIVILEGES;"
mysql_root "$DBNAME" <<SQL
CREATE TABLE wp_options (option_id BIGINT PRIMARY KEY, option_name VARCHAR(191), option_value LONGTEXT);
INSERT INTO wp_options VALUES (1,'siteurl','https://tienda.demo.duckdns.org');
CREATE TABLE wp_posts (ID BIGINT PRIMARY KEY, post_title VARCHAR(255), post_type VARCHAR(20));
INSERT INTO wp_posts VALUES (1,'Producto demo','product');
CREATE TABLE wp_users (ID BIGINT PRIMARY KEY, user_login VARCHAR(60));
INSERT INTO wp_users VALUES (1,'admin');
SQL

mkdir -p "$WORKDIR/wp"
cat > "$WORKDIR/wp/wp-config.php" <<EOF
<?php
define('DB_NAME', '$DBNAME');
define('DB_USER', '$DBUSER');
define('DB_PASSWORD', '$DBPASS');
define('DB_HOST', '$DB_HOST:$DB_PORT');
EOF

mkdir -p "$WORKDIR/destino"
"$SCRIPT" -w "$WORKDIR/wp" -o "$WORKDIR/destino" >/dev/null 2>&1
CODE=$?

ok=1
[ "$CODE" -eq 0 ] || ok=0

DUMP=$(find "$WORKDIR/destino" -maxdepth 1 -name "*.sql.gz" | head -n1)
[ -n "$DUMP" ] || ok=0

if [ -n "$DUMP" ]; then
  gzip -t "$DUMP" 2>/dev/null || ok=0
  CONTENIDO=$(zcat "$DUMP" 2>/dev/null)
  echo "$CONTENIDO" | grep -q "wp_options" || ok=0
  echo "$CONTENIDO" | grep -q "wp_posts" || ok=0
  echo "$CONTENIDO" | grep -q "siteurl" || ok=0
fi

mysql_root -e "DROP DATABASE IF EXISTS \`$DBNAME\`; DROP USER IF EXISTS '$DBUSER'@'%';" 2>/dev/null || true

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
