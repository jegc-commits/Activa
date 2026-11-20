// ===================================================================
// almacen_cuentas.dart
// Guarda las cuentas (alumnos registrados e instructores creados por el
// admin) en la base de datos SQLite de ACTIVA. Las contraseñas NO se
// guardan en texto: solo la sal y el hash (SHA-256).
//
// Este archivo conserva la misma API que usaban las pantallas, así que
// el login y el registro siguen funcionando sin cambios.
// ===================================================================

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../modelos/enums.dart';
import '../modelos/usuario.dart';
import 'bd/base_datos.dart';
import 'bd/repositorio_activa.dart';
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
  List<int> tallerIds; // talleres que el admin le asignó
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

  /// "profe.lopez@utng.edu.mx" -> "profe_lopez" (válido para validarUsuario)
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
}

class AlmacenCuentas {
  AlmacenCuentas._(this._cuentas, this._siguienteId, this._repo);

  final List<CuentaGuardada> _cuentas;
  final RepositorioActiva _repo;
  int _siguienteId;
  Future<bool> _cola = Future.value(true); // escrituras una tras otra

  // ------------------------------------------------ carga / guardado
  static Future<AlmacenCuentas> cargar() async {
    try {
      final db = await BaseDatos.instancia.abrir();
      final repo = RepositorioActiva(db);
      final lista = await repo.cargarCuentas();
      final maxId = lista.fold<int>(0, (a, c) => c.id > a ? c.id : a);
      final guardado = await repo.siguienteIdUsuario();
      return AlmacenCuentas._(
        lista,
        [guardado, maxId + 1, 1000].reduce((a, b) => a > b ? a : b),
        repo,
      );
    } catch (e) {
      debugPrint('No se pudieron leer las cuentas guardadas: $e');
      return AlmacenCuentas._(
        [],
        1000,
        RepositorioActiva(await BaseDatos.instancia.abrir()),
      );
    }
  }

  /// Escribe todas las cuentas (y sus perfiles) en SQLite.
  /// Devuelve false si no se pudo guardar.
  Future<bool> guardar() {
    _cola = _cola.then((_) async {
      try {
        await _repo.guardarCuentas(_cuentas, siguienteId: _siguienteId);
        return true;
      } catch (e) {
        debugPrint('No se pudieron guardar las cuentas: $e');
        return false;
      }
    });
    return _cola;
  }

  // ------------------------------------------------ consultas
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

  /// Busca por usuario, correo o número de control (solo alumnos).
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

  /// Si "base" ya existe, le agrega un número (profe, profe2, profe3...)
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

  // ------------------------------------------------ altas
  Future<bool> agregar(CuentaGuardada c) async {
    _cuentas.add(c);
    final ok = await guardar();
    if (!ok) _cuentas.remove(c);
    return ok;
  }

  // ------------------------------------------------ contraseñas

  /// Guarda la contraseña (ya con hash). [temporal] = true obliga a
  /// cambiarla en el siguiente inicio de sesión.
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

  /// Contraseña temporal de 10 caracteres que cumple las reglas de la app
  /// (mayúscula, número y carácter especial). Sin letras ambiguas (O, 0, l, 1).
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
