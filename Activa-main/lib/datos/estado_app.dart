import 'dart:async';

import 'package:activa/modelos/taller.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/enums.dart';
import '../modelos/inscripcion.dart';
import '../modelos/categoria.dart';
import '../nucleo/utilidades/formateadores.dart';
import '../modelos/usuario.dart';
import '../modelos/comunicacion.dart';
import '../nucleo/servicios/notificaciones.dart';
import 'almacen_cuentas.dart';

class EstadoApp extends ChangeNotifier {
  EstadoApp([this._almacen]);

  final AlmacenCuentas? _almacen;
  final SupabaseClient _db = Supabase.instance.client;

  static bool _aBool(Object? v, {bool defecto = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return defecto;
  }

  static int _aInt(Object? v, {int defecto = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defecto;
    return defecto;
  }

  /// Lee una tabla y devuelve [] si algo falla (tabla inexistente, RLS,
  /// red caída...). Así una tabla ausente no tumba toda la carga.
  Future<List<Map<String, dynamic>>> _leer(
    String tabla, {
    String? orden,
    bool ascendente = true,
  }) async {
    try {
      final consulta = _db.from(tabla).select();
      final filas = orden == null
          ? await consulta.timeout(const Duration(seconds: 8))
          : await consulta
                .order(orden, ascending: ascendente)
                .timeout(const Duration(seconds: 8));
      return List<Map<String, dynamic>>.from(filas);
    } catch (e) {
      debugPrint('ACTIVA: no se pudo leer la tabla "$tabla": $e');
      return const [];
    }
  }

  /// Lee los datos compartidos desde Supabase y actualiza el estado.
  Future<void> cargar() async {
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _leer('categorias', orden: 'id'),
        _leer('especialidades_alumno', orden: 'nombre'),
        _leer('talleres', orden: 'id'),
        _leer('inscripciones'),
        _leer('favoritos'),
        _leer('avisos', orden: 'id', ascendente: false),
        _leer('mensajes', orden: 'id'),
        _leer('encuestas', orden: 'id', ascendente: false),
        _leer('bajas'),
        _leer('reportes', orden: 'id', ascendente: false),
        _leer('asistencias'),
        _leer('horarios', orden: 'orden'),
        _leer('aprendizajes', orden: 'orden'),
        _leer('solicitudes', orden: 'id', ascendente: false),
        _leer('chats_estado'),
      ]);

      // Categorías
      final catsRows = List<Map<String, dynamic>>.from(results[0]);
      _categorias
        ..clear()
        ..addAll(
          catsRows.map(
            (r) => Categoria(
              id: _aInt(r['id']),
              clave: (r['clave'] ?? '').toString(),
              nombre: (r['nombre'] ?? '').toString(),
              etiqueta: (r['etiqueta'] ?? '').toString(),
              colorValue: _aInt(r['color']),
              icono: (r['icono'] ?? '').toString(),
              activa: _aBool(r['activa'], defecto: true),
            ),
          ),
        );

      // Especialidades
      final espRows = List<Map<String, dynamic>>.from(results[1]);
      _especialidades
        ..clear()
        ..addAll(espRows.map((r) => (r['nombre'] ?? '').toString()))
        ..sort();

      // Horarios y aprendizajes (se usan al construir los talleres)
      final horariosPorTaller = <int, List<Horario>>{};
      for (final r in List<Map<String, dynamic>>.from(results[11])) {
        final tId = _aInt(r['taller_id']);
        final dia = Dia.values.firstWhere(
          (d) => d.index == _aInt(r['dia']),
          orElse: () => Dia.lunes,
        );
        horariosPorTaller
            .putIfAbsent(tId, () => [])
            .add(
              Horario(
                dia,
                (r['hora_inicio'] ?? '').toString(),
                (r['hora_fin'] ?? '').toString(),
              ),
            );
      }
      final aprendizajesPorTaller = <int, List<String>>{};
      for (final r in List<Map<String, dynamic>>.from(results[12])) {
        aprendizajesPorTaller
            .putIfAbsent(_aInt(r['taller_id']), () => [])
            .add((r['texto'] ?? '').toString());
      }

      // Talleres
      final talleresRows = List<Map<String, dynamic>>.from(results[2]);
      final catPorId = {for (final c in _categorias) c.id: c};
      final instCuentas = _almacen?.instructores ?? const <CuentaGuardada>[];
      final instPorId = {for (final c in instCuentas) c.id: c.aInstructor()};

      _talleres
        ..clear()
        ..addAll(
          talleresRows.map((r) {
            final tId = _aInt(r['id']);
            final cat =
                catPorId[_aInt(r['categoria_id'])] ??
                (_categorias.isNotEmpty
                    ? _categorias.first
                    : const Categoria(
                        id: 1,
                        clave: 'general',
                        nombre: 'General',
                        etiqueta: 'General',
                        colorValue: 0xFF2196F3,
                        icono: 'star',
                      ));
            final inst =
                instPorId[_aInt(r['instructor_id'])] ??
                Instructor(
                  id: _aInt(r['instructor_id']),
                  nombre: 'Instructor',
                  apellidoPaterno: '',
                  correo: '',
                  especialidad: '',
                );
            return Taller(
              id: tId,
              nombre: (r['nombre'] ?? '').toString(),
              descripcion: (r['descripcion'] ?? '').toString(),
              categoria: cat,
              lugar: (r['lugar'] ?? '').toString(),
              cupoMaximo: _aInt(r['cupo_maximo'], defecto: 20),
              horasOtorga: _aInt(r['horas_otorga'], defecto: 60),
              activo: _aBool(r['activo'], defecto: true),
              instructor: inst,
              horarios: horariosPorTaller[tId] ?? const [],
              aprendizajes: aprendizajesPorTaller[tId] ?? const [],
              inscritos: _aInt(r['inscritos']),
            );
          }),
        );

      final maxTallerId = _talleres.fold<int>(0, (a, t) => t.id > a ? t.id : a);
      if (maxTallerId >= _tallerSeq) _tallerSeq = maxTallerId + 1;

      // Inscripciones
      final insRows = List<Map<String, dynamic>>.from(results[3]);
      final tallerPorIdMap = {for (final t in _talleres) t.id: t};
      final alumnoPorIdMap = {for (final a in todosAlumnos) a.id: a};
      _inscripciones.clear();
      _horas.clear();
      for (final r in insRows) {
        final tId = _aInt(r['taller_id']);
        final aId = _aInt(r['alumno_id']);
        final t = tallerPorIdMap[tId];
        final al = alumnoPorIdMap[aId];
        if (t == null || al == null) continue;
        final estadoStr = (r['estado'] ?? 'activa').toString();
        final estado = estadoStr == 'cancelada'
            ? EstadoInscripcion.cancelada
            : EstadoInscripcion.activa;
        final folio = (r['folio'] ?? '').toString();
        _inscripciones.add(
          Inscripcion(
            folio: folio,
            alumno: al,
            taller: t,
            estado: estado,
            fechaInscripcion:
                DateTime.tryParse((r['fecha'] ?? '').toString()) ??
                DateTime.now(),
          ),
        );
        _horas[folio] = _aInt(r['horas']);
        final m = RegExp(r'-(\d+)$').firstMatch(folio);
        final n = m == null ? null : int.tryParse(m.group(1)!);
        if (n != null && n >= _seq) _seq = n + 1;
      }

      // Favoritos
      final favRows = List<Map<String, dynamic>>.from(results[4]);
      _favoritos
        ..clear()
        ..addAll(favRows.map((r) => _aInt(r['taller_id'])));

      // Avisos
      final avisosRows = List<Map<String, dynamic>>.from(results[5]);
      _avisos.clear();
      _avisosLeidos.clear();
      _avisosArchivados.clear();
      for (final r in avisosRows) {
        final id = _aInt(r['id']);
        final tipoNombre = (r['tipo'] ?? '').toString();
        final tipo = TipoAviso.values.firstWhere(
          (e) => e.name == tipoNombre,
          orElse: () => TipoAviso.values.first,
        );
        _avisos.add(
          Aviso(
            id: id,
            tallerId: r['taller_id'] == null ? null : _aInt(r['taller_id']),
            tipo: tipo,
            titulo: (r['titulo'] ?? '').toString(),
            mensaje: (r['mensaje'] ?? '').toString(),
            fecha:
                DateTime.tryParse((r['fecha'] ?? '').toString()) ??
                DateTime.now(),
          ),
        );
        if (_aBool(r['leido'])) _avisosLeidos.add(id);
        if (_aBool(r['archivado'])) _avisosArchivados.add(id);
      }
      final maxAvisoId = _avisos.fold<int>(0, (a, av) => av.id > a ? av.id : a);
      if (maxAvisoId >= _avisoSeq) _avisoSeq = maxAvisoId + 1;

      // Mensajes
      final msgRows = List<Map<String, dynamic>>.from(results[6]);
      _chats.clear();
      for (final r in msgRows) {
        final tId = _aInt(r['taller_id']);
        final rolNombre = (r['rol'] ?? 'alumno').toString();
        final rol = Rol.values.firstWhere(
          (e) => e.name == rolNombre,
          orElse: () => Rol.alumno,
        );
        _chats
            .putIfAbsent(tId, () => [])
            .add(
              MensajeChat(
                id: _aInt(r['id']),
                tallerId: tId,
                rol: rol,
                autor: (r['autor'] ?? '').toString(),
                texto: (r['texto'] ?? '').toString(),
                fecha:
                    DateTime.tryParse((r['fecha'] ?? '').toString()) ??
                    DateTime.now(),
              ),
            );
      }

      // Encuestas
      final encRows = List<Map<String, dynamic>>.from(results[7]);
      _encuestas
        ..clear()
        ..addAll(
          encRows.map(
            (r) => RespuestaEncuesta(
              id: _aInt(r['id']),
              tallerId: _aInt(r['taller_id']),
              numeroControl: (r['numero_control'] ?? '').toString(),
              califClub: _aInt(r['calif_club']),
              califInstructor: _aInt(r['calif_instructor']),
              comentario: (r['comentario'] ?? '').toString(),
              fecha:
                  DateTime.tryParse((r['fecha'] ?? '').toString()) ??
                  DateTime.now(),
            ),
          ),
        );

      // Bajas
      final bajasRows = List<Map<String, dynamic>>.from(results[8]);
      _bajas
        ..clear()
        ..addAll({
          for (final r in bajasRows) _aInt(r['taller_id']): _aInt(r['total']),
        });

      // Reportes
      final repRows = List<Map<String, dynamic>>.from(results[9]);
      _reportes
        ..clear()
        ..addAll(
          repRows.map(
            (r) => (
              tipo: (r['tipo'] ?? '').toString(),
              formato: (r['formato'] ?? '').toString(),
              fecha:
                  DateTime.tryParse((r['fecha'] ?? '').toString()) ??
                  DateTime.now(),
            ),
          ),
        );

      // Asistencias
      final asistRows = List<Map<String, dynamic>>.from(results[10]);
      _asistencias.clear();
      for (final r in asistRows) {
        final k = '${_aInt(r['taller_id'])}|${(r['fecha'] ?? '').toString()}';
        final mapa = _asistencias.putIfAbsent(k, () => <String, bool>{});
        mapa[(r['numero_control'] ?? '').toString()] = _aBool(r['presente']);
      }

      // Solicitudes al admin
      final solRows = List<Map<String, dynamic>>.from(results[13]);
      _solicitudes
        ..clear()
        ..addAll(
          solRows.map(
            (r) => SolicitudAdmin(
              id: _aInt(r['id']),
              tallerId: _aInt(r['taller_id']),
              instructorId: _aInt(r['instructor_id']),
              instructorNombre: (r['instructor_nombre'] ?? '').toString(),
              tipo: TipoSolicitud.values.firstWhere(
                (e) => e.name == (r['tipo'] ?? '').toString(),
                orElse: () => TipoSolicitud.otro,
              ),
              mensaje: (r['mensaje'] ?? '').toString(),
              fecha:
                  DateTime.tryParse((r['fecha'] ?? '').toString()) ??
                  DateTime.now(),
              estado: EstadoSolicitud.values.firstWhere(
                (e) => e.name == (r['estado'] ?? '').toString(),
                orElse: () => EstadoSolicitud.pendiente,
              ),
              respuesta: (r['respuesta'] ?? '').toString(),
              cupoExtra: _aInt(r['cupo_extra']),
            ),
          ),
        );
      final maxSolId = _solicitudes.fold<int>(0, (a, s) => s.id > a ? s.id : a);
      if (maxSolId >= _solSeq) _solSeq = maxSolId + 1;

      // Estado de chats (anclados y fondo)
      _chatsAnclados.clear();
      _fondosChat.clear();
      for (final r in List<Map<String, dynamic>>.from(results[14])) {
        final id = _aInt(r['taller_id']);
        if (_aBool(r['anclado'])) _chatsAnclados.add(id);
        _fondosChat[id] = _aInt(r['fondo']);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ACTIVA: error al cargar desde Supabase: $e');
    }
  }

  void _guardar(Future<void> Function(SupabaseClient db) accion) {
    unawaited(
      accion(_db).catchError((Object e, StackTrace _) {
        debugPrint('ACTIVA: error escribiendo en Supabase: $e');
      }),
    );
  }

  final List<Taller> _talleres = [];
  final List<Inscripcion> _inscripciones = [];
  final Set<int> _favoritos = {};
  final Map<int, int> _bajas = {};
  int _seq = 1;

  List<Taller> get talleres => List.unmodifiable(_talleres);
  List<Inscripcion> get inscripciones => List.unmodifiable(_inscripciones);

  Taller tallerPorId(int id) => _talleres.firstWhere((t) => t.id == id);

  String nombreDeTaller(int? tallerId) {
    if (tallerId == null) return 'Aviso general';
    return tallerPorId(tallerId).nombre;
  }

  bool estaInscrito(int tallerId) => _inscripciones.any(
    (i) =>
        i.taller.id == tallerId &&
        i.estado == EstadoInscripcion.activa &&
        i.alumno.numeroControl == alumno.numeroControl,
  );

  List<Inscripcion> inscripcionesDeAlumno(String numeroControl) =>
      _inscripciones
          .where(
            (i) =>
                i.estado == EstadoInscripcion.activa &&
                i.alumno.numeroControl == numeroControl,
          )
          .toList();

  Inscripcion? inscripcionPorFolio(String folio) {
    for (final i in _inscripciones) {
      if (i.folio == folio) return i;
    }
    return null;
  }

  bool esFavorito(int id) => _favoritos.contains(id);

  void toggleFavorito(int id) {
    final ahoraEsFavorito = !_favoritos.contains(id);
    if (ahoraEsFavorito) {
      _favoritos.add(id);
    } else {
      _favoritos.remove(id);
    }
    _guardar((db) async {
      if (ahoraEsFavorito) {
        await db.from('favoritos').upsert({'taller_id': id});
      } else {
        await db.from('favoritos').delete().eq('taller_id', id);
      }
    });
    notifyListeners();
  }

  Inscripcion? inscribir(Taller t) {
    final actual = tallerPorId(t.id);
    if (!actual.hayCupo || estaInscrito(t.id)) return null;

    final actualizado = actual.copyWith(inscritos: actual.inscritos + 1);
    _talleres[_talleres.indexWhere((x) => x.id == t.id)] = actualizado;

    final ins = Inscripcion(
      folio: _folio(actualizado),
      alumno: alumno,
      taller: actualizado,
      fechaInscripcion: DateTime.now(),
    );
    _inscripciones.add(ins);
    _guardar((db) async {
      await db.from('inscripciones').insert({
        'folio': ins.folio,
        'alumno_id': alumno.id,
        'taller_id': actualizado.id,
        'estado': EstadoInscripcion.activa.name,
        'fecha': ins.fechaInscripcion.toIso8601String(),
        'horas': 0,
      });
      await db
          .from('talleres')
          .update({'inscritos': actualizado.inscritos})
          .eq('id', actualizado.id);
    });
    notifyListeners();
    return ins;
  }

  static const _acentos = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ñ': 'n',
  };

  String _folio(Taller t) {
    final limpio = t.nombre
        .toLowerCase()
        .split('')
        .map((c) => _acentos[c] ?? c)
        .join()
        .replaceAll(RegExp(r'[^a-z]'), '');
    final prefijo = limpio.substring(0, 3).toUpperCase();
    return '$prefijo-2026-${(_seq++).toString().padLeft(4, '0')}';
  }

  final List<Categoria> _categorias = [];

  List<Categoria> get categorias =>
      List.unmodifiable(_categorias.where((c) => c.activa));

  /// Agrega una categoría y devuelve la versión con el id real de Supabase.
  Future<Categoria?> agregarCategoria(Categoria c) async {
    try {
      final fila = await _db
          .from('categorias')
          .insert({
            'clave': c.clave,
            'nombre': c.nombre,
            'etiqueta': c.etiqueta,
            'color': c.colorValue,
            'icono': c.icono,
            'activa': c.activa,
          })
          .select()
          .single();
      final nueva = Categoria(
        id: _aInt(fila['id']),
        clave: (fila['clave'] ?? c.clave).toString(),
        nombre: (fila['nombre'] ?? c.nombre).toString(),
        etiqueta: (fila['etiqueta'] ?? c.etiqueta).toString(),
        colorValue: _aInt(fila['color'], defecto: c.colorValue),
        icono: (fila['icono'] ?? c.icono).toString(),
        activa: _aBool(fila['activa'], defecto: true),
      );
      _categorias.add(nueva);
      notifyListeners();
      return nueva;
    } catch (e) {
      debugPrint('ACTIVA: no se pudo agregar la categoría: $e');
      return null;
    }
  }

  /// Edita una categoría existente. Devuelve el error o null.
  Future<String?> editarCategoria(Categoria c) async {
    final idx = _categorias.indexWhere((x) => x.id == c.id);
    if (idx < 0) return 'Error: no se encontró la categoría';
    try {
      await _db
          .from('categorias')
          .update({
            'clave': c.clave,
            'nombre': c.nombre,
            'etiqueta': c.etiqueta,
            'color': c.colorValue,
            'icono': c.icono,
            'activa': c.activa,
          })
          .eq('id', c.id);
    } catch (e) {
      debugPrint('ACTIVA: no se pudo editar la categoría: $e');
      return 'Error: no se pudo guardar la categoría';
    }
    _categorias[idx] = c;
    // los talleres guardan una copia de la categoría: actualizarla
    for (var i = 0; i < _talleres.length; i++) {
      if (_talleres[i].categoria.id == c.id) {
        _talleres[i] = _talleres[i].copyWith(categoria: c);
      }
    }
    notifyListeners();
    return null;
  }

  /// Elimina (o desactiva, si tiene talleres) una categoría.
  Future<String?> eliminarCategoria(int id) async {
    final idx = _categorias.indexWhere((x) => x.id == id);
    if (idx < 0) return 'Error: no se encontró la categoría';
    if (_categorias.where((c) => c.activa).length <= 1) {
      return 'Error: debe existir al menos una categoría activa';
    }
    final enUso = _talleres.any((t) => t.categoria.id == id);
    try {
      if (enUso) {
        await _db.from('categorias').update({'activa': false}).eq('id', id);
        _categorias[idx] = _categorias[idx].copyWith(activa: false);
      } else {
        await _db.from('categorias').delete().eq('id', id);
        _categorias.removeAt(idx);
      }
    } catch (e) {
      debugPrint('ACTIVA: no se pudo eliminar la categoría: $e');
      return 'Error: no se pudo eliminar la categoría';
    }
    notifyListeners();
    return null;
  }

  final List<String> _especialidades = [];

  List<String> get especialidades => List.unmodifiable(_especialidades);

  bool agregarEspecialidad(String nombre) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return false;
    final yaExiste = _especialidades.any(
      (e) => e.toLowerCase() == limpio.toLowerCase(),
    );
    if (yaExiste) return false;
    _especialidades
      ..add(limpio)
      ..sort();
    _guardar((db) async {
      await db.from('especialidades_alumno').insert({'nombre': limpio});
    });
    notifyListeners();
    return true;
  }

  /// Renombra una especialidad y actualiza a los alumnos que la tenían.
  Future<String?> editarEspecialidad(String anterior, String nuevo) async {
    final limpio = nuevo.trim();
    if (limpio.isEmpty) return 'Error: escribe el nombre de la especialidad';
    if (limpio.toLowerCase() == anterior.toLowerCase()) return null;
    if (_especialidades.any((e) => e.toLowerCase() == limpio.toLowerCase())) {
      return 'Error: esa especialidad ya existe';
    }
    try {
      await _db
          .from('especialidades_alumno')
          .update({'nombre': limpio})
          .eq('nombre', anterior);
      await _db
          .from('usuarios')
          .update({'carrera': limpio})
          .eq('carrera', anterior);
    } catch (e) {
      debugPrint('ACTIVA: no se pudo editar la especialidad: $e');
      return 'Error: no se pudo guardar la especialidad';
    }
    final idx = _especialidades.indexOf(anterior);
    if (idx >= 0) {
      _especialidades[idx] = limpio;
      _especialidades.sort();
    }
    for (final c in _almacen?.alumnos ?? const <CuentaGuardada>[]) {
      if (c.carrera == anterior) c.carrera = limpio;
    }
    notifyListeners();
    return null;
  }

  void eliminarEspecialidad(String nombre) {
    _especialidades.remove(nombre);
    _guardar((db) async {
      await db.from('especialidades_alumno').delete().eq('nombre', nombre);
    });
    notifyListeners();
  }

  static const Alumno alumnoVacio = Alumno(
    id: 0,
    nombre: '',
    apellidoPaterno: '',
    correo: '',
    numeroControl: '',
    grupo: '',
    carrera: '',
  );
  static const Instructor instructorVacio = Instructor(
    id: 0,
    nombre: '',
    apellidoPaterno: '',
    correo: '',
    especialidad: '',
  );
  static const Administrador adminVacio = Administrador(
    id: 0,
    nombre: '',
    apellidoPaterno: '',
    correo: '',
    cargo: '',
  );

  Alumno alumno = alumnoVacio;
  final Map<String, int> _horas = {};
  final List<Aviso> _avisos = [];

  List<Aviso> get avisos => List.unmodifiable(_avisos);

  List<Inscripcion> get misInscripciones => _inscripciones
      .where(
        (i) =>
            i.estado == EstadoInscripcion.activa &&
            i.alumno.numeroControl == alumno.numeroControl,
      )
      .toList();

  int get horasRealizadas => _inscripciones
      .where((i) => i.alumno.numeroControl == alumno.numeroControl)
      .fold(0, (a, i) => a + (_horas[i.folio] ?? 0));
  int horasDe(String folio) => _horas[folio] ?? 0;

  void cancelar(String folio) {
    final idx = _inscripciones.indexWhere((i) => i.folio == folio);
    if (idx < 0) return;
    final ins = _inscripciones[idx];
    final nuevoTotalBajas = (_bajas[ins.taller.id] ?? 0) + 1;
    _bajas[ins.taller.id] = nuevoTotalBajas;

    _inscripciones[idx] = ins.copyWith(estado: EstadoInscripcion.cancelada);
    final ti = _talleres.indexWhere((t) => t.id == ins.taller.id);
    final nuevoInscritos = _talleres[ti].inscritos - 1;
    _talleres[ti] = _talleres[ti].copyWith(inscritos: nuevoInscritos);

    _guardar((db) async {
      await db
          .from('inscripciones')
          .update({'estado': EstadoInscripcion.cancelada.name})
          .eq('folio', folio);
      await db
          .from('talleres')
          .update({'inscritos': nuevoInscritos})
          .eq('id', ins.taller.id);
      await db.from('bajas').upsert({
        'taller_id': ins.taller.id,
        'total': nuevoTotalBajas,
      });
    });
    notifyListeners();
  }

  void actualizarPerfil(String nombreCompleto, String telefono) {
    final p = nombreCompleto.trim().split(RegExp(r'\s+'));
    alumno = p.length >= 3
        ? alumno.copyWith(
            nombre: p.sublist(0, p.length - 2).join(' '),
            apellidoPaterno: p[p.length - 2],
            apellidoMaterno: p.last,
            telefono: telefono.trim(),
          )
        : alumno.copyWith(
            nombre: p.first,
            apellidoPaterno: p.length > 1 ? p[1] : '',
            apellidoMaterno: '',
            telefono: telefono.trim(),
          );
    final c = _almacen?.porId(alumno.id);
    if (c != null && c.rol == Rol.alumno) {
      c.nombre = alumno.nombre;
      c.apellidoPaterno = alumno.apellidoPaterno;
      c.apellidoMaterno = alumno.apellidoMaterno;
      c.telefono = alumno.telefono ?? '';
      unawaited(_almacen!.actualizar(c));
    }

    notifyListeners();
  }

  Instructor instructor = instructorVacio;
  final Map<int, List<Alumno>> _roster = {};
  final Map<String, Map<String, bool>> _asistencias = {};

  Map<String, Map<String, bool>> get asistencias =>
      Map.unmodifiable(_asistencias);

  List<Taller> get misGrupos =>
      _talleres.where((t) => t.instructor.id == instructor.id).toList();

  List<Alumno> alumnosDe(int tallerId) {
    final vistos = <String>{};
    final lista = <Alumno>[];

    void agregar(Alumno a) {
      if (a.numeroControl.isEmpty) return;
      if (vistos.add(a.numeroControl)) lista.add(a);
    }

    for (final a in _roster[tallerId] ?? const <Alumno>[]) {
      agregar(a);
    }
    for (final i in _inscripciones) {
      if (i.taller.id == tallerId && i.estado == EstadoInscripcion.activa) {
        agregar(i.alumno);
      }
    }
    if (estaInscrito(tallerId)) agregar(alumno);
    return lista;
  }

  String _key(int tallerId, DateTime f) => '$tallerId|${fechaIso(f)}';

  Map<String, bool> asistenciaDe(int tallerId, DateTime f) =>
      Map.of(_asistencias[_key(tallerId, f)] ?? {});

  void guardarAsistencia(Taller t, DateTime f, Map<String, bool> marcas) {
    final k = _key(t.id, f);
    final antes = _asistencias[k] ?? const <String, bool>{};

    final cambios = <String, int>{};
    for (final e in marcas.entries) {
      final ins = _inscripciones
          .where(
            (i) =>
                i.taller.id == t.id &&
                i.estado == EstadoInscripcion.activa &&
                i.alumno.numeroControl == e.key,
          )
          .firstOrNull;
      if (ins == null) continue;

      final eraP = antes[e.key] == true;
      final esP = e.value;
      final actual = _horas[ins.folio] ?? 0;
      if (!eraP && esP) {
        _horas[ins.folio] = actual + 1;
      } else if (eraP && !esP) {
        final nuevo = actual - 1;
        _horas[ins.folio] = nuevo < 0 ? 0 : nuevo;
      }
      if (_horas[ins.folio] != actual) {
        cambios[ins.folio] = _horas[ins.folio] ?? 0;
      }
    }

    _asistencias[k] = Map.of(marcas);

    final totales = <String, int>{};
    for (final ins in _inscripciones) {
      totales.update(
        ins.alumno.numeroControl,
        (v) => v + (_horas[ins.folio] ?? 0),
        ifAbsent: () => _horas[ins.folio] ?? 0,
      );
    }

    final fechaTexto = fechaIso(f);
    _guardar((db) async {
      for (final c in cambios.entries) {
        await db
            .from('inscripciones')
            .update({'horas': c.value})
            .eq('folio', c.key);
      }
      for (final m in marcas.entries) {
        await db.from('asistencias').upsert({
          'taller_id': t.id,
          'fecha': fechaTexto,
          'numero_control': m.key,
          'presente': m.value,
        }, onConflict: 'taller_id,fecha,numero_control');
      }
    });

    _horasOtros
      ..clear()
      ..addAll(totales);
    notifyListeners();
  }

  ({int asistidas, int total}) asistenciaDeAlumno(
    int tallerId,
    String numeroControl,
  ) {
    var asistidas = 0;
    var total = 0;
    for (final e in _asistencias.entries) {
      if (int.tryParse(e.key.split('|').first) != tallerId) continue;
      final presente = e.value[numeroControl];
      if (presente == null) continue;
      total++;
      if (presente) asistidas++;
    }
    return (asistidas: asistidas, total: total);
  }

  int get porcentajeAsistencia {
    final nc = alumno.numeroControl;
    if (nc.isEmpty) return 0;
    var asistidas = 0;
    var total = 0;
    for (final e in _asistencias.entries) {
      final presente = e.value[nc];
      if (presente == null) continue;
      total++;
      if (presente) asistidas++;
    }
    return total == 0 ? 0 : (asistidas * 100 / total).round();
  }

  int get horasDelMes {
    final nc = alumno.numeroControl;
    if (nc.isEmpty) return 0;
    final ahora = DateTime.now();
    var total = 0;
    for (final e in _asistencias.entries) {
      if (e.value[nc] != true) continue;
      final partes = e.key.split('|');
      final tallerId = int.tryParse(partes.first);
      final fecha = partes.length > 1 ? DateTime.tryParse(partes.last) : null;
      if (tallerId == null || fecha == null) continue;
      if (fecha.year != ahora.year || fecha.month != ahora.month) continue;
      final taller = _talleres.where((t) => t.id == tallerId).firstOrNull;
      if (taller != null) total += 1;
    }
    return total;
  }

  int get porcentajeAsistenciaInstructor {
    final ids = misGrupos.map((t) => t.id).toSet();
    var asistidas = 0;
    var total = 0;
    for (final e in _asistencias.entries) {
      final tallerId = int.tryParse(e.key.split('|').first);
      if (tallerId == null || !ids.contains(tallerId)) continue;
      for (final presente in e.value.values) {
        total++;
        if (presente) asistidas++;
      }
    }
    return total == 0 ? 0 : (asistidas * 100 / total).round();
  }

  List<Aviso> get avisosPublicados {
    final ids = misGrupos.map((t) => t.id).toSet();
    return _avisos
        .where((a) => a.tallerId != null && ids.contains(a.tallerId))
        .toList();
  }

  void publicarAviso({
    required int? tallerId,
    required TipoAviso tipo,
    required String titulo,
    required String mensaje,
  }) {
    final ahora = DateTime.now();
    final aviso = Aviso(
      id: _avisoSeq++,
      tallerId: tallerId,
      tipo: tipo,
      titulo: titulo.trim(),
      mensaje: mensaje.trim(),
      fecha: ahora,
    );
    _avisos.insert(0, aviso);
    _guardar((db) async {
      await db.from('avisos').insert({
        'taller_id': tallerId,
        'tipo': tipo.name,
        'titulo': aviso.titulo,
        'mensaje': aviso.mensaje,
        'fecha': ahora.toIso8601String(),
        'leido': false,
        'archivado': false,
      });
    });
    Notificaciones.mostrar(titulo: aviso.titulo, cuerpo: aviso.mensaje);
    notifyListeners();
  }

  Administrador admin = adminVacio;

  /// Pone como "persona actual" a la cuenta con la que se entró.
  /// Con null deja los perfiles vacíos (explorar sin cuenta).
  void usarCuenta(CuentaGuardada? c) {
    if (c != null && c.rol == Rol.alumno) {
      alumno = c.aAlumno();
    } else {
      alumno = alumnoVacio;
    }

    if (c != null && c.rol == Rol.instructor) {
      instructor = instructorPorId(c.id) ?? c.aInstructor();
    } else {
      instructor = instructorVacio;
    }

    if (c != null && c.rol == Rol.admin) {
      admin = Administrador(
        id: c.id,
        nombre: c.nombre,
        apellidoPaterno: c.apellidoPaterno,
        apellidoMaterno: c.apellidoMaterno,
        correo: c.correo,
        cargo: 'Coordinador',
      );
    } else {
      admin = adminVacio;
    }
    notifyListeners();
  }

  int _tallerSeq = 1;
  final Map<String, int> _horasOtros = {};
  final List<({String tipo, String formato, DateTime fecha})> _reportes = [];

  /// Todos los instructores viven en la tabla `usuarios` (rol instructor).
  List<Instructor> get instructores => List.unmodifiable(
    (_almacen?.instructores ?? const <CuentaGuardada>[]).map(
      (c) => c.aInstructor(),
    ),
  );

  /// Todos los alumnos viven en la tabla `usuarios` (rol alumno).
  List<Alumno> get todosAlumnos => List.unmodifiable(
    (_almacen?.alumnos ?? const <CuentaGuardada>[]).map((c) => c.aAlumno()),
  );

  List<({String tipo, String formato, DateTime fecha})> get reportes =>
      List.unmodifiable(_reportes);

  int horasAlumno(Alumno a) => a.numeroControl == alumno.numeroControl
      ? horasRealizadas
      : (_horasOtros[a.numeroControl] ?? 0);

  int get totalInscripciones => _talleres.fold(0, (a, t) => a + t.inscritos);
  int get totalCupos => _talleres
      .where((t) => t.activo)
      .fold(0, (a, t) => a + t.cuposDisponibles);
  int alumnosDeInstructor(int id) => _talleres
      .where((t) => t.instructor.id == id)
      .fold(0, (a, t) => a + t.inscritos);

  int get siguienteTallerId => _tallerSeq;

  /// Guarda el taller y sus horarios/aprendizajes. Devuelve el taller con el
  /// id real de Supabase, o null si no se pudo guardar.
  Future<Taller?> guardarTaller(Taller t) async {
    final esNuevo = !_talleres.any((x) => x.id == t.id);
    var guardado = t;
    try {
      final datos = <String, dynamic>{
        'nombre': t.nombre,
        'descripcion': t.descripcion,
        'categoria_id': t.categoria.id,
        'lugar': t.lugar,
        'cupo_maximo': t.cupoMaximo,
        'horas_otorga': t.horasOtorga,
        'activo': t.activo,
        'instructor_id': t.instructor.id,
        'inscritos': t.inscritos,
      };
      if (esNuevo) {
        final fila = await _db.from('talleres').insert(datos).select().single();
        guardado = t.copyWith(id: _aInt(fila['id'], defecto: t.id));
      } else {
        await _db.from('talleres').update(datos).eq('id', t.id);
      }

      await _db.from('horarios').delete().eq('taller_id', guardado.id);
      for (var k = 0; k < guardado.horarios.length; k++) {
        final h = guardado.horarios[k];
        await _db.from('horarios').insert({
          'taller_id': guardado.id,
          'dia': h.dia.index,
          'hora_inicio': h.horaInicio,
          'hora_fin': h.horaFin,
          'orden': k,
        });
      }
      await _db.from('aprendizajes').delete().eq('taller_id', guardado.id);
      for (var k = 0; k < guardado.aprendizajes.length; k++) {
        await _db.from('aprendizajes').insert({
          'taller_id': guardado.id,
          'texto': guardado.aprendizajes[k],
          'orden': k,
        });
      }
    } catch (e) {
      debugPrint('ACTIVA: no se pudo guardar el taller: $e');
      return null;
    }

    final idx = _talleres.indexWhere((x) => x.id == t.id);
    if (idx < 0) {
      _talleres.add(guardado);
    } else {
      _talleres[idx] = guardado;
    }
    if (guardado.id >= _tallerSeq) _tallerSeq = guardado.id + 1;
    for (var k = 0; k < _inscripciones.length; k++) {
      if (_inscripciones[k].taller.id == t.id) {
        _inscripciones[k] = _inscripciones[k].copyWith(taller: guardado);
      }
    }
    notifyListeners();
    return guardado;
  }

  String? conflictoHorario(Taller t) {
    for (final o in _talleres) {
      if (o.id == t.id || !o.activo) continue;
      final mismoLugar =
          o.lugar.trim().toLowerCase() == t.lugar.trim().toLowerCase();
      final mismoInstr = o.instructor.id == t.instructor.id;
      if (!mismoLugar && !mismoInstr) continue;
      for (final a in t.horarios) {
        for (final b in o.horarios) {
          if (a.traslapaCon(b)) {
            final cuando = '${a.dia.corto} de ${b.horaInicio} a ${b.horaFin}';
            return mismoInstr
                ? '${t.instructor.nombreCompleto} ya imparte ${o.nombre} el $cuando'
                : '${o.lugar} está ocupado por ${o.nombre} el $cuando';
          }
        }
      }
    }
    return null;
  }

  /// Activa o desactiva un taller. Devuelve el error o null.
  Future<String?> cambiarActivoTaller(int id, bool activo) async {
    final idx = _talleres.indexWhere((t) => t.id == id);
    if (idx < 0) return 'Error: no se encontró el taller';
    if (_talleres[idx].activo == activo) return null;
    try {
      await _db.from('talleres').update({'activo': activo}).eq('id', id);
    } catch (e) {
      debugPrint('ACTIVA: no se pudo cambiar el estado del taller: $e');
      return 'Error: no se pudo guardar el cambio';
    }
    final nuevo = _talleres[idx].copyWith(activo: activo);
    _talleres[idx] = nuevo;
    for (var k = 0; k < _inscripciones.length; k++) {
      if (_inscripciones[k].taller.id == id) {
        _inscripciones[k] = _inscripciones[k].copyWith(taller: nuevo);
      }
    }
    notifyListeners();
    return null;
  }

  /// Elimina un taller. Se niega si tiene alumnos inscritos activos.
  Future<String?> eliminarTaller(int id) async {
    final idx = _talleres.indexWhere((t) => t.id == id);
    if (idx < 0) return 'Error: no se encontró el taller';
    final activas = _inscripciones.where(
      (i) => i.taller.id == id && i.estado == EstadoInscripcion.activa,
    );
    if (activas.isNotEmpty) {
      return 'Error: tiene ${activas.length} alumno(s) inscrito(s). '
          'Mejor desactívalo.';
    }
    try {
      // los avisos usan SET NULL; los borramos para no dejar avisos huérfanos
      await _db.from('avisos').delete().eq('taller_id', id);
      await _db.from('talleres').delete().eq('id', id);
    } catch (e) {
      debugPrint('ACTIVA: no se pudo eliminar el taller: $e');
      return 'Error: no se pudo eliminar el taller';
    }
    final folios = _inscripciones
        .where((i) => i.taller.id == id)
        .map((i) => i.folio)
        .toList();
    _inscripciones.removeWhere((i) => i.taller.id == id);
    for (final f in folios) {
      _horas.remove(f);
    }
    final avisosIds = _avisos
        .where((a) => a.tallerId == id)
        .map((a) => a.id)
        .toSet();
    _avisos.removeWhere((a) => a.tallerId == id);
    _avisosLeidos.removeAll(avisosIds);
    _avisosArchivados.removeAll(avisosIds);
    _talleres.removeAt(idx);
    _favoritos.remove(id);
    _bajas.remove(id);
    _chats.remove(id);
    _chatsAnclados.remove(id);
    _fondosChat.remove(id);
    _roster.remove(id);
    _asistencias.removeWhere((k, _) => int.tryParse(k.split('|').first) == id);
    _encuestas.removeWhere((e) => e.tallerId == id);
    _solicitudes.removeWhere((s) => s.tallerId == id);
    notifyListeners();
    return null;
  }

  // ================= INSTRUCTORES: cuentas y asignaciones =================
  bool existeCorreoInstructor(String c) =>
      (_almacen?.instructores ?? const <CuentaGuardada>[]).any(
        (i) => i.correo.toLowerCase() == c.trim().toLowerCase(),
      );

  bool existeInstructor(String n, String p, String m) =>
      (_almacen?.instructores ?? const <CuentaGuardada>[]).any(
        (i) =>
            i.nombreCompleto.toLowerCase() == '$n $p $m'.trim().toLowerCase(),
      );

  bool tieneCuentaInstructor(int id) {
    final c = _almacen?.porId(id);
    return c != null && c.rol == Rol.instructor;
  }

  Instructor? instructorPorId(int id) {
    final c = _almacen?.porId(id);
    return c != null && c.rol == Rol.instructor ? c.aInstructor() : null;
  }

  List<Taller> talleresDeInstructor(int id) =>
      _talleres.where((t) => t.instructor.id == id).toList();

  /// Los talleres guardan una copia del instructor: hay que actualizarla
  /// en memoria (la relación real en la BD es `talleres.instructor_id`).
  void _reemplazarInstructorEnMemoria(Instructor n) {
    for (var i = 0; i < _talleres.length; i++) {
      if (_talleres[i].instructor.id == n.id) {
        _talleres[i] = _talleres[i].copyWith(instructor: n);
      }
    }
    if (instructor.id == n.id) instructor = n;
  }

  /// Da de alta al instructor con su cuenta de acceso. La contraseña se
  /// guarda con hash y queda como temporal (la tiene que cambiar al entrar).
  Future<({Instructor? instructor, String? error})> crearInstructor({
    required String nombre,
    required String paterno,
    String materno = '',
    required String correo,
    required String especialidad,
    required String contrasenaTemporal,
  }) async {
    final a = _almacen;
    if (a == null) {
      return (
        instructor: null,
        error: 'Error: no se pudo abrir el almacenamiento',
      );
    }
    final mail = correo.trim().toLowerCase();
    if (existeCorreoInstructor(mail) || a.correoTomado(mail)) {
      return (instructor: null, error: 'Error: ese correo ya está registrado');
    }
    if (existeInstructor(nombre, paterno, materno)) {
      return (
        instructor: null,
        error: 'Error: ya existe un instructor con ese nombre',
      );
    }
    final c = CuentaGuardada(
      id: a.nuevoId(),
      rol: Rol.instructor,
      usuario: a.usuarioLibre(CuentaGuardada.usuarioDesdeCorreo(mail)),
      correo: mail,
      nombre: nombre.trim(),
      apellidoPaterno: paterno.trim(),
      apellidoMaterno: materno.trim(),
      especialidad: especialidad.trim(),
    );
    a.ponerContrasena(c, contrasenaTemporal, temporal: true);
    final real = await a.agregar(c);
    if (real == null) {
      return (instructor: null, error: 'Error: no se pudo guardar la cuenta');
    }
    notifyListeners();
    return (instructor: real.aInstructor(), error: null);
  }

  /// Devuelve el texto del error, o null si todo salió bien.
  Future<String?> editarInstructor(
    int id, {
    required String nombre,
    required String paterno,
    String materno = '',
    required String correo,
    required String especialidad,
  }) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.instructor) {
      return 'Error: no se encontró al instructor';
    }
    final mail = correo.trim().toLowerCase();
    if (a.correoTomado(mail, excepto: id)) {
      return 'Error: ese correo ya está registrado';
    }
    c.nombre = nombre.trim();
    c.apellidoPaterno = paterno.trim();
    c.apellidoMaterno = materno.trim();
    c.correo = mail;
    c.especialidad = especialidad.trim();
    if (!await a.actualizar(c)) {
      return 'Error: no se pudieron guardar los cambios';
    }
    _reemplazarInstructorEnMemoria(c.aInstructor());
    notifyListeners();
    return null;
  }

  /// Activa o desactiva al instructor (desactivado no puede iniciar sesión).
  Future<String?> cambiarActivoInstructor(int id, bool activo) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.instructor) {
      return 'Error: no se encontró al instructor';
    }
    if (c.activo == activo) return null;
    c.activo = activo;
    if (!await a.actualizar(c)) {
      return 'Error: no se pudo guardar el cambio';
    }
    _reemplazarInstructorEnMemoria(c.aInstructor());
    notifyListeners();
    return null;
  }

  /// Elimina al instructor. Se niega si todavía tiene talleres asignados,
  /// para no dejar talleres sin instructor.
  Future<String?> eliminarInstructor(int id) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.instructor) {
      return 'Error: no se encontró al instructor';
    }
    final asignados = talleresDeInstructor(id);
    if (asignados.isNotEmpty) {
      final nombres = asignados.map((t) => t.nombre).join(', ');
      return 'Error: tiene talleres asignados ($nombres). Reasígnalos antes de eliminar.';
    }
    if (!await a.eliminar(c)) return 'Error: no se pudo eliminar al instructor';
    notifyListeners();
    return null;
  }

  /// Pone una contraseña temporal nueva (vuelve a pedir el cambio al entrar).
  Future<String?> restablecerContrasenaInstructor(
    int id,
    String temporal,
  ) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.instructor) {
      return 'Error: este instructor no tiene cuenta de acceso';
    }
    a.ponerContrasena(c, temporal, temporal: true);
    return await a.actualizar(c)
        ? null
        : 'Error: no se pudo guardar la contraseña';
  }

  /// Asigna el taller al instructor (el taller solo tiene un instructor, así
  /// que si lo tenía otro, se le quita). Devuelve el error o null.
  Future<String?> asignarTaller(int instructorId, int tallerId) async {
    final inst = instructorPorId(instructorId);
    if (inst == null) return 'Error: no se encontró al instructor';
    if (!inst.activo) return 'Error: el instructor está desactivado';
    final t = tallerPorId(tallerId);
    if (t.instructor.id == instructorId) return null;
    final nuevo = t.copyWith(instructor: inst);
    final choque = conflictoHorario(nuevo);
    if (choque != null) return 'Error: traslape de horario. $choque';
    final guardado = await guardarTaller(nuevo);
    if (guardado == null) {
      return 'Error: no se pudo guardar la asignación';
    }
    return null;
  }

  // ================= ALUMNOS: CRUD del administrador =================

  /// Da de alta a un alumno con su cuenta de acceso.
  Future<String?> crearAlumno({
    required String nombre,
    required String paterno,
    String materno = '',
    required String correo,
    required String numeroControl,
    required String grupo,
    required String carrera,
    required String contrasena,
    String telefono = '',
  }) async {
    final a = _almacen;
    if (a == null) return 'Error: no se pudo abrir el almacenamiento';
    final mail = correo.trim().toLowerCase();
    final control = numeroControl.trim();
    if (mail.isEmpty) return 'Error: el correo es obligatorio';
    if (control.isEmpty) return 'Error: el número de control es obligatorio';
    if (a.correoTomado(mail)) {
      return 'Error: ese correo ya está registrado';
    }
    if (a.controlTomado(control)) {
      return 'Error: ese número de control ya está registrado';
    }
    final c = CuentaGuardada(
      id: 0,
      rol: Rol.alumno,
      usuario: a.usuarioLibre(CuentaGuardada.usuarioDesdeCorreo(mail)),
      correo: mail,
      nombre: nombre.trim(),
      apellidoPaterno: paterno.trim(),
      apellidoMaterno: materno.trim(),
      telefono: telefono.trim(),
      numeroControl: control,
      grupo: grupo.trim().toUpperCase(),
      carrera: carrera.trim(),
    );
    a.ponerContrasena(c, contrasena);
    if (await a.agregar(c) == null) {
      return 'Error: no se pudo guardar la cuenta';
    }
    notifyListeners();
    return null;
  }

  /// Edita los datos de un alumno. Devuelve el error o null.
  Future<String?> editarAlumno(
    int id, {
    required String nombre,
    required String paterno,
    String materno = '',
    required String correo,
    required String numeroControl,
    required String grupo,
    required String carrera,
    String telefono = '',
  }) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.alumno) {
      return 'Error: no se encontró al alumno';
    }
    final mail = correo.trim().toLowerCase();
    final control = numeroControl.trim();
    if (a.correoTomado(mail, excepto: id)) {
      return 'Error: ese correo ya está registrado';
    }
    if (a.controlTomado(control, excepto: id)) {
      return 'Error: ese número de control ya está registrado';
    }
    final controlAntes = c.numeroControl;
    c.nombre = nombre.trim();
    c.apellidoPaterno = paterno.trim();
    c.apellidoMaterno = materno.trim();
    c.correo = mail;
    c.numeroControl = control;
    c.grupo = grupo.trim().toUpperCase();
    c.carrera = carrera.trim();
    c.telefono = telefono.trim();
    if (!await a.actualizar(c)) {
      return 'Error: no se pudieron guardar los cambios';
    }
    if (controlAntes.isNotEmpty && controlAntes != control) {
      _guardar((db) async {
        await db
            .from('asistencias')
            .update({'numero_control': control})
            .eq('numero_control', controlAntes);
        await db
            .from('encuestas')
            .update({'numero_control': control})
            .eq('numero_control', controlAntes);
      });
    }
    if (alumno.id == id) alumno = c.aAlumno();
    notifyListeners();
    return null;
  }

  /// Activa o desactiva a un alumno (desactivado no puede iniciar sesión).
  Future<String?> cambiarActivoAlumno(int id, bool activo) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.alumno) {
      return 'Error: no se encontró al alumno';
    }
    if (c.activo == activo) return null;
    c.activo = activo;
    if (!await a.actualizar(c)) {
      return 'Error: no se pudo guardar el cambio';
    }
    notifyListeners();
    return null;
  }

  /// Pone una contraseña temporal nueva al alumno.
  Future<String?> restablecerContrasenaAlumno(int id, String temporal) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.alumno) {
      return 'Error: no se encontró al alumno';
    }
    a.ponerContrasena(c, temporal, temporal: true);
    return await a.actualizar(c)
        ? null
        : 'Error: no se pudo guardar la contraseña';
  }

  /// Elimina al alumno y sus inscripciones, ajustando los cupos ocupados.
  Future<String?> eliminarAlumno(int id) async {
    final a = _almacen;
    final c = a?.porId(id);
    if (a == null || c == null || c.rol != Rol.alumno) {
      return 'Error: no se encontró al alumno';
    }
    final porTaller = <int, int>{};
    for (final i in _inscripciones) {
      if (i.alumno.id == id && i.estado == EstadoInscripcion.activa) {
        porTaller.update(i.taller.id, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    if (!await a.eliminar(c)) return 'Error: no se pudo eliminar al alumno';

    _inscripciones.removeWhere((i) => i.alumno.id == id);
    _horas.removeWhere((folio, _) {
      return !_inscripciones.any((i) => i.folio == folio);
    });
    for (final e in porTaller.entries) {
      final idx = _talleres.indexWhere((t) => t.id == e.key);
      if (idx < 0) continue;
      final nuevo = (_talleres[idx].inscritos - e.value)
          .clamp(0, 1 << 31)
          .toInt();
      _talleres[idx] = _talleres[idx].copyWith(inscritos: nuevo);
      _guardar(
        (db) =>
            db.from('talleres').update({'inscritos': nuevo}).eq('id', e.key),
      );
    }
    _guardar((db) => db.from('inscripciones').delete().eq('alumno_id', id));
    if (alumno.id == id) alumno = alumnoVacio;
    notifyListeners();
    return null;
  }

  void registrarReporte(String tipo, String formato) {
    final fecha = DateTime.now();
    _reportes.insert(0, (tipo: tipo, formato: formato, fecha: fecha));
    _guardar((db) async {
      await db.from('reportes').insert({
        'tipo': tipo,
        'formato': formato,
        'fecha': fecha.toIso8601String(),
      });
    });
    notifyListeners();
  }

  // ================= CHATS GRUPALES =================
  final Map<int, List<MensajeChat>> _chats = {};
  int _msgSeq = 1;

  List<MensajeChat> mensajesDe(int tallerId) =>
      List.unmodifiable(_chats[tallerId] ?? const []);

  MensajeChat? ultimoMensaje(int tallerId) {
    final l = _chats[tallerId];
    return (l == null || l.isEmpty) ? null : l.last;
  }

  List<Taller> chatsDe(Rol rol) => switch (rol) {
    Rol.alumno =>
      misInscripciones.map((i) => tallerPorId(i.taller.id)).toList(),
    Rol.instructor => misGrupos,
    Rol.admin => _talleres.where((t) => t.activo).toList(),
  };

  String nombreChat(Rol rol) => switch (rol) {
    Rol.alumno => alumno.nombreCompleto,
    Rol.instructor => instructor.nombreCompleto,
    Rol.admin => 'Coordinación',
  };

  // ================= CHATS: anclar y fondo =================
  final Set<int> _chatsAnclados = {};
  final Map<int, int> _fondosChat = {};

  bool chatAnclado(int id) => _chatsAnclados.contains(id);
  int fondoChat(int id) => _fondosChat[id] ?? 0;

  /// false si ya hay 3 anclados
  bool toggleAnclarChat(int id) {
    if (_chatsAnclados.contains(id)) {
      _chatsAnclados.remove(id);
    } else {
      if (_chatsAnclados.length >= 3) return false;
      _chatsAnclados.add(id);
    }
    _guardar(
      (db) => db.from('chats_estado').upsert({
        'taller_id': id,
        'anclado': _chatsAnclados.contains(id),
        'fondo': _fondosChat[id] ?? 0,
      }, onConflict: 'taller_id'),
    );
    notifyListeners();
    return true;
  }

  void ponerFondoChat(int id, int fondo) {
    _fondosChat[id] = fondo;
    _guardar(
      (db) => db.from('chats_estado').upsert({
        'taller_id': id,
        'anclado': _chatsAnclados.contains(id),
        'fondo': fondo,
      }, onConflict: 'taller_id'),
    );
    notifyListeners();
  }

  List<Taller> chatsOrdenados(Rol rol) {
    final l = chatsDe(rol);
    int t(Taller x) => ultimoMensaje(x.id)?.fecha.millisecondsSinceEpoch ?? 0;
    l.sort((a, b) {
      final pa = chatAnclado(a.id), pb = chatAnclado(b.id);
      if (pa != pb) return pa ? -1 : 1;
      return t(b).compareTo(t(a));
    });
    return l;
  }

  void enviarMensaje({
    required int tallerId,
    required Rol rol,
    required String texto,
  }) {
    final t = texto.trim();
    if (t.isEmpty) return;
    final ahora = DateTime.now();
    final autor = nombreChat(rol);
    final mensaje = MensajeChat(
      id: _msgSeq++,
      tallerId: tallerId,
      rol: rol,
      autor: autor,
      texto: t,
      fecha: ahora,
    );
    _chats.putIfAbsent(tallerId, () => []).add(mensaje);
    _guardar((db) async {
      await db.from('mensajes').insert({
        'taller_id': tallerId,
        'rol': rol.name,
        'autor': autor,
        'texto': t,
        'fecha': ahora.toIso8601String(),
      });
    });
    notifyListeners();
  }

  // ================= ENCUESTAS =================
  final List<RespuestaEncuesta> _encuestas = [];
  int _encSeq = 1;

  List<RespuestaEncuesta> get encuestas => List.unmodifiable(_encuestas);

  bool encuestaContestada(int tallerId) => _encuestas.any(
    (e) => e.tallerId == tallerId && e.numeroControl == alumno.numeroControl,
  );

  void enviarEncuesta({
    required int tallerId,
    required int club,
    required int instructorCalif,
    String comentario = '',
  }) {
    if (encuestaContestada(tallerId)) return;
    final ahora = DateTime.now();
    final encuesta = RespuestaEncuesta(
      id: _encSeq++,
      tallerId: tallerId,
      numeroControl: alumno.numeroControl,
      califClub: club,
      califInstructor: instructorCalif,
      comentario: comentario.trim(),
      fecha: ahora,
    );
    _encuestas.insert(0, encuesta);
    _guardar((db) async {
      await db.from('encuestas').insert({
        'taller_id': tallerId,
        'numero_control': alumno.numeroControl,
        'calif_club': club,
        'calif_instructor': instructorCalif,
        'comentario': comentario.trim(),
        'fecha': ahora.toIso8601String(),
      });
    });
    notifyListeners();
  }

  int respuestasDeClub(int tallerId) =>
      _encuestas.where((e) => e.tallerId == tallerId).length;

  double? promedioClub(int tallerId) {
    final l = _encuestas.where((e) => e.tallerId == tallerId).toList();
    if (l.isEmpty) return null;
    return l.fold<int>(0, (a, e) => a + e.califClub) / l.length;
  }

  List<RespuestaEncuesta> _encuestasDeInstructor(int instructorId) {
    final ids = _talleres
        .where((t) => t.instructor.id == instructorId)
        .map((t) => t.id)
        .toSet();
    return _encuestas.where((e) => ids.contains(e.tallerId)).toList();
  }

  int respuestasDeInstructor(int instructorId) =>
      _encuestasDeInstructor(instructorId).length;

  double? promedioInstructor(int instructorId) {
    final l = _encuestasDeInstructor(instructorId);
    if (l.isEmpty) return null;
    return l.fold<int>(0, (a, e) => a + e.califInstructor) / l.length;
  }

  double? get promedioGeneralClubes {
    if (_encuestas.isEmpty) return null;
    return _encuestas.fold<int>(0, (a, e) => a + e.califClub) /
        _encuestas.length;
  }

  // ================= SOLICITUDES AL ADMIN =================
  final List<SolicitudAdmin> _solicitudes = [];
  int _solSeq = 1;

  List<SolicitudAdmin> get solicitudes => List.unmodifiable(_solicitudes);

  List<SolicitudAdmin> get solicitudesDelInstructor =>
      _solicitudes.where((s) => s.instructorId == instructor.id).toList();

  int get solicitudesPendientes =>
      _solicitudes.where((s) => s.estado == EstadoSolicitud.pendiente).length;

  void atenderSolicitud(int id) {
    final i = _solicitudes.indexWhere((s) => s.id == id);
    if (i < 0) return;
    _solicitudes[i] = _solicitudes[i].copyWith(
      estado: EstadoSolicitud.atendida,
    );
    _guardar((db) async {
      await db
          .from('solicitudes')
          .update({'estado': EstadoSolicitud.atendida.name})
          .eq('id', id);
    });
    notifyListeners();
  }

  int bajasDe(int tallerId) => _bajas[tallerId] ?? 0;

  bool haySolicitudPendiente(int tallerId, TipoSolicitud tipo) =>
      _solicitudes.any(
        (s) =>
            s.tallerId == tallerId &&
            s.tipo == tipo &&
            s.estado == EstadoSolicitud.pendiente,
      );

  /// false si ya existe una igual pendiente
  bool enviarSolicitud({
    required Taller taller,
    required TipoSolicitud tipo,
    String mensaje = '',
  }) {
    if (haySolicitudPendiente(taller.id, tipo)) return false;
    final solicitud = SolicitudAdmin(
      id: _solSeq++,
      tallerId: taller.id,
      instructorId: instructor.id,
      instructorNombre: instructor.nombreCompleto,
      tipo: tipo,
      mensaje: mensaje.trim(),
      fecha: DateTime.now(),
    );
    _solicitudes.insert(0, solicitud);
    _guardar(
      (db) => db.from('solicitudes').insert({
        'id': solicitud.id,
        'taller_id': solicitud.tallerId,
        'instructor_id': solicitud.instructorId,
        'instructor_nombre': solicitud.instructorNombre,
        'tipo': solicitud.tipo.name,
        'mensaje': solicitud.mensaje,
        'fecha': solicitud.fecha.toIso8601String(),
        'estado': solicitud.estado.name,
        'respuesta': solicitud.respuesta,
        'cupo_extra': solicitud.cupoExtra,
      }),
    );
    notifyListeners();
    return true;
  }

  void cancelarSolicitud(int id) {
    _solicitudes.removeWhere(
      (s) => s.id == id && s.estado == EstadoSolicitud.pendiente,
    );
    _guardar((db) => db.from('solicitudes').delete().eq('id', id));
    notifyListeners();
  }

  Future<void> responderSolicitud(
    int id, {
    required bool aprobar,
    String respuesta = '',
    int cupoExtra = 0,
  }) async {
    final i = _solicitudes.indexWhere((s) => s.id == id);
    if (i < 0) return;
    final sol = _solicitudes[i];
    if (aprobar && cupoExtra > 0) {
      final t = tallerPorId(sol.tallerId);
      await guardarTaller(t.copyWith(cupoMaximo: t.cupoMaximo + cupoExtra));
    }
    _solicitudes[i] = sol.copyWith(
      estado: aprobar ? EstadoSolicitud.atendida : EstadoSolicitud.rechazada,
      respuesta: respuesta.trim(),
      cupoExtra: aprobar ? cupoExtra : 0,
    );
    _guardar(
      (db) => db
          .from('solicitudes')
          .update({
            'estado': _solicitudes[i].estado.name,
            'respuesta': _solicitudes[i].respuesta,
            'cupo_extra': _solicitudes[i].cupoExtra,
          })
          .eq('id', id),
    );
    notifyListeners();
  }

  int listasRegistradasDe(int instructorId) {
    final ids = _talleres
        .where((t) => t.instructor.id == instructorId)
        .map((t) => t.id)
        .toSet();
    return _asistencias.keys
        .where((k) => ids.contains(int.tryParse(k.split('|').first)))
        .length;
  }

  // ================= AVISOS: leídos / archivados =================
  final Set<int> _avisosLeidos = {};
  final Set<int> _avisosArchivados = {};
  int _avisoSeq = 1;

  bool avisoLeido(int id) => _avisosLeidos.contains(id);
  List<Aviso> get avisosVisibles =>
      _avisos.where((a) => !_avisosArchivados.contains(a.id)).toList();
  List<Aviso> get avisosArchivados =>
      _avisos.where((a) => _avisosArchivados.contains(a.id)).toList();

  int get avisosSinLeer =>
      avisosVisibles.where((a) => !_avisosLeidos.contains(a.id)).length;

  void marcarAviso(int id, {bool leido = true}) {
    leido ? _avisosLeidos.add(id) : _avisosLeidos.remove(id);
    _guardar((db) => db.from('avisos').update({'leido': leido}).eq('id', id));
    notifyListeners();
  }

  void marcarTodosLeidos() {
    final ids = avisosVisibles
        .where((a) => !_avisosLeidos.contains(a.id))
        .map((a) => a.id)
        .toList();
    _avisosLeidos.addAll(ids);
    _guardar((db) async {
      for (final id in ids) {
        await db.from('avisos').update({'leido': true}).eq('id', id);
      }
    });
    notifyListeners();
  }

  void archivarAviso(int id, {bool archivar = true}) {
    archivar ? _avisosArchivados.add(id) : _avisosArchivados.remove(id);
    _guardar(
      (db) => db.from('avisos').update({'archivado': archivar}).eq('id', id),
    );
    notifyListeners();
  }

  Aviso? eliminarAviso(int id) {
    final i = _avisos.indexWhere((a) => a.id == id);
    if (i < 0) return null;
    final a = _avisos.removeAt(i);
    _guardar((db) => db.from('avisos').delete().eq('id', id));
    notifyListeners();
    return a;
  }

  void restaurarAviso(Aviso a) {
    _avisos.add(a);
    _avisos.sort((x, y) => y.fecha.compareTo(x.fecha));
    _guardar(
      (db) => db.from('avisos').upsert({
        'id': a.id,
        'taller_id': a.tallerId,
        'tipo': a.tipo.name,
        'titulo': a.titulo,
        'mensaje': a.mensaje,
        'fecha': a.fecha.toIso8601String(),
        'leido': _avisosLeidos.contains(a.id),
        'archivado': _avisosArchivados.contains(a.id),
      }),
    );
    notifyListeners();
  }
}
