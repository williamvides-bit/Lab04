# Laboratorio Semana 5 — Automatización de respaldo del sitio WordPress

CET 115 — Comercio Electrónico · Universidad de El Salvador

**No se respalda un proyecto de ejemplo: se respalda SU sitio WordPress + WooCommerce
real**, el mismo que desplegaron en el Laboratorio 1 (Nginx + Certbot, HTTPS) y
personalizaron en el Laboratorio 4 (WooCommerce, con al menos 2 categorías y 2
productos por categoría ya cargados, cada uno con nombre, descripciones,
inventario y galería de imágenes). Reutilizan el mismo `entrega.env` (carnet +
dominio) de esos laboratorios.

## Por qué esto importa?

Como se vio en clase: **un respaldo no probado no es un respaldo, es una
suposición.** Este laboratorio los obliga a demostrar dos cosas que un respaldo
de verdad debe cumplir:

1. Que el respaldo es de **su** sitio (no de un sitio de ejemplo ni el de un
   compañero): el autograder busca su propio dominio (`entrega.env`) dentro del
   dump de base de datos.
2. Que el respaldo **captura cambios reales con el tiempo** (no es una foto
   fija tomada una sola vez y subida dos veces): van a agregar un producto de
   verdad en WooCommerce, con imagen, y demostrar con un segundo respaldo que
   ese cambio quedó capturado.

## Estructura del repositorio

```
entrega.env               Mismo carnet y dominio del Laboratorio 1/4
data/                      Ejemplo de wp-config.php para probar en local (no modificar)
scripts/                   Aquí van los tres scripts pedidos
cron/                      Línea de crontab pedida (ejercicio 4)
systemd/                   Unidades systemd pedidas (ejercicio 4)
practica/                  Evidencia del trabajo en aula (ejercicio 0)
evidencia/v1/              Respaldo inicial de su sitio real (ejercicio 5)
evidencia/v2/              Respaldo tras agregar un producto + imagen (ejercicio 5)
tests/                     Pruebas del autograder (no modificar ni borrar)
.github/                   Configuración del autograder de GitHub Classroom
RUBRICA.md                 Cómo se reparten los 10 puntos de este laboratorio
```

## Ejercicio 0 — Trabajo en aula (diseño 3-2-1)

En parejas, diseñen en papel/pizarra el esquema de respaldo de su propio sitio y
suban la evidencia como `practica/diseno_321.md`, respondiendo:

1. ¿Qué se respalda? (base de datos de WordPress, `wp-content`, configuración)
2. ¿Con qué frecuencia y a qué hora (fuera de horario pico)?
3. ¿Dónde se guarda la copia fuera del sitio?

## Ejercicio 1 — `scripts/respaldo_db.sh`

Respalda la base de datos real de WordPress usando `mysqldump`, leyendo las
credenciales directamente del `wp-config.php` de su instalación:

```
scripts/respaldo_db.sh -w <ruta_instalacion_wordpress> -o <carpeta_destino>
```

- Debe leer `DB_NAME`, `DB_USER`, `DB_PASSWORD` y `DB_HOST` de `wp-config.php`
  (con `grep`/`sed`, no hace falta PHP).
- Si `wp-config.php` no existe o no tiene credenciales utilizables: código de
  salida distinto de 0.
- Si existe: ejecutar `mysqldump` con esas credenciales y comprimir con
  `gzip`, con nombre que incluya la fecha.
- **Nunca** pasen la contraseña como argumento de línea de comandos
  (`ps aux` la dejaría visible para cualquier otro usuario del servidor):
  usen un archivo de opciones temporal de MySQL (`--defaults-extra-file`,
  con `chmod 600`) como se explicó en clase para el manejo seguro de
  credenciales.

Pruébenlo en local contra su propio WordPress (o, si no tienen acceso directo,
monten una MariaDB de prueba: `docker run --rm -e MARIADB_ROOT_PASSWORD=root -p 3306:3306 mariadb:11`
y usen `data/wp-config.php.ejemplo` como referencia del formato esperado).

## Ejercicio 2 — `scripts/respaldo_321.sh`

Implementa la regla 3-2-1 sobre su instalación de WordPress completa:

```
scripts/respaldo_321.sh -s <ruta_instalacion_wordpress> -o <carpeta_base_respaldos> [-f <dump.sql.gz>]
```

- Si `-s` no existe: código de salida distinto de 0.
- Si existe: generar un `.tar.gz` del sitio (incluyendo el dump de `-f` si se
  indicó) y guardar **una copia real e idéntica** en **dos subcarpetas
  distintas** (dos "medios" — por ejemplo `disco_local/` y `nube_simulada/`).
  No se aceptan enlaces simbólicos.
- **Debe excluir `wp-config.php` del respaldo.** Ese archivo tiene las
  credenciales de la base de datos en texto plano: si termina dentro de un
  `.tar.gz` que luego suben a git, están filtrando su propia base de datos.
  Esto lo verifica el autograder explícitamente.

## Ejercicio 3 — `scripts/restaurar.sh`

La prueba de que el respaldo sirve, en dos modos:

```
scripts/restaurar.sh -t sitio -b <respaldo.tar.gz> -d <carpeta_destino>
scripts/restaurar.sh -t bd -b <dump.sql.gz> -h <host> -P <puerto> -u <usuario> -p <clave> -n <basededatos>
```

- Modo `sitio`: extrae el `.tar.gz` en `-d`.
- Modo `bd`: importa el dump (`zcat ... | mysql ...`) en la base indicada.
- En cualquier caso, si el respaldo no existe o no es válido: código de salida
  distinto de 0.

El autograder genera un respaldo, "pierde" el original y verifica que
`restaurar.sh` recupera tanto los archivos como la base de datos.

## Ejercicio 4 — Programación automática (`cron/` y `systemd/`)

Entreguen la configuración real que usan en su servidor (no un ejemplo
genérico: el autograder rechaza rutas de plantilla como `/opt/proyecto` y
exige que aparezca su propio dominio de `entrega.env`):

- `cron/respaldo.cron`: una línea que ejecute `respaldo_321.sh` todos los
  días, en horario fuera de pico (madrugada, 00:00–05:59).
- `systemd/respaldo.service`: unidad `oneshot` con `ExecStart` apuntando a
  su script real.
- `systemd/respaldo.timer`: `OnCalendar` diario, vinculada a `timers.target`.

## Ejercicio 5 — Evidencia real, en dos entregas

Esta es la parte que conecta todo con su sitio en producción:

**Entrega v1 (respaldo inicial).** En su servidor, con `cron`/`systemd` ya
configurados, ejecuten sus scripts contra su WordPress real — el que ya
tiene las categorías y productos del Laboratorio 4 cargados — y copien el
resultado a este repositorio:

```
evidencia/v1/respaldo_db.sql.gz
evidencia/v1/respaldo_sitio.tar.gz
```

Hagan commit y push de la entrega inicial completa (ejercicios 0-4 + v1).

**Cambien algo real en su tienda.** En el panel de WooCommerce, agreguen **un
producto nuevo** (uno más, además de los que ya tenían de la Semana 4) **con
al menos una imagen de galería**, con su nombre, descripción e inventario
como en cualquier producto del catálogo. Esto es lo que el autograder busca
en la segunda entrega: un producto nuevo en la base de datos y una imagen
nueva bajo `wp-content/uploads`.

**Entrega v2 (respaldo tras el cambio).** Corran de nuevo sus scripts y suban:

```
evidencia/v2/respaldo_db.sql.gz
evidencia/v2/respaldo_sitio.tar.gz
```

con su propio commit y push, **al menos 5 minutos después** del commit de v1
(el autograder compara las fechas de los commits, no solo el contenido — un
respaldo que en verdad automatizaron toma su tiempo real, no se genera dos
veces en el mismo instante).

El autograder verifica que v2 realmente cambió respecto a v1 (más un
producto, un archivo de imagen nuevo) y que las dos entregas llegaron en
commits distintos y en orden.

## La conexión con CI/CD

Cada `git push` a este repositorio dispara `.github/workflows/classroom.yml`,
que corre pruebas automáticas — exactamente el diagrama de la clase
(`git push → pruebas → construcción → respaldo automático → despliegue`). El
autograder de este laboratorio **es** una canalización de CI/CD real,
aplicada a la evidencia de que ustedes automatizaron el respaldo de su propio
sitio.

## Cómo se califica

Ver `RUBRICA.md`. En resumen: 9 de 10 puntos los pone el autograder
automáticamente en cada `push` (pestaña **Actions** de este repositorio), y 1
punto lo revisa el docente manualmente (historial de commits y legibilidad
del código).

## Flujo de trabajo recomendado

```bash
git clone <url-de-su-repositorio>
cd <su-repositorio>

# completar entrega.env con su carnet y dominio (los mismos del Laboratorio 1/4)

# ejercicios 0-4, luego el primer respaldo real en su servidor:
mkdir -p evidencia/v1
scp servidor:/ruta/al/respaldo_db.sql.gz evidencia/v1/
scp servidor:/ruta/al/respaldo_sitio.tar.gz evidencia/v1/
git add entrega.env practica scripts cron systemd evidencia/v1
git commit -m "Entrega inicial: scripts, cron/systemd y evidencia v1"
git push

# ... agregar un producto con imagen en WooCommerce, esperar unos minutos,
# correr de nuevo el respaldo en el servidor ...

mkdir -p evidencia/v2
scp servidor:/ruta/al/respaldo_db.sql.gz evidencia/v2/
scp servidor:/ruta/al/respaldo_sitio.tar.gz evidencia/v2/
git add evidencia/v2
git commit -m "Entrega final: producto nuevo + imagen, evidencia v2"
git push
```

Cada `push` dispara el autograder automáticamente. Recuerden dar permiso de
ejecución a sus scripts antes de subirlos: `chmod +x scripts/*.sh`.
