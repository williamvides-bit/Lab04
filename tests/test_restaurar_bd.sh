#!/usr/bin/env bash
# restaurar.sh -t bd debe importar un dump real en una base de datos vacia
# (contra la MariaDB de prueba que levanta el workflow como "services:").
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/restaurar.sh"
[ -x "$SCRIPT" ] || { echo "FAIL"; exit 0; }

DB_HOST="${CET_DB_HOST:-127.0.0.1}"
DB_PORT="${CET_DB_PORT:-3306}"
ROOT_USER="${CET_DB_ROOT_USER:-root}"
ROOT_PASSWORD="${CET_DB_ROOT_PASSWORD:-root}"

mysql_root() {
  mysql --host="$DB_HOST" --port="$DB_PORT" --user="$ROOT_USER" --password="$ROOT_PASSWORD" --protocol=TCP "$@"
}

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

DBNAME="cet_wp_restore_$$"
DBUSER="cet_wp_restore_user_$$"
DBPASS="clave_restore_$$_segura"

mysql_root -e "CREATE DATABASE \`$DBNAME\`;" || { echo "FAIL"; exit 0; }
mysql_root -e "CREATE USER '$DBUSER'@'%' IDENTIFIED BY '$DBPASS'; GRANT ALL ON \`$DBNAME\`.* TO '$DBUSER'@'%'; FLUSH PRIVILEGES;"

DUMP="$WORKDIR/dump.sql.gz"
{
  echo "CREATE TABLE wp_options (option_id BIGINT PRIMARY KEY, option_name VARCHAR(191), option_value LONGTEXT);"
  echo "INSERT INTO wp_options VALUES (1,'siteurl','https://tienda.demo.duckdns.org');"
  echo "CREATE TABLE wp_posts (ID BIGINT PRIMARY KEY, post_title VARCHAR(255), post_type VARCHAR(20));"
  echo "INSERT INTO wp_posts VALUES (1,'Producto demo','product');"
} | gzip -c > "$DUMP"

"$SCRIPT" -t bd -b "$DUMP" -h "$DB_HOST" -P "$DB_PORT" -u "$DBUSER" -p "$DBPASS" -n "$DBNAME" >/dev/null 2>&1
CODE=$?

ok=1
[ "$CODE" -eq 0 ] || ok=0

if [ "$ok" -eq 1 ]; then
  CONTEO=$(mysql_root -N -B -e "SELECT COUNT(*) FROM \`$DBNAME\`.wp_posts WHERE post_type='product';" 2>/dev/null)
  [ "${CONTEO:-0}" -ge 1 ] || ok=0
fi

mysql_root -e "DROP DATABASE IF EXISTS \`$DBNAME\`; DROP USER IF EXISTS '$DBUSER'@'%';" 2>/dev/null || true

if [ "$ok" -eq 1 ]; then
  echo "PASS"
else
  echo "FAIL"
fi
