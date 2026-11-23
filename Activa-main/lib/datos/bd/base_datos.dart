// ===================================================================
// base_datos.dart
// Abre (o crea) la base de datos SQLite de ACTIVA y define el esquema.
//
//  - Android / iOS: plugin sqflite
//  - Linux / Windows / macOS: sqflite_common_ffi
//  - Web: sqflite_common_ffi_web (SQLite en WebAssembly + IndexedDB)
//
// La base arranca limpia: solo se crean las categorías del catálogo y una
// cuenta de administrador inicial. Los talleres, alumnos, avisos, chats,
// etc. los captura el usuario desde la app.
// ===================================================================

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../catalogo.dart';
import '../constantes_app.dart';
import 'seguridad.dart';
import 'plataforma_stub.dart'
    if (dart.library.io) 'plataforma_io.dart'
    if (dart.library.js_interop) 'plataforma_web.dart';

class BaseDatos {
  BaseDatos._({this._fabrica, this._ruta});

  /// Instancia normal de la app (elige la fábrica y ruta según la plataforma).
  static final BaseDatos instancia = BaseDatos._();

  /// Instancia para pruebas: permite usar una fábrica y ruta propias
  /// (por ejemplo, sqflite_common_ffi con una base en memoria).
  factory BaseDatos.pruebas(DatabaseFactory fabrica, String ruta) =>
      BaseDatos._(fabrica: fabrica, ruta: ruta);

  static const _version = 4;
  final DatabaseFactory? _fabrica;
  final String? _ruta;
  Database? _db;

  /// Abre la base de datos una sola vez y la deja lista para usarse.
  Future<Database> abrir() async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final fabrica = _fabrica ?? fabricaSqlite();
    final ruta = _ruta ?? await rutaBaseDatos();
    return fabrica.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await _crearEsquema(db);
          await _sembrar(db);
        },
        onUpgrade: (db, versionAnterior, versionNueva) async {
          // La versión 2 arranca sin datos de ejemplo: se descarta la base
          // anterior (que traía datos simulados) y se crea limpia.
          await _borrarEsquema(db);
          await _crearEsquema(db);
          await _sembrar(db);
        },
      ),
    );
  }

  /// Cierra la conexión sin borrar el archivo.
  Future<void> cerrar() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }

  /// Borra la base de datos (útil para pruebas). La siguiente apertura
  /// vuelve a crear el esquema y los datos iniciales.
  Future<void> reiniciar() async {
    await cerrar();
    final fabrica = _fabrica ?? fabricaSqlite();
    await fabrica.deleteDatabase(_ruta ?? await rutaBaseDatos());
  }

  /// Elimina todas las tablas (para migrar de una versión anterior).
  Future<void> _borrarEsquema(Database db) async {
    const tablas = <String>[
      'contadores',
      'usuarios',
      'reportes',
      'horas_validadas',
      'bajas',
      'favoritos',
      'solicitudes',
      'encuestas',
      'chats_estado',
      'mensajes',
      'avisos',
      'roster',
      'asistencias',
      'inscripciones',
      'aprendizajes',
      'horarios',
      'talleres',
      'instructores',
      'alumnos',
      'categorias',
    ];
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      for (final tabla in tablas) {
        await txn.execute('DROP TABLE IF EXISTS $tabla');
      }
      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }

  // ------------------------------------------------------------ esquema
  Future<void> _crearEsquema(Database db) async {
    final lote = <String>[
      // ---------- catálogo ----------
      '''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY,
        clave TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        etiqueta TEXT NOT NULL,
        color INTEGER NOT NULL,
        icono TEXT NOT NULL,
        activa INTEGER NOT NULL DEFAULT 1
      )
      ''',
      // catálogo de especialidades que se piden al registrarse (lo
      // administra el admin: agregar/eliminar desde la app)
      '''
      CREATE TABLE especialidades_alumno (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL UNIQUE
      )
      ''',
      // ---------- personas ----------
      '''
      CREATE TABLE alumnos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        apellido_paterno TEXT NOT NULL DEFAULT '',
        apellido_materno TEXT NOT NULL DEFAULT '',
        correo TEXT NOT NULL DEFAULT '',
        telefono TEXT NOT NULL DEFAULT '',
        numero_control TEXT NOT NULL UNIQUE,
        grupo TEXT NOT NULL DEFAULT '',
        carrera TEXT NOT NULL DEFAULT '',
        horas INTEGER NOT NULL DEFAULT 0
      )
      ''',
      '''
      CREATE TABLE instructores (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        apellido_paterno TEXT NOT NULL DEFAULT '',
        apellido_materno TEXT NOT NULL DEFAULT '',
        correo TEXT NOT NULL DEFAULT '',
        telefono TEXT NOT NULL DEFAULT '',
        especialidad TEXT NOT NULL DEFAULT '',
        activo INTEGER NOT NULL DEFAULT 1
      )
      ''',
      // ---------- talleres ----------
      '''
      CREATE TABLE talleres (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL DEFAULT '',
        categoria_id INTEGER NOT NULL,
        lugar TEXT NOT NULL DEFAULT '',
        cupo_maximo INTEGER NOT NULL,
        horas_otorga INTEGER NOT NULL DEFAULT 60,
        activo INTEGER NOT NULL DEFAULT 1,
        instructor_id INTEGER NOT NULL,
        inscritos INTEGER NOT NULL DEFAULT 0,
        foto BLOB,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id),
        FOREIGN KEY (instructor_id) REFERENCES instructores(id)
      )
      ''',
      '''
      CREATE TABLE horarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taller_id INTEGER NOT NULL,
        dia INTEGER NOT NULL,
        hora_inicio TEXT NOT NULL,
        hora_fin TEXT NOT NULL,
        orden INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (taller_id) REFERENCES talleres(id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE aprendizajes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taller_id INTEGER NOT NULL,
        texto TEXT NOT NULL,
        orden INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (taller_id) REFERENCES talleres(id) ON DELETE CASCADE
      )
      ''',
      // ---------- inscripciones / asistencia ----------
      '''
      CREATE TABLE inscripciones (
        folio TEXT PRIMARY KEY,
        alumno_id INTEGER NOT NULL,
        taller_id INTEGER NOT NULL,
        estado TEXT NOT NULL DEFAULT 'activa',
        fecha TEXT NOT NULL,
        horas INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (alumno_id) REFERENCES alumnos(id),
        FOREIGN KEY (taller_id) REFERENCES talleres(id)
      )
      ''',
      '''
      CREATE TABLE asistencias (
        taller_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        numero_control TEXT NOT NULL,
        presente INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (taller_id, fecha, numero_control),
        FOREIGN KEY (taller_id) REFERENCES talleres(id) ON DELETE CASCADE
      )
      ''',
      // lista de alumnos que el instructor ve al pasar lista
      '''
      CREATE TABLE roster (
        taller_id INTEGER NOT NULL,
        alumno_id INTEGER NOT NULL,
        PRIMARY KEY (taller_id, alumno_id),
        FOREIGN KEY (taller_id) REFERENCES talleres(id) ON DELETE CASCADE,
        FOREIGN KEY (alumno_id) REFERENCES alumnos(id)
      )
      ''',
      // ---------- avisos ----------
      '''
      CREATE TABLE avisos (
        id INTEGER PRIMARY KEY,
        taller_id INTEGER,
        tipo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        mensaje TEXT NOT NULL DEFAULT '',
        fecha TEXT NOT NULL,
        leido INTEGER NOT NULL DEFAULT 0,
        archivado INTEGER NOT NULL DEFAULT 0
      )
      ''',
      // ---------- chats ----------
      '''
      CREATE TABLE mensajes (
        id INTEGER PRIMARY KEY,
        taller_id INTEGER NOT NULL,
        rol TEXT NOT NULL,
        autor TEXT NOT NULL,
        texto TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE chats_estado (
        taller_id INTEGER PRIMARY KEY,
        anclado INTEGER NOT NULL DEFAULT 0,
        fondo INTEGER NOT NULL DEFAULT 0
      )
      ''',
      // ---------- encuestas / solicitudes ----------
      '''
      CREATE TABLE encuestas (
        id INTEGER PRIMARY KEY,
        taller_id INTEGER NOT NULL,
        numero_control TEXT NOT NULL,
        calif_club INTEGER NOT NULL,
        calif_instructor INTEGER NOT NULL,
        comentario TEXT NOT NULL DEFAULT '',
        fecha TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE solicitudes (
        id INTEGER PRIMARY KEY,
        taller_id INTEGER NOT NULL,
        instructor_id INTEGER NOT NULL,
        instructor_nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        mensaje TEXT NOT NULL DEFAULT '',
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'pendiente',
        respuesta TEXT NOT NULL DEFAULT '',
        cupo_extra INTEGER NOT NULL DEFAULT 0
      )
      ''',
      // ---------- preferencias / reportes ----------
      '''
      CREATE TABLE favoritos (
        taller_id INTEGER PRIMARY KEY
      )
      ''',
      '''
      CREATE TABLE bajas (
        taller_id INTEGER PRIMARY KEY,
        total INTEGER NOT NULL DEFAULT 0
      )
      ''',
      // alumnos cuya constancia final ya revisó y confirmó la coordinación
      '''
      CREATE TABLE horas_validadas (
        numero_control TEXT PRIMARY KEY,
        fecha TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE reportes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        formato TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
      ''',
      // ---------- cuentas de acceso ----------
      '''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        rol TEXT NOT NULL,
        usuario TEXT NOT NULL UNIQUE,
        correo TEXT NOT NULL DEFAULT '',
        nombre TEXT NOT NULL DEFAULT '',
        apellido_paterno TEXT NOT NULL DEFAULT '',
        apellido_materno TEXT NOT NULL DEFAULT '',
        telefono TEXT NOT NULL DEFAULT '',
        especialidad TEXT NOT NULL DEFAULT '',
        numero_control TEXT NOT NULL DEFAULT '',
        grupo TEXT NOT NULL DEFAULT '',
        carrera TEXT NOT NULL DEFAULT '',
        activo INTEGER NOT NULL DEFAULT 1,
        debe_cambiar_contrasena INTEGER NOT NULL DEFAULT 0,
        sal TEXT NOT NULL DEFAULT '',
        hash TEXT NOT NULL DEFAULT ''
      )
      ''',
      // ---------- consecutivos ----------
      '''
      CREATE TABLE contadores (
        clave TEXT PRIMARY KEY,
        valor INTEGER NOT NULL
      )
      ''',
    ];

    await db.transaction((txn) async {
      for (final sql in lote) {
        await txn.execute(sql);
      }
    });
  }

  // ------------------------------------------------------------ semilla
  Future<void> _sembrar(Database db) async {
    await db.transaction((txn) async {
      // catálogo real de categorías
      for (final c in categoriasIniciales) {
        await txn.insert('categorias', {
          'id': c.id,
          'clave': c.clave,
          'nombre': c.nombre,
          'etiqueta': c.etiqueta,
          'color': c.colorValue,
          'icono': c.icono,
          'activa': c.activa ? 1 : 0,
        });
      }

      // especialidades con las que arranca el registro de alumno
      for (var i = 0; i < especialidadesIniciales.length; i++) {
        await txn.insert('especialidades_alumno', {
          'id': i + 1,
          'nombre': especialidadesIniciales[i],
        });
      }

      // cuenta de administrador inicial (contraseña con hash)
      final sal = generarSal();
      await txn.insert('usuarios', {
        'id': 1,
        'rol': 'admin',
        'usuario': usuarioAdminInicial,
        'correo': correoAdminInicial,
        'nombre': nombreAdminInicial,
        'apellido_paterno': apellidoAdminInicial,
        'apellido_materno': '',
        'telefono': '',
        'especialidad': '',
        'numero_control': '',
        'grupo': '',
        'carrera': '',
        'activo': 1,
        'debe_cambiar_contrasena': 0,
        'sal': sal,
        'hash': hashContrasena(sal, contrasenaAdminInicial),
      });

      // consecutivos iniciales
      const iniciales = <String, int>{
        'folio': 1,
        'taller': 1,
        'instructor': 1,
        'aviso': 1,
        'mensaje': 1,
        'encuesta': 1,
        'solicitud': 1,
        'usuario': 2,
      };
      for (final e in iniciales.entries) {
        await txn.insert('contadores', {'clave': e.key, 'valor': e.value});
      }
    });
    debugPrint(
      'ACTIVA: base de datos creada (catálogo y administrador inicial)',
    );
  }
}

/// Convierte un enum guardado como texto en su valor, con respaldo.
T enumDe<T extends Enum>(List<T> valores, Object? texto, T porDefecto) {
  if (texto is! String) return porDefecto;
  for (final v in valores) {
    if (v.name == texto) return v;
  }
  return porDefecto;
}