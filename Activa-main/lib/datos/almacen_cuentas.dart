import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/enums.dart';
import '../modelos/usuario.dart';
import 'bd/seguridad.dart';

class CuentaGuardada {
  CuentaGuardada({
    required this.id,
    required this.rol,
    required this.usuario,
    required this.correo,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno = '',
    this.telefono = '',
    this.especialidad = '',
    this.numeroControl = '',
    this.grupo = '',
    this.carrera = '',
    List<int>? tallerIds,
    this.activo = true,
    this.debeCambiarContrasena = false,
    this.sal = '',
    this.hash = '',
  }) : tallerIds = tallerIds ?? [];

  final int id;
  final Rol rol;
  String usuario;
  String correo;
  String nombre;
  String apellidoPaterno;
  String apellidoMaterno;
  String telefono;
  // instructor
  String especialidad;
  List<int> tallerIds;
  // alumno
  String numeroControl;
  String grupo;
  String carrera;
  // acceso
  bool activo;
  bool debeCambiarContrasena;
  String sal;
  String hash;

  Alumno aAlumno() => Alumno(
    id: id,
    nombre: nombre,
    apellidoPaterno: apellidoPaterno,
    apellidoMaterno: apellidoMaterno,
    correo: correo,
    telefono: telefono.isEmpty ? null : telefono,
    numeroControl: numeroControl,
    grupo: grupo,
    carrera: carrera,
  );

  Instructor aInstructor() => Instructor(
    id: id,
    nombre: nombre,
    apellidoPaterno: apellidoPaterno,
    apellidoMaterno: apellidoMaterno,
    correo: correo,
    telefono: telefono.isEmpty ? null : telefono,
    especialidad: especialidad,
    activo: activo,
  );

  static String usuarioDesdeCorreo(String correo) {
    var u = correo
        .split('@')
        .first
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    if (!RegExp(r'^[a-z]').hasMatch(u)) u = 'inst_$u';
    if (u.length > 20) u = u.substring(0, 20);
    if (u.length < 4) u = u.padRight(4, '0');
    return u;
  }

  static Rol _rolDesdeTexto(Object? valor) {
    final texto = (valor ?? '').toString().toLowerCase();
    for (final r in Rol.values) {
      if (r.name == texto) return r;
    }
    return Rol.alumno;
  }

  static bool _aBool(Object? valor, {bool porDefecto = false}) {
    if (valor is bool) return valor;
    if (valor is num) return valor != 0;
    if (valor is String) {
      final v = valor.toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return porDefecto;
  }

  factory CuentaGuardada.desdeMapa(Map<String, dynamic> m) {
    return CuentaGuardada(
      id: (m['id'] as num?)?.toInt() ?? 0,
      rol: _rolDesdeTexto(m['rol']),
      usuario: (m['usuario'] ?? '').toString(),
      correo: (m['correo'] ?? '').toString(),
      nombre: (m['nombre'] ?? '').toString(),
      apellidoPaterno: (m['apellido_paterno'] ?? '').toString(),
      apellidoMaterno: (m['apellido_materno'] ?? '').toString(),
      telefono: (m['telefono'] ?? '').toString(),
      especialidad: (m['especialidad'] ?? '').toString(),
      numeroControl: (m['numero_control'] ?? '').toString(),
      grupo: (m['grupo'] ?? '').toString(),
      carrera: (m['carrera'] ?? '').toString(),
      activo: _aBool(m['activo'], porDefecto: true),
      debeCambiarContrasena: _aBool(m['debe_cambiar_contrasena']),
      sal: (m['sal'] ?? '').toString(),
      hash: (m['hash'] ?? '').toString(),
    );
  }

  Map<String, dynamic> aMapaSupabase({bool incluirId = true}) {
    final mapa = <String, dynamic>{
      'rol': rol.name,
      'usuario': usuario.trim().toLowerCase(),
      'correo': correo.trim().toLowerCase(),
      'nombre': nombre.trim(),
      'apellido_paterno': apellidoPaterno.trim(),
      'apellido_materno': apellidoMaterno.trim(),
      'telefono': telefono.trim(),
      'especialidad': especialidad.trim(),
      'numero_control': numeroControl.trim(),
      'grupo': grupo.trim(),
      'carrera': carrera.trim(),
      'activo': activo,
      'debe_cambiar_contrasena': debeCambiarContrasena,
      'sal': sal,
      'hash': hash,
    };
    if (incluirId && id > 0) {
      mapa['id'] = id;
    }
    return mapa;
  }
}

class AlmacenCuentas {
  AlmacenCuentas._(this._cuentas, this._siguienteId, this._db);

  final List<CuentaGuardada> _cuentas;
  final SupabaseClient _db;
  int _siguienteId;
  Future<bool> _cola = Future.value(true);

  static Future<AlmacenCuentas> cargar() async {
    final db = Supabase.instance.client;
    try {
      final filas = await db
          .from('usuarios')
          .select()
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 8));
      final lista = List<Map<String, dynamic>>.from(filas).map(CuentaGuardada.desdeMapa).toList();
      final maxId = lista.fold<int>(0, (a, c) => c.id > a ? c.id : a);
      return AlmacenCuentas._(lista, maxId + 1, db);
    } catch (e) {
      debugPrint('No se pudieron leer las cuentas desde Supabase: $e');
      return AlmacenCuentas._([], 1, db);
    }
  }

  /// Sincroniza la lista en memoria hacia Supabase.
  Future<bool> guardar() {
    _cola = _cola.then((_) async {
      try {
        for (final c in _cuentas) {
          await _db
              .from('usuarios')
              .upsert(
                c.aMapaSupabase(incluirId: c.id > 0),
                onConflict: 'usuario',
              );
        }
        return true;
      } catch (e) {
        debugPrint('No se pudieron guardar las cuentas en Supabase: $e');
        return false;
      }
    });
    return _cola;
  }

  List<CuentaGuardada> get cuentas => List.unmodifiable(_cuentas);
  List<CuentaGuardada> get instructores =>
      _cuentas.where((c) => c.rol == Rol.instructor).toList();
  List<CuentaGuardada> get alumnos =>
      _cuentas.where((c) => c.rol == Rol.alumno).toList();

  int nuevoId() => _siguienteId++;

  CuentaGuardada? porId(int id) {
    for (final c in _cuentas) {
      if (c.id == id) return c;
    }
    return null;
  }

  CuentaGuardada? buscarAcceso(String texto) {
    final u = texto.trim().toLowerCase();
    if (u.isEmpty) return null;
    for (final c in _cuentas) {
      if (c.usuario == u ||
          c.correo.toLowerCase() == u ||
          (c.rol == Rol.alumno && c.numeroControl == u)) {
        return c;
      }
    }
    return null;
  }

  bool correoTomado(String correo, {int? excepto}) => _cuentas.any(
    (c) =>
        c.id != excepto &&
        c.correo.toLowerCase() == correo.trim().toLowerCase(),
  );

  bool controlTomado(String control, {int? excepto}) => _cuentas.any(
    (c) =>
        c.id != excepto &&
        c.rol == Rol.alumno &&
        c.numeroControl == control.trim(),
  );

  bool usuarioTomado(String usuario, {int? excepto}) => _cuentas.any(
    (c) => c.id != excepto && c.usuario == usuario.trim().toLowerCase(),
  );

  String usuarioLibre(String base) {
    var u = base;
    var n = 2;
    while (usuarioTomado(u)) {
      final sufijo = '$n';
      final corte = base.length + sufijo.length > 20
          ? 20 - sufijo.length
          : base.length;
      u = '${base.substring(0, corte)}$sufijo';
      n++;
    }
    return u;
  }

  Future<bool> agregar(CuentaGuardada c) async {
    try {
      final insertada = await _db
          .from('usuarios')
          .insert(c.aMapaSupabase(incluirId: false))
          .select()
          .single();
      final cuentaReal = CuentaGuardada.desdeMapa(insertada);
      _cuentas.add(cuentaReal);
      if (cuentaReal.id >= _siguienteId) {
        _siguienteId = cuentaReal.id + 1;
      }
      return true;
    } catch (e) {
      debugPrint('Error al registrar cuenta en Supabase: $e');
      return false;
    }
  }

  void ponerContrasena(
    CuentaGuardada c,
    String contrasena, {
    bool temporal = false,
  }) {
    c.sal = generarSal();
    c.hash = hashContrasena(c.sal, contrasena);
    c.debeCambiarContrasena = temporal;
  }

  bool verificar(CuentaGuardada c, String contrasena) =>
      contrasenaCorrecta(c.sal, c.hash, contrasena);

  static String generarTemporal() {
    const mayus = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const minus = 'abcdefghijkmnpqrstuvwxyz';
    const nums = '23456789';
    const esp = '@#!%*?';
    final r = Random.secure();
    String uno(String s) => s[r.nextInt(s.length)];
    final chars = [
      uno(mayus),
      uno(mayus),
      uno(nums),
      uno(nums),
      uno(esp),
      for (var i = 0; i < 5; i++) uno(minus),
    ]..shuffle(r);
    return chars.join();
  }
}
