// ===================================================================
// repositorio_activa.dart
// Traduce entre los modelos de la app y las tablas de SQLite.
// EstadoApp y AlmacenCuentas lo usan para leer al arrancar y para
// escribir cada cambio (inscripciones, asistencia, avisos, chats...).
// ===================================================================

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../modelos/categoria.dart';
import '../../modelos/comunicacion.dart';
import '../../modelos/enums.dart';
import '../../modelos/inscripcion.dart';
import '../../modelos/taller.dart';
import '../../modelos/usuario.dart';
import '../almacen_cuentas.dart';
import 'base_datos.dart';

/// Todo lo que la app necesita al arrancar, ya leído de SQLite.
class DatosActiva {
  DatosActiva({
    required this.categorias,
    required this.especialidades,
    required this.talleres,
    required this.inscripciones,
    required this.horasPorFolio,
    required this.alumnos,
    required this.horasAlumnos,
    required this.instructores,
    required this.avisos,
    required this.avisosLeidos,
    required this.avisosArchivados,
    required this.chats,
    required this.chatsAnclados,
    required this.fondosChat,
    required this.encuestas,
    required this.solicitudes,
    required this.favoritos,
    required this.bajas,
    required this.roster,
    required this.reportes,
    required this.contadores,
  });

  final List<Categoria> categorias;
  final List<String> especialidades;
  final List<Taller> talleres;
  final List<Inscripcion> inscripciones;
  final Map<String, int> horasPorFolio;
  final List<Alumno> alumnos;
  final Map<String, int> horasAlumnos;
  final List<Instructor> instructores;
  final List<Aviso> avisos;
  final Set<int> avisosLeidos;
  final Set<int> avisosArchivados;
  final Map<int, List<MensajeChat>> chats;
  final Set<int> chatsAnclados;
  final Map<int, int> fondosChat;
  final List<RespuestaEncuesta> encuestas;
  final List<SolicitudAdmin> solicitudes;
  final Set<int> favoritos;
  final Map<int, int> bajas;
  final Map<int, List<Alumno>> roster;
  final List<({String tipo, String formato, DateTime fecha})> reportes;
  final Map<String, int> contadores;
}

class RepositorioActiva {
  RepositorioActiva(this._db);

  final Database _db;

  // ======================================================= lectura
  Future<DatosActiva> cargarTodo() async {
    final categorias = await _cargarCategorias();
    final especialidades = await _cargarEspecialidades();
    final instructores = await _cargarInstructores();
    final alumnos = await _cargarAlumnos();
    final talleres = await _cargarTalleres(
      categorias: categorias,
      instructores: instructores,
    );
    final inscripciones = await _cargarInscripciones(
      alumnos: alumnos,
      talleres: talleres,
    );

    final avisos = <Aviso>[];
    final avisosLeidos = <int>{};
    final avisosArchivados = <int>{};
    for (final f in await _db.query('avisos', orderBy: 'fecha DESC, id DESC')) {
      final id = f['id'] as int;
      avisos.add(
        Aviso(
          id: id,
          tallerId: f['taller_id'] as int?,
          tipo: enumDe(TipoAviso.values, f['tipo'], TipoAviso.informativo),
          titulo: f['titulo'] as String,
          mensaje: (f['mensaje'] as String?) ?? '',
          fecha: DateTime.parse(f['fecha'] as String),
        ),
      );
      if ((f['leido'] as int? ?? 0) == 1) avisosLeidos.add(id);
      if ((f['archivado'] as int? ?? 0) == 1) avisosArchivados.add(id);
    }

    final chats = <int, List<MensajeChat>>{};
    for (final f in await _db.query('mensajes', orderBy: 'fecha ASC, id ASC')) {
      final m = MensajeChat(
        id: f['id'] as int,
        tallerId: f['taller_id'] as int,
        rol: enumDe(Rol.values, f['rol'], Rol.alumno),
        autor: f['autor'] as String,
        texto: f['texto'] as String,
        fecha: DateTime.parse(f['fecha'] as String),
      );
      chats.putIfAbsent(m.tallerId, () => []).add(m);
    }

    final chatsAnclados = <int>{};
    final fondosChat = <int, int>{};
    for (final f in await _db.query('chats_estado')) {
      final id = f['taller_id'] as int;
      if ((f['anclado'] as int? ?? 0) == 1) chatsAnclados.add(id);
      fondosChat[id] = f['fondo'] as int? ?? 0;
    }

    final encuestas = <RespuestaEncuesta>[
      for (final f in await _db.query(
        'encuestas',
        orderBy: 'fecha DESC, id DESC',
      ))
        RespuestaEncuesta(
          id: f['id'] as int,
          tallerId: f['taller_id'] as int,
          numeroControl: f['numero_control'] as String,
          califClub: f['calif_club'] as int,
          califInstructor: f['calif_instructor'] as int,
          comentario: (f['comentario'] as String?) ?? '',
          fecha: DateTime.parse(f['fecha'] as String),
        ),
    ];

    final solicitudes = <SolicitudAdmin>[
      for (final f in await _db.query(
        'solicitudes',
        orderBy: 'fecha DESC, id DESC',
      ))
        SolicitudAdmin(
          id: f['id'] as int,
          tallerId: f['taller_id'] as int,
          instructorId: f['instructor_id'] as int,
          instructorNombre: f['instructor_nombre'] as String,
          tipo: enumDe(TipoSolicitud.values, f['tipo'], TipoSolicitud.otro),
          mensaje: (f['mensaje'] as String?) ?? '',
          fecha: DateTime.parse(f['fecha'] as String),
          estado: enumDe(
            EstadoSolicitud.values,
            f['estado'],
            EstadoSolicitud.pendiente,
          ),
          respuesta: (f['respuesta'] as String?) ?? '',
          cupoExtra: f['cupo_extra'] as int? ?? 0,
        ),
    ];

    final favoritos = <int>{
      for (final f in await _db.query('favoritos')) f['taller_id'] as int,
    };

    final bajas = <int, int>{
      for (final f in await _db.query('bajas'))
        f['taller_id'] as int: f['total'] as int,
    };

    final roster = <int, List<Alumno>>{};
    final alumnosPorId = {for (final a in alumnos) a.id: a};
    for (final f in await _db.query(
      'roster',
      orderBy: 'taller_id, alumno_id',
    )) {
      final a = alumnosPorId[f['alumno_id'] as int];
      if (a == null) continue;
      roster.putIfAbsent(f['taller_id'] as int, () => []).add(a);
    }

    final reportes = <({String tipo, String formato, DateTime fecha})>[
      for (final f in await _db.query('reportes', orderBy: 'id DESC'))
        (
          tipo: f['tipo'] as String,
          formato: f['formato'] as String,
          fecha: DateTime.parse(f['fecha'] as String),
        ),
    ];

    final contadores = <String, int>{
      for (final f in await _db.query('contadores'))
        f['clave'] as String: f['valor'] as int,
    };

    final horasPorFolio = <String, int>{
      for (final f in await _db.query('inscripciones'))
        f['folio'] as String: f['horas'] as int? ?? 0,
    };

    final horasAlumnos = <String, int>{
      for (final f in await _db.query(
        'alumnos',
        columns: ['numero_control', 'horas'],
      ))
        f['numero_control'] as String: f['horas'] as int? ?? 0,
    };

    return DatosActiva(
      categorias: categorias,
      especialidades: especialidades,
      talleres: talleres,
      inscripciones: inscripciones,
      horasPorFolio: horasPorFolio,
      alumnos: alumnos,
      horasAlumnos: horasAlumnos,
      instructores: instructores,
      avisos: avisos,
      avisosLeidos: avisosLeidos,
      avisosArchivados: avisosArchivados,
      chats: chats,
      chatsAnclados: chatsAnclados,
      fondosChat: fondosChat,
      encuestas: encuestas,
      solicitudes: solicitudes,
      favoritos: favoritos,
      bajas: bajas,
      roster: roster,
      reportes: reportes,
      contadores: contadores,
    );
  }

  Future<List<Categoria>> _cargarCategorias() async => [
    for (final f in await _db.query('categorias', orderBy: 'id'))
      Categoria(
        id: f['id'] as int,
        clave: f['clave'] as String,
        nombre: f['nombre'] as String,
        etiqueta: f['etiqueta'] as String,
        colorValue: f['color'] as int,
        icono: f['icono'] as String,
        activa: (f['activa'] as int? ?? 1) == 1,
      ),
  ];

  Future<List<String>> _cargarEspecialidades() async => [
    for (final f in await _db.query('especialidades_alumno', orderBy: 'nombre'))
      f['nombre'] as String,
  ];

  Future<List<Instructor>> _cargarInstructores() async => [
    for (final f in await _db.query('instructores', orderBy: 'id'))
      Instructor(
        id: f['id'] as int,
        nombre: f['nombre'] as String,
        apellidoPaterno: (f['apellido_paterno'] as String?) ?? '',
        apellidoMaterno: (f['apellido_materno'] as String?) ?? '',
        correo: (f['correo'] as String?) ?? '',
        telefono: _textoONull(f['telefono']),
        especialidad: (f['especialidad'] as String?) ?? '',
        activo: (f['activo'] as int? ?? 1) == 1,
      ),
  ];

  Future<List<Alumno>> _cargarAlumnos() async => [
    for (final f in await _db.query('alumnos', orderBy: 'id'))
      Alumno(
        id: f['id'] as int,
        nombre: f['nombre'] as String,
        apellidoPaterno: (f['apellido_paterno'] as String?) ?? '',
        apellidoMaterno: (f['apellido_materno'] as String?) ?? '',
        correo: (f['correo'] as String?) ?? '',
        telefono: _textoONull(f['telefono']),
        numeroControl: f['numero_control'] as String,
        grupo: (f['grupo'] as String?) ?? '',
        carrera: (f['carrera'] as String?) ?? '',
      ),
  ];

  Future<List<Taller>> _cargarTalleres({
    required List<Categoria> categorias,
    required List<Instructor> instructores,
  }) async {
    final catPorId = {for (final c in categorias) c.id: c};
    final instPorId = {for (final i in instructores) i.id: i};

    final horarios = <int, List<Horario>>{};
    for (final f in await _db.query(
      'horarios',
      orderBy: 'taller_id, orden, id',
    )) {
      horarios
          .putIfAbsent(f['taller_id'] as int, () => [])
          .add(
            Horario(
              Dia.values[(f['dia'] as int).clamp(0, Dia.values.length - 1)],
              f['hora_inicio'] as String,
              f['hora_fin'] as String,
            ),
          );
    }

    final aprendizajes = <int, List<String>>{};
    for (final f in await _db.query(
      'aprendizajes',
      orderBy: 'taller_id, orden, id',
    )) {
      aprendizajes
          .putIfAbsent(f['taller_id'] as int, () => [])
          .add(f['texto'] as String);
    }

    final talleres = <Taller>[];
    for (final f in await _db.query('talleres', orderBy: 'id')) {
      final categoria = catPorId[f['categoria_id'] as int];
      final instructor = instPorId[f['instructor_id'] as int];
      if (categoria == null || instructor == null) continue;
      final id = f['id'] as int;
      talleres.add(
        Taller(
          id: id,
          nombre: f['nombre'] as String,
          descripcion: (f['descripcion'] as String?) ?? '',
          categoria: categoria,
          lugar: (f['lugar'] as String?) ?? '',
          cupoMaximo: f['cupo_maximo'] as int,
          activo: (f['activo'] as int? ?? 1) == 1,
          instructor: instructor,
          horarios: horarios[id] ?? const [],
          aprendizajes: aprendizajes[id] ?? const [],
          inscritos: f['inscritos'] as int? ?? 0,
          foto: f['foto'] as Uint8List?,
        ),
      );
    }
    return talleres;
  }

  Future<List<Inscripcion>> _cargarInscripciones({
    required List<Alumno> alumnos,
    required List<Taller> talleres,
  }) async {
    final alumnoPorId = {for (final a in alumnos) a.id: a};
    final tallerPorId = {for (final t in talleres) t.id: t};
    final lista = <Inscripcion>[];
    for (final f in await _db.query('inscripciones', orderBy: 'fecha')) {
      final alumno = alumnoPorId[f['alumno_id'] as int];
      final taller = tallerPorId[f['taller_id'] as int];
      if (alumno == null || taller == null) continue;
      lista.add(
        Inscripcion(
          folio: f['folio'] as String,
          alumno: alumno,
          taller: taller,
          estado: enumDe(
            EstadoInscripcion.values,
            f['estado'],
            EstadoInscripcion.activa,
          ),
          fechaInscripcion: DateTime.parse(f['fecha'] as String),
        ),
      );
    }
    return lista;
  }

  /// Asistencias agrupadas como las usa EstadoApp: {"tallerId|yyyy-mm-dd": {nc: presente}}
  Future<Map<String, Map<String, bool>>> cargarAsistencias() async {
    final mapa = <String, Map<String, bool>>{};
    for (final f in await _db.query('asistencias')) {
      final clave = '${f['taller_id']}|${f['fecha']}';
      mapa.putIfAbsent(clave, () => {})[f['numero_control'] as String] =
          (f['presente'] as int? ?? 0) == 1;
    }
    return mapa;
  }

  // ======================================================= escritura
  Future<void> agregarEspecialidad(String nombre) => _db.insert(
    'especialidades_alumno',
    {'nombre': nombre},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  Future<void> eliminarEspecialidad(String nombre) => _db.delete(
    'especialidades_alumno',
    where: 'nombre = ?',
    whereArgs: [nombre],
  );

  Future<void> guardarCategoria(Categoria c) => _db.insert('categorias', {
    'id': c.id,
    'clave': c.clave,
    'nombre': c.nombre,
    'etiqueta': c.etiqueta,
    'color': c.colorValue,
    'icono': c.icono,
    'activa': c.activa ? 1 : 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> guardarAlumno(Alumno a) => _db.rawInsert(
    '''
    INSERT INTO alumnos
      (id, nombre, apellido_paterno, apellido_materno, correo, telefono,
       numero_control, grupo, carrera)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      nombre = excluded.nombre,
      apellido_paterno = excluded.apellido_paterno,
      apellido_materno = excluded.apellido_materno,
      correo = excluded.correo,
      telefono = excluded.telefono,
      numero_control = excluded.numero_control,
      grupo = excluded.grupo,
      carrera = excluded.carrera
    ''',
    [
      a.id,
      a.nombre,
      a.apellidoPaterno,
      a.apellidoMaterno,
      a.correo,
      a.telefono ?? '',
      a.numeroControl,
      a.grupo,
      a.carrera,
    ],
  );

  Future<void> guardarInstructor(Instructor i) => _db.rawInsert(
    '''
    INSERT INTO instructores
      (id, nombre, apellido_paterno, apellido_materno, correo, telefono,
       especialidad, activo)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      nombre = excluded.nombre,
      apellido_paterno = excluded.apellido_paterno,
      apellido_materno = excluded.apellido_materno,
      correo = excluded.correo,
      telefono = excluded.telefono,
      especialidad = excluded.especialidad,
      activo = excluded.activo
    ''',
    [
      i.id,
      i.nombre,
      i.apellidoPaterno,
      i.apellidoMaterno,
      i.correo,
      i.telefono ?? '',
      i.especialidad,
      i.activo ? 1 : 0,
    ],
  );

  Future<void> guardarTaller(Taller t) async {
    final datos = {
      'id': t.id,
      'nombre': t.nombre,
      'descripcion': t.descripcion,
      'categoria_id': t.categoria.id,
      'lugar': t.lugar,
      'cupo_maximo': t.cupoMaximo,
      'activo': t.activo ? 1 : 0,
      'instructor_id': t.instructor.id,
      'inscritos': t.inscritos,
      'foto': t.foto,
    };
    await _db.transaction((txn) async {
      final existe = await txn.query(
        'talleres',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [t.id],
        limit: 1,
      );
      if (existe.isEmpty) {
        await txn.insert('talleres', datos);
      } else {
        await txn.update('talleres', datos, where: 'id = ?', whereArgs: [t.id]);
      }
      await txn.delete('horarios', where: 'taller_id = ?', whereArgs: [t.id]);
      await txn.delete(
        'aprendizajes',
        where: 'taller_id = ?',
        whereArgs: [t.id],
      );
      var orden = 0;
      for (final h in t.horarios) {
        await txn.insert('horarios', {
          'taller_id': t.id,
          'dia': h.dia.index,
          'hora_inicio': h.horaInicio,
          'hora_fin': h.horaFin,
          'orden': orden++,
        });
      }
      orden = 0;
      for (final a in t.aprendizajes) {
        await txn.insert('aprendizajes', {
          'taller_id': t.id,
          'texto': a,
          'orden': orden++,
        });
      }
    });
  }

  Future<void> guardarInscripcion(Inscripcion i) => _db.rawInsert(
    '''
    INSERT INTO inscripciones (folio, alumno_id, taller_id, estado, fecha)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(folio) DO UPDATE SET
      alumno_id = excluded.alumno_id,
      taller_id = excluded.taller_id,
      estado = excluded.estado
    ''',
    [
      i.folio,
      i.alumno.id,
      i.taller.id,
      i.estado.name,
      i.fechaInscripcion.toIso8601String(),
    ],
  );

  Future<void> actualizarInscripcion(Inscripcion i) => _db.update(
    'inscripciones',
    {'estado': i.estado.name, 'taller_id': i.taller.id},
    where: 'folio = ?',
    whereArgs: [i.folio],
  );

  Future<void> guardarHorasFolio(String folio, int horas) => _db.update(
    'inscripciones',
    {'horas': horas},
    where: 'folio = ?',
    whereArgs: [folio],
  );

  Future<void> guardarHorasAlumno(String numeroControl, int horas) =>
      _db.update(
        'alumnos',
        {'horas': horas},
        where: 'numero_control = ?',
        whereArgs: [numeroControl],
      );

  Future<void> guardarAsistencia(
    int tallerId,
    String fecha,
    Map<String, bool> marcas,
  ) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'asistencias',
        where: 'taller_id = ? AND fecha = ?',
        whereArgs: [tallerId, fecha],
      );
      for (final e in marcas.entries) {
        await txn.insert('asistencias', {
          'taller_id': tallerId,
          'fecha': fecha,
          'numero_control': e.key,
          'presente': e.value ? 1 : 0,
        });
      }
    });
  }

  Future<void> guardarAviso(
    Aviso a, {
    bool leido = false,
    bool archivado = false,
  }) => _db.insert('avisos', {
    'id': a.id,
    'taller_id': a.tallerId,
    'tipo': a.tipo.name,
    'titulo': a.titulo,
    'mensaje': a.mensaje,
    'fecha': a.fecha.toIso8601String(),
    'leido': leido ? 1 : 0,
    'archivado': archivado ? 1 : 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> eliminarAviso(int id) =>
      _db.delete('avisos', where: 'id = ?', whereArgs: [id]);

  Future<void> estadoAviso(int id, {bool? leido, bool? archivado}) =>
      _db.update(
        'avisos',
        {
          if (leido != null) 'leido': leido ? 1 : 0,
          if (archivado != null) 'archivado': archivado ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> guardarMensaje(MensajeChat m) => _db.insert('mensajes', {
    'id': m.id,
    'taller_id': m.tallerId,
    'rol': m.rol.name,
    'autor': m.autor,
    'texto': m.texto,
    'fecha': m.fecha.toIso8601String(),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> guardarEstadoChat(int tallerId, {bool? anclado, int? fondo}) =>
      _db.insert('chats_estado', {
        'taller_id': tallerId,
        if (anclado != null) 'anclado': anclado ? 1 : 0,
        if (fondo != null) 'fondo': fondo,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> guardarEncuesta(RespuestaEncuesta e) => _db.insert('encuestas', {
    'id': e.id,
    'taller_id': e.tallerId,
    'numero_control': e.numeroControl,
    'calif_club': e.califClub,
    'calif_instructor': e.califInstructor,
    'comentario': e.comentario,
    'fecha': e.fecha.toIso8601String(),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> guardarSolicitud(SolicitudAdmin s) => _db.insert('solicitudes', {
    'id': s.id,
    'taller_id': s.tallerId,
    'instructor_id': s.instructorId,
    'instructor_nombre': s.instructorNombre,
    'tipo': s.tipo.name,
    'mensaje': s.mensaje,
    'fecha': s.fecha.toIso8601String(),
    'estado': s.estado.name,
    'respuesta': s.respuesta,
    'cupo_extra': s.cupoExtra,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> eliminarSolicitud(int id) =>
      _db.delete('solicitudes', where: 'id = ?', whereArgs: [id]);

  Future<void> guardarFavorito(int tallerId, bool favorito) => favorito
      ? _db.insert('favoritos', {
          'taller_id': tallerId,
        }, conflictAlgorithm: ConflictAlgorithm.replace)
      : _db.delete('favoritos', where: 'taller_id = ?', whereArgs: [tallerId]);

  Future<void> guardarBaja(int tallerId, int total) => _db.insert('bajas', {
    'taller_id': tallerId,
    'total': total,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> guardarReporte(String tipo, String formato, DateTime fecha) =>
      _db.insert('reportes', {
        'tipo': tipo,
        'formato': formato,
        'fecha': fecha.toIso8601String(),
      });

  Future<void> guardarContador(String clave, int valor) => _db.insert(
    'contadores',
    {'clave': clave, 'valor': valor},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  // ======================================================= cuentas
  Future<int> siguienteIdUsuario() async {
    final filas = await _db.query(
      'contadores',
      columns: ['valor'],
      where: 'clave = ?',
      whereArgs: ['usuario'],
      limit: 1,
    );
    return filas.isEmpty ? 1000 : filas.first['valor'] as int;
  }

  Future<List<CuentaGuardada>> cargarCuentas() async {
    final tallerIds = <int, List<int>>{};
    for (final f in await _db.query(
      'talleres',
      columns: ['id', 'instructor_id'],
    )) {
      tallerIds
          .putIfAbsent(f['instructor_id'] as int, () => [])
          .add(f['id'] as int);
    }
    return [
      for (final f in await _db.query('usuarios', orderBy: 'id'))
        CuentaGuardada(
          id: f['id'] as int,
          rol: enumDe(Rol.values, f['rol'], Rol.alumno),
          usuario: f['usuario'] as String,
          correo: (f['correo'] as String?) ?? '',
          nombre: (f['nombre'] as String?) ?? '',
          apellidoPaterno: (f['apellido_paterno'] as String?) ?? '',
          apellidoMaterno: (f['apellido_materno'] as String?) ?? '',
          telefono: (f['telefono'] as String?) ?? '',
          especialidad: (f['especialidad'] as String?) ?? '',
          numeroControl: (f['numero_control'] as String?) ?? '',
          grupo: (f['grupo'] as String?) ?? '',
          carrera: (f['carrera'] as String?) ?? '',
          tallerIds: List.of(tallerIds[f['id']] ?? const []),
          activo: (f['activo'] as int? ?? 1) == 1,
          debeCambiarContrasena:
              (f['debe_cambiar_contrasena'] as int? ?? 0) == 1,
          sal: (f['sal'] as String?) ?? '',
          hash: (f['hash'] as String?) ?? '',
        ),
    ];
  }

  /// Reemplaza todas las cuentas guardadas y sus datos de perfil.
  Future<void> guardarCuentas(
    List<CuentaGuardada> cuentas, {
    required int siguienteId,
  }) async {
    await _db.transaction((txn) async {
      final ids = cuentas.map((c) => c.id).toList();
      if (ids.isEmpty) {
        await txn.delete('usuarios');
      } else {
        await txn.delete(
          'usuarios',
          where: 'id NOT IN (${List.filled(ids.length, '?').join(',')})',
          whereArgs: ids,
        );
      }
      for (final c in cuentas) {
        await txn.insert('usuarios', {
          'id': c.id,
          'rol': c.rol.name,
          'usuario': c.usuario,
          'correo': c.correo,
          'nombre': c.nombre,
          'apellido_paterno': c.apellidoPaterno,
          'apellido_materno': c.apellidoMaterno,
          'telefono': c.telefono,
          'especialidad': c.especialidad,
          'numero_control': c.numeroControl,
          'grupo': c.grupo,
          'carrera': c.carrera,
          'activo': c.activo ? 1 : 0,
          'debe_cambiar_contrasena': c.debeCambiarContrasena ? 1 : 0,
          'sal': c.sal,
          'hash': c.hash,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        if (c.rol == Rol.alumno) {
          await txn.rawInsert(
            '''
            INSERT INTO alumnos
              (id, nombre, apellido_paterno, apellido_materno, correo,
               telefono, numero_control, grupo, carrera)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              nombre = excluded.nombre,
              apellido_paterno = excluded.apellido_paterno,
              apellido_materno = excluded.apellido_materno,
              correo = excluded.correo,
              telefono = excluded.telefono,
              numero_control = excluded.numero_control,
              grupo = excluded.grupo,
              carrera = excluded.carrera
            ''',
            [
              c.id,
              c.nombre,
              c.apellidoPaterno,
              c.apellidoMaterno,
              c.correo,
              c.telefono,
              c.numeroControl,
              c.grupo,
              c.carrera,
            ],
          );
        } else if (c.rol == Rol.instructor) {
          await txn.rawInsert(
            '''
            INSERT INTO instructores
              (id, nombre, apellido_paterno, apellido_materno, correo,
               telefono, especialidad, activo)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              nombre = excluded.nombre,
              apellido_paterno = excluded.apellido_paterno,
              apellido_materno = excluded.apellido_materno,
              correo = excluded.correo,
              telefono = excluded.telefono,
              especialidad = excluded.especialidad,
              activo = excluded.activo
            ''',
            [
              c.id,
              c.nombre,
              c.apellidoPaterno,
              c.apellidoMaterno,
              c.correo,
              c.telefono,
              c.especialidad,
              c.activo ? 1 : 0,
            ],
          );
        }
      }
      await txn.insert('contadores', {
        'clave': 'usuario',
        'valor': siguienteId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}

String? _textoONull(Object? valor) {
  final texto = valor as String?;
  return (texto == null || texto.isEmpty) ? null : texto;
}