# Base de datos de ACTIVA

ACTIVA guarda toda su información en **SQLite** (base de datos local).
La app funciona sin internet y los datos siguen ahí después de cerrarla.

## Arranque limpio

La base se crea **sin datos de ejemplo**. Solo incluye:

- El catálogo de categorías: Deportes, Cultura, Recreativa y Otros.
- Una cuenta de administrador inicial.

| Usuario | Contraseña | Rol |
|---|---|---|
| `admin` | `Activa2026!` | Administrador |

Con esa cuenta se crean instructores, talleres, horarios y avisos.
Los alumnos se registran desde **Crear cuenta** en la pantalla de inicio
de sesión. Los datos simulados (`mar_alumna`, `mar_instructor`,
`mar_admin`, talleres de prueba, avisos, chats y encuestas) ya no existen
en la base limpia. Si necesitas una demo, usa el script de datos de prueba
que se explica más abajo; genera un archivo aparte.

## Archivo `.sqlite`

El archivo listo para abrir con cualquier visor de SQLite está en:

```
Activa-main/activa.sqlite
```

Está al mismo nivel que la carpeta `lib/`. Para regenerarlo:

```bash
cd Activa-main
flutter test tool/generar_base.dart
```

## Datos de prueba (opcional)

La base limpia no trae datos de ejemplo. Si necesitas una base para
demostrar la app, genera una copia con datos de prueba:

```bash
cd Activa-main
flutter test tool/datos_prueba.dart
```

Esto crea `Activa-main/activa_datos_prueba.sqlite` **sin tocar**
`activa.sqlite`. Incluye:

- 6 instructores y 12 alumnos con cuenta de acceso.
- 6 talleres (Voleibol, Básquetbol, Danza folclórica, Guitarra, Ajedrez
  y Robótica), uno de ellos con cupo lleno.
- 28 inscripciones, 8 sesiones de asistencia por taller y horas
  acumuladas por alumno.
- Avisos, chats grupales, encuestas, solicitudes al administrador,
  favoritos, una baja y reportes.

Todas las cuentas usan la contraseña `Activa2026!`:

| Rol | Usuarios |
|---|---|
| Administrador | `admin` |
| Instructores | `ana_lopez`, `carlos_ruiz`, `lucia_mendez`, `jorge_salas`, `paola_ortiz`, `hector_navarro` |
| Alumnos | `mariana_torres`, `diego_ramirez`, `sofia_hernandez`, `luis_garcia`, `valeria_martinez`, `emilio_lopez`, `fernanda_diaz`, `santiago_morales`, `camila_jimenez`, `andres_castillo`, `renata_vargas`, `ivan_romero` |

Para usarla en la app de escritorio (Linux), cierra la app y copia:

```bash
cp activa_datos_prueba.sqlite ~/Documentos/activa.db
```

También puedes generar los datos directamente en la ruta de ejecución:

```bash
ACTIVA_DB="$HOME/Documentos/activa.db" flutter test tool/datos_prueba.dart
```

En Android/iOS copia el archivo a la carpeta de documentos de la app con
el nombre `activa.db`. En web no se puede importar el archivo: los datos
se capturan desde la app.

Para volver a la base limpia, borra `activa.db` y abre la app de nuevo.

## Plataformas

| Plataforma | Motor de SQLite | Dónde se guarda en ejecución |
|---|---|---|
| Android / iOS | `sqflite` | Documentos privados de la app (`activa.db`) |
| Linux / Windows / macOS | `sqflite_common_ffi` | Documentos del usuario (`activa.db`) |
| Web (Chrome/Edge) | `sqflite_common_ffi_web` | IndexedDB del navegador |

En Linux el archivo de ejecución queda en `~/Documentos/activa.db`.
En Android/iOS se puede ver con el explorador de archivos del dispositivo
(carpeta de documentos de la app).

> El archivo `activa.sqlite` de la raíz es una copia limpia de referencia.
> La app crea y usa su propio `activa.db` en la ubicación de cada plataforma.

## Tablas

| Tabla | Contenido |
|---|---|
| `categorias` | Deportes, Cultura, Recreativa, Otros |
| `alumnos` | Alumnos y sus horas acumuladas |
| `instructores` | Instructores (con o sin cuenta de acceso) |
| `talleres` | Clubes/talleres, cupo, instructor y foto |
| `horarios` | Días y horas de cada taller |
| `aprendizajes` | Lista de aprendizajes de cada taller |
| `inscripciones` | Folio, alumno, taller, estado y horas |
| `asistencias` | Lista de asistencia por taller y fecha |
| `roster` | Alumnos que aparecen al pasar lista |
| `avisos` | Avisos y si están leídos/archivados |
| `mensajes` | Mensajes de los chats grupales |
| `chats_estado` | Chats anclados y fondo elegido |
| `encuestas` | Respuestas de encuestas |
| `solicitudes` | Solicitudes de instructores al admin |
| `favoritos` | Talleres favoritos |
| `bajas` | Bajas por taller |
| `reportes` | Historial de reportes generados |
| `usuarios` | Cuentas de acceso (sal + hash SHA-256) |
| `contadores` | Consecutivos de folios, ids, etc. |

## Cómo está conectada

- `lib/datos/bd/base_datos.dart`: abre/crea la base, define el esquema y
  crea el catálogo y el administrador inicial.
- `lib/datos/bd/repositorio_activa.dart`: convierte entre los modelos de la
  app y las tablas (leer y guardar).
- `lib/datos/bd/seguridad.dart`: sal aleatoria y hash SHA-256 de contraseñas.
- `lib/datos/estado_app.dart`: al arrancar carga todo desde SQLite y cada
  cambio (inscripción, asistencia, aviso, mensaje, etc.) se guarda solo.
- `lib/datos/almacen_cuentas.dart`: registro/login usa la tabla `usuarios`.
- `lib/datos/constantes_app.dart`: meta de horas, periodo y administrador
  inicial.
- `lib/datos/catalogo.dart`: categorías iniciales.
- `lib/main.dart`: abre la base y carga los datos antes de mostrar la app.

Las pantallas no cambiaron: siguen usando `EstadoApp` y `EstadoSesion`.

## Reiniciar la base

Borra el archivo `activa.db` y vuelve a abrir la app. En web, borra los
datos del sitio desde el navegador. La siguiente apertura vuelve a crear
la base limpia.

También se puede llamar a `BaseDatos.instancia.reiniciar()` desde código.

Si una instalación anterior tenía la versión 1 (con datos simulados), la
app la detecta y la reemplaza por la base limpia automáticamente.

## Prueba automática

```bash
flutter test test/base_datos_test.dart
```

Comprueba que la base arranca limpia, que existe el administrador, y que
se guardan y releen instructores, talleres, alumnos, inscripciones y horas.

## Web

Los archivos `web/sqflite_sw.js` y `web/sqlite3.wasm` son necesarios para
que SQLite funcione en el navegador. Ya están incluidos en el proyecto.
