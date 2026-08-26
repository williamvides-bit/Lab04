#!/usr/bin/env bash
# Crea una instalacion de WordPress de juguete en $1, con wp-config.php
# (credenciales de prueba) y la estructura minima que deben respetar los
# scripts del laboratorio. Usada por varias pruebas del autograder.
crear_fixture_wp() {
  local wp="$1"
  mkdir -p "$wp/wp-content/themes/mitienda" \
           "$wp/wp-content/plugins/woocommerce" \
           "$wp/wp-content/uploads/2026/08" \
           "$wp/wp-includes"
  echo "<?php // version" > "$wp/wp-includes/version.php"
  echo "/* tema mitienda */" > "$wp/wp-content/themes/mitienda/style.css"
  echo "<?php // plugin woocommerce" > "$wp/wp-content/plugins/woocommerce/woocommerce.php"
  echo "<?php // index" > "$wp/index.php"
  echo "fake-jpg-bytes" > "$wp/wp-content/uploads/2026/08/producto-demo.jpg"
  cat > "$wp/wp-config.php" <<'EOF'
<?php
define('DB_NAME', 'no_usar_en_pruebas');
define('DB_USER', 'no_usar_en_pruebas');
define('DB_PASSWORD', 'secreto-de-mentira-no-debe-filtrarse');
define('DB_HOST', 'localhost');
EOF
}
