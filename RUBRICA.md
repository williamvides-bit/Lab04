# Rúbrica de evaluación — Laboratorio Semana 5: Automatización de respaldo

**Puntaje total: 10 puntos**, dentro del promedio de laboratorios de CET 115.

## 1. Autograder (9 puntos, automático)

Cada `push` al repositorio dispara el workflow `.github/workflows/classroom.yml`,
que ejecuta las pruebas de `.github/classroom/autograding.json` (incluyendo un
contenedor MariaDB de prueba como `services:` del propio workflow, para poder
correr `mysqldump`/`mysql` de verdad). El resultado se ve en la pestaña
**Actions** del repositorio y, si el docente configuró la asignación en GitHub
Classroom, también en el panel de calificaciones de la organización.

| # | Prueba | Ejercicio que verifica | Puntos |
|---|---|---|---|
| 1 | Estructura, `entrega.env` completo y evidencia entregada | Estructura general | 1 |
| 2 | `respaldo_db.sh` maneja errores (wp-config.php ausente o sin credenciales) | Ejercicio 1 (validación) | 1 |
| 3 | `respaldo_db.sh` genera un dump real con `mysqldump` (contra MariaDB de prueba) | Ejercicio 1 (caso de éxito) | 1 |
| 4 | `respaldo_321.sh` cumple la regla 3-2-1 y **no filtra `wp-config.php`** | Ejercicio 2 | 1 |
| 5 | `restaurar.sh -t sitio` recupera los archivos correctamente | Ejercicio 3 (archivos) | 1 |
| 6 | `restaurar.sh -t bd` recupera la base de datos en una instancia limpia | Ejercicio 3 (base de datos) | 1 |
| 7 | `cron/respaldo.cron` y `systemd/*` apuntan al sitio real de `entrega.env` (no una plantilla genérica) | Ejercicio 4 | 1 |
| 8 | `evidencia/v1/` es un respaldo real de su propio sitio (tablas de WordPress + su dominio) | Ejercicio 5 (v1) | 1 |
| 9 | `evidencia/v2/` demuestra un cambio incremental real: producto nuevo en la base de datos, imagen nueva en el sitio, y commits en orden con al menos 5 minutos de separación | Ejercicio 5 (v2) | 1 |

## 2. Política de entrega tardía

Sin extensión salvo justificación previa. El autograder no queda disponible
después de la fecha límite solo para que el estudiante vea qué falló — el
`push` posterior a la fecha límite no se recalifica automáticamente; el
docente aplica el descuento que corresponda según la política general del
curso.
