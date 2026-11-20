// ===================================================================
// datos_prueba.dart
// Genera una base SQLite con datos de prueba realistas para ACTIVA:
// instructores, alumnos, talleres, inscripciones, asistencias, avisos,
// chats, encuestas y solicitudes.
//
// No toca la base limpia de la app. Por defecto crea:
//   Activa-main/activa_datos_prueba.sqlite
//
// Uso:
//   flutter test tool/datos_prueba.dart
//
// Para escribir en otra ruta (por ejemplo, la base que usa la app en
// Linux), cierra la app y ejecuta:
//   ACTIVA_DB="$HOME/Documentos/activa.db" flutter test tool/datos_prueba.dart
//
// Todas las cuentas usan la contraseña: Activa2026!
// ===================================================================

import 'dart:io';
import 'dart:math';

import 'package:activa/datos/almacen_cuentas.dart';
import 'package:activa/datos/bd/base_datos.dart';
import 'package:activa/datos/bd/repositorio_activa.dart';
import 'package:activa/datos/bd/seguridad.dart';
import 'package:activa/datos/catalogo.dart';
import 'package:activa/modelos/comunicacion.dart';
import 'package:activa/modelos/enums.dart';
import 'package:activa/modelos/inscripcion.dart';
import 'package:activa/modelos/taller.dart';
import 'package:activa/modelos/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _contrasena = 'Activa2026!';

// -------------------------------------------------------------------
// Personas de prueba
// -------------------------------------------------------------------
class _InstructorSeed {
  const _InstructorSeed({
    required this.id,
    required this.nombre,
    required this.paterno,
    required this.materno,
    required this.usuario,
    required this.correo,
    required this.especialidad,
  });

  final int id;
  final String nombre;
  final String paterno;
  final String materno;
  final String usuario;
  final String correo;
  final String especialidad;
}

class _AlumnoSeed {
  const _AlumnoSeed({
    required this.id,
    required this.nombre,
    required this.paterno,
    required this.materno,
    required this.usuario,
    required this.correo,
    required this.control,
    required this.grupo,
    required this.carrera,
  });

  final int id;
  final String nombre;
  final String paterno;
  final String materno;
  final String usuario;
  final String correo;
  final String control;
  final String grupo;
  final String carrera;
}

const _instructores = <_InstructorSeed>[
  _InstructorSeed(
    id: 2,
    nombre: 'Ana',
    paterno: 'López',
    materno: 'García',
    usuario: 'ana_lopez',
    correo: 'ana.lopez@utng.edu.mx',
    especialidad: 'Voleibol',
  ),
  _InstructorSeed(
    id: 3,
    nombre: 'Carlos',
    paterno: 'Ruiz',
    materno: 'Medina',
    usuario: 'carlos_ruiz',
    correo: 'carlos.ruiz@utng.edu.mx',
    especialidad: 'Básquetbol',
  ),
  _InstructorSeed(
    id: 4,
    nombre: 'Lucía',
    paterno: 'Méndez',
    materno: 'Ríos',
    usuario: 'lucia_mendez',
    correo: 'lucia.mendez@utng.edu.mx',
    especialidad: 'Danza folclórica',
  ),
  _InstructorSeed(
    id: 5,
    nombre: 'Jorge',
    paterno: 'Salas',
    materno: 'Torres',
    usuario: 'jorge_salas',
    correo: 'jorge.salas@utng.edu.mx',
    especialidad: 'Guitarra',
  ),
  _InstructorSeed(
    id: 6,
    nombre: 'Paola',
    paterno: 'Ortiz',
    materno: 'Vega',
    usuario: 'paola_ortiz',
    correo: 'paola.ortiz@utng.edu.mx',
    especialidad: 'Ajedrez',
  ),
  _InstructorSeed(
    id: 7,
    nombre: 'Héctor',
    paterno: 'Navarro',
    materno: 'Luna',
    usuario: 'hector_navarro',
    correo: 'hector.navarro@utng.edu.mx',
    especialidad: 'Robótica',
  ),
];

const _alumnos = <_AlumnoSeed>[
  _AlumnoSeed(
    id: 8,
    nombre: 'Mariana',
    paterno: 'Torres',
    materno: 'Salinas',
    usuario: 'mariana_torres',
    correo: 'mariana.torres@utng.edu.mx',
    control: '20260001',
    grupo: 'GTID235',
    carrera: 'Desarrollo de Software Multiplataforma',
  ),
  _AlumnoSeed(
    id: 9,
    nombre: 'Diego',
    paterno: 'Ramírez',
    materno: 'Flores',
    usuario: 'diego_ramirez',
    correo: 'diego.ramirez@utng.edu.mx',
    control: '20260002',
    grupo: 'GTID235',
    carrera: 'Desarrollo de Software Multiplataforma',
  ),
  _AlumnoSeed(
    id: 10,
    nombre: 'Sofía',
    paterno: 'Hernández',
    materno: 'Cruz',
    usuario: 'sofia_hernandez',
    correo: 'sofia.hernandez@utng.edu.mx',
    control: '20260003',
    grupo: 'GTID236',
    carrera: 'Mecatrónica Industrial',
  ),
  _AlumnoSeed(
    id: 11,
    nombre: 'Luis',
    paterno: 'García',
    materno: 'Ponce',
    usuario: 'luis_garcia',
    correo: 'luis.garcia@utng.edu.mx',
    control: '20260004',
    grupo: 'GTID236',
    carrera: 'Mecatrónica Industrial',
  ),
  _AlumnoSeed(
    id: 12,
    nombre: 'Valeria',
    paterno: 'Martínez',
    materno: 'Rojas',
    usuario: 'valeria_martinez',
    correo: 'valeria.martinez@utng.edu.mx',
    control: '20260005',
    grupo: 'GTID237',
    carrera: 'Administración',
  ),
  _AlumnoSeed(
    id: 13,
    nombre: 'Emilio',
    paterno: 'López',
    materno: 'Santos',
    usuario: 'emilio_lopez',
    correo: 'emilio.lopez@utng.edu.mx',
    control: '20260006',
    grupo: 'GTID237',
    carrera: 'Administración',
  ),
  _AlumnoSeed(
    id: 14,
    nombre: 'Fernanda',
    paterno: 'Díaz',
    materno: 'Núñez',
    usuario: 'fernanda_diaz',
    correo: 'fernanda.diaz@utng.edu.mx',
    control: '20260007',
    grupo: 'GTID238',
    carrera: 'Contaduría',
  ),
  _AlumnoSeed(
    id: 15,
    nombre: 'Santiago',
    paterno: 'Morales',
    materno: 'Peña',
    usuario: 'santiago_morales',
    correo: 'santiago.morales@utng.edu.mx',
    control: '20260008',
    grupo: 'GTID238',
    carrera: 'Contaduría',
  ),
  _AlumnoSeed(
    id: 16,
    nombre: 'Camila',
    paterno: 'Jiménez',
    materno: 'Soto',
    usuario: 'camila_jimenez',
    correo: 'camila.jimenez@utng.edu.mx',
    control: '20260009',
    grupo: 'GTID239',
    carrera: 'Desarrollo de Software Multiplataforma',
  ),
  _AlumnoSeed(
    id: 17,
    nombre: 'Andrés',
    paterno: 'Castillo',
    materno: 'Vega',
    usuario: 'andres_castillo',
    correo: 'andres.castillo@utng.edu.mx',
    control: '20260010',
    grupo: 'GTID239',
    carrera: 'Desarrollo de Software Multiplataforma',
  ),
  _AlumnoSeed(
    id: 18,
    nombre: 'Renata',
    paterno: 'Vargas',
    materno: 'León',
    usuario: 'renata_vargas',
    correo: 'renata.vargas@utng.edu.mx',
    control: '20260011',
    grupo: 'GTID240',
    carrera: 'Mecatrónica Industrial',
  ),
  _AlumnoSeed(
    id: 19,
    nombre: 'Iván',
    paterno: 'Romero',
    materno: 'Aguilar',
    usuario: 'ivan_romero',
    correo: 'ivan.romero@utng.edu.mx',
    control: '20260012',
    grupo: 'GTID240',
    carrera: 'Mecatrónica Industrial',
  ),
];

/// alumno = índice en [_alumnos], taller = id del taller.
const _planInscripciones = <({int alumno, int taller, bool cancelada})>[
  // Voleibol
  (alumno: 0, taller: 1, cancelada: false),
  (alumno: 1, taller: 1, cancelada: false),
  (alumno: 2, taller: 1, cancelada: false),
  (alumno: 3, taller: 1, cancelada: false),
  (alumno: 4, taller: 1, cancelada: false),
  (alumno: 5, taller: 1, cancelada: false),
  // Básquetbol
  (alumno: 1, taller: 2, cancelada: false),
  (alumno: 2, taller: 2, cancelada: false),
  (alumno: 6, taller: 2, cancelada: false),
  (alumno: 7, taller: 2, cancelada: false),
  (alumno: 8, taller: 2, cancelada: false),
  // Danza folclórica
  (alumno: 0, taller: 3, cancelada: false),
  (alumno: 3, taller: 3, cancelada: false),
  (alumno: 5, taller: 3, cancelada: false),
  (alumno: 9, taller: 3, cancelada: false),
  (alumno: 10, taller: 3, cancelada: false),
  (alumno: 11, taller: 3, cancelada: false),
  // Guitarra (cupo lleno)
  (alumno: 4, taller: 4, cancelada: false),
  (alumno: 6, taller: 4, cancelada: false),
  (alumno: 8, taller: 4, cancelada: false),
  (alumno: 9, taller: 4, cancelada: false),
  // Ajedrez
  (alumno: 1, taller: 5, cancelada: false),
  (alumno: 7, taller: 5, cancelada: false),
  (alumno: 10, taller: 5, cancelada: false),
  // Robótica
  (alumno: 2, taller: 6, cancelada: false),
  (alumno: 4, taller: 6, cancelada: false),
  (alumno: 11, taller: 6, cancelada: false),
  (alumno: 0, taller: 6, cancelada: true),
];

void main() {
  test('genera la base con datos de prueba', () async {
    sqfliteFfiInit();

    final rutaEnv = Platform.environment['ACTIVA_DB']?.trim();
    final destino = (rutaEnv == null || rutaEnv.isEmpty)
        ? File('activa_datos_prueba.sqlite').absolute.path
        : File(rutaEnv).absolute.path;
    final archivo = File(destino);
    if (archivo.existsSync()) archivo.deleteSync();

    final bd = BaseDatos.pruebas(databaseFactoryFfi, destino);
    final repo = RepositorioActiva(await bd.abrir());

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // =========================================================
    // 1. Cuentas de acceso (admin + instructores + alumnos)
    // =========================================================
    final cuentasBase = await repo.cargarCuentas();
    final admin = cuentasBase.firstWhere((c) => c.rol == Rol.admin);

    final cuentas = <CuentaGuardada>[admin];
    final instructores = <Instructor>[];

    for (final s in _instructores) {
      final c = CuentaGuardada(
        id: s.id,
        rol: Rol.instructor,
        usuario: s.usuario,
        correo: s.correo,
        nombre: s.nombre,
        apellidoPaterno: s.paterno,
        apellidoMaterno: s.materno,
        telefono: '473 100 000${s.id}',
        especialidad: s.especialidad,
      );
      c.sal = generarSal();
      c.hash = hashContrasena(c.sal, _contrasena);
      cuentas.add(c);
      instructores.add(c.aInstructor());
    }

    final alumnos = <Alumno>[];
    for (final s in _alumnos) {
      final c = CuentaGuardada(
        id: s.id,
        rol: Rol.alumno,
        usuario: s.usuario,
        correo: s.correo,
        nombre: s.nombre,
        apellidoPaterno: s.paterno,
        apellidoMaterno: s.materno,
        telefono: '473 200 000${s.id - 7}',
        numeroControl: s.control,
        grupo: s.grupo,
        carrera: s.carrera,
      );
      c.sal = generarSal();
      c.hash = hashContrasena(c.sal, _contrasena);
      cuentas.add(c);
      alumnos.add(c.aAlumno());
    }

    await repo.guardarCuentas(cuentas, siguienteId: 20);

    // =========================================================
    // 2. Talleres
    // =========================================================
    final categorias = {for (final c in categoriasIniciales) c.clave: c};

    final inscritosPorTaller = <int, int>{};
    for (final p in _planInscripciones) {
      if (p.cancelada) continue;
      inscritosPorTaller.update(p.taller, (v) => v + 1, ifAbsent: () => 1);
    }

    final talleres = <Taller>[
      Taller(
        id: 1,
        nombre: 'Voleibol',
        descripcion: 'Entrenamiento y torneos internos de voleibol.',
        categoria: categorias['deportes']!,
        lugar: 'Gimnasio',
        cupoMaximo: 8,
        instructor: instructores[0],
        horarios: const [
          Horario(Dia.lunes, '17:00', '18:30'),
          Horario(Dia.miercoles, '17:00', '18:30'),
        ],
        aprendizajes: const [
          'Trabajo en equipo',
          'Técnica de remate y recepción',
          'Disciplina y condición física',
        ],
        inscritos: inscritosPorTaller[1] ?? 0,
      ),
      Taller(
        id: 2,
        nombre: 'Básquetbol',
        descripcion: 'Fundamentos, táctica y partidos recreativos.',
        categoria: categorias['deportes']!,
        lugar: 'Cancha de básquetbol',
        cupoMaximo: 15,
        instructor: instructores[1],
        horarios: const [
          Horario(Dia.martes, '16:00', '17:30'),
          Horario(Dia.jueves, '16:00', '17:30'),
        ],
        aprendizajes: const [
          'Fundamentos del bote y tiro',
          'Juego en equipo',
          'Acondicionamiento físico',
        ],
        inscritos: inscritosPorTaller[2] ?? 0,
      ),
      Taller(
        id: 3,
        nombre: 'Danza folclórica',
        descripcion: 'Montaje de bailes tradicionales para eventos UTNG.',
        categoria: categorias['cultura']!,
        lugar: 'Sala de usos múltiples',
        cupoMaximo: 25,
        instructor: instructores[2],
        horarios: const [
          Horario(Dia.martes, '18:00', '19:30'),
          Horario(Dia.jueves, '18:00', '19:30'),
        ],
        aprendizajes: const [
          'Ritmo y coordinación',
          'Tradiciones mexicanas',
          'Expresión escénica',
        ],
        inscritos: inscritosPorTaller[3] ?? 0,
      ),
      Taller(
        id: 4,
        nombre: 'Guitarra',
        descripcion: 'Iniciación a la guitarra acústica y ensamble musical.',
        categoria: categorias['cultura']!,
        lugar: 'Aula B-12',
        cupoMaximo: 4,
        instructor: instructores[3],
        horarios: const [
          Horario(Dia.lunes, '15:00', '16:30'),
          Horario(Dia.jueves, '15:00', '16:30'),
        ],
        aprendizajes: const [
          'Acordes básicos',
          'Lectura de tablatura',
          'Ensamble grupal',
        ],
        inscritos: inscritosPorTaller[4] ?? 0,
      ),
      Taller(
        id: 5,
        nombre: 'Ajedrez',
        descripcion: 'Estrategia, aperturas y torneos rápidos.',
        categoria: categorias['recreativa']!,
        lugar: 'Biblioteca',
        cupoMaximo: 16,
        instructor: instructores[4],
        horarios: const [Horario(Dia.miercoles, '15:00', '16:30')],
        aprendizajes: const [
          'Aperturas y finales',
          'Cálculo de variantes',
          'Concentración y paciencia',
        ],
        inscritos: inscritosPorTaller[5] ?? 0,
      ),
      Taller(
        id: 6,
        nombre: 'Robótica',
        descripcion: 'Armado de prototipos con Arduino y sensores.',
        categoria: categorias['otros']!,
        lugar: 'Laboratorio de cómputo',
        cupoMaximo: 18,
        instructor: instructores[5],
        horarios: const [Horario(Dia.viernes, '15:00', '17:00')],
        aprendizajes: const [
          'Electrónica básica',
          'Programación de Arduino',
          'Trabajo en equipo',
        ],
        inscritos: inscritosPorTaller[6] ?? 0,
      ),
    ];

    for (final t in talleres) {
      await repo.guardarTaller(t);
    }

    // =========================================================
    // 3. Inscripciones
    // =========================================================
    final inscripciones = <Inscripcion>[];
    var folioSeq = 1;

    for (var i = 0; i < _planInscripciones.length; i++) {
      final p = _planInscripciones[i];
      final taller = talleres[p.taller - 1];
      final alumno = alumnos[p.alumno];
      final prefijo = _prefijo(taller.nombre);
      final folio =
          '$prefijo-${ahora.year}-${folioSeq.toString().padLeft(4, '0')}';
      folioSeq++;

      final ins = Inscripcion(
        folio: folio,
        alumno: alumno,
        taller: taller,
        estado: p.cancelada
            ? EstadoInscripcion.cancelada
            : EstadoInscripcion.activa,
        fechaInscripcion: hoy.subtract(Duration(days: 75 - i)),
      );
      inscripciones.add(ins);
      await repo.guardarInscripcion(ins);
    }

    // =========================================================
    // 4. Asistencias (últimas 8 sesiones de cada taller)
    // =========================================================
    final alumnosPorTaller = <int, List<Inscripcion>>{};
    for (final ins in inscripciones) {
      if (ins.estado != EstadoInscripcion.activa) continue;
      alumnosPorTaller.putIfAbsent(ins.taller.id, () => []).add(ins);
    }

    final horasPorFolio = <String, int>{};

    for (final taller in talleres) {
      for (final fecha in _sesionesDe(taller, hoy)) {
        final marcas = <String, bool>{};
        for (final ins
            in alumnosPorTaller[taller.id] ?? const <Inscripcion>[]) {
          final r = Random(
            taller.id * 100000 +
                ins.alumno.id * 1000 +
                fecha.month * 31 +
                fecha.day,
          );
          final presente = r.nextInt(100) < 88;
          marcas[ins.alumno.numeroControl] = presente;
          if (presente) {
            horasPorFolio.update(
              ins.folio,
              (v) => v + taller.horasPorSesion,
              ifAbsent: () => taller.horasPorSesion,
            );
          }
        }
        await repo.guardarAsistencia(taller.id, _iso(fecha), marcas);
      }
    }

    for (final e in horasPorFolio.entries) {
      await repo.guardarHorasFolio(e.key, min(e.value, 60));
    }

    final totalesPorAlumno = <String, int>{};
    for (final ins in inscripciones) {
      totalesPorAlumno.update(
        ins.alumno.numeroControl,
        (v) => v + (horasPorFolio[ins.folio] ?? 0),
        ifAbsent: () => horasPorFolio[ins.folio] ?? 0,
      );
    }
    for (final e in totalesPorAlumno.entries) {
      await repo.guardarHorasAlumno(e.key, min(e.value, 60));
    }

    // =========================================================
    // 5. Avisos
    // =========================================================
    final avisos = <Aviso>[
      Aviso(
        id: 1,
        tipo: TipoAviso.informativo,
        titulo: 'Bienvenida al cuatrimestre',
        mensaje:
            'Ya están abiertas las inscripciones a los talleres paraescolares. '
            'Recuerda que la meta es de 60 horas por cuatrimestre.',
        fecha: hoy
            .subtract(const Duration(days: 14))
            .add(const Duration(hours: 9)),
      ),
      Aviso(
        id: 2,
        tallerId: 1,
        tipo: TipoAviso.cambioHorario,
        titulo: 'Cambio de horario: Voleibol',
        mensaje:
            'A partir de esta semana el entrenamiento del miércoles '
            'empieza a las 17:30 en el gimnasio.',
        fecha: hoy
            .subtract(const Duration(days: 6))
            .add(const Duration(hours: 12)),
      ),
      Aviso(
        id: 3,
        tallerId: 3,
        tipo: TipoAviso.recordatorio,
        titulo: 'Ensayo general de Danza',
        mensaje:
            'El ensayo general será el jueves en la sala de usos múltiples. '
            'Llevar el vestuario completo.',
        fecha: hoy
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 17)),
      ),
      Aviso(
        id: 4,
        tallerId: 6,
        tipo: TipoAviso.informativo,
        titulo: 'Material para Robótica',
        mensaje:
            'Traer laptop y cables el viernes. El laboratorio abre desde '
            'las 14:30 para quien necesite instalar el software.',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 10)),
      ),
      Aviso(
        id: 5,
        tipo: TipoAviso.cancelacion,
        titulo: 'Suspensión de actividades',
        mensaje:
            'El viernes no habrá actividades paraescolares por '
            'mantenimiento del campus.',
        fecha: hoy
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 8)),
      ),
    ];

    for (var i = 0; i < avisos.length; i++) {
      await repo.guardarAviso(
        avisos[i],
        leido: i < 2,
        archivado: avisos[i].id == 5,
      );
    }

    // =========================================================
    // 6. Chats grupales
    // =========================================================
    final mensajes = <MensajeChat>[
      MensajeChat(
        id: 1,
        tallerId: 1,
        rol: Rol.instructor,
        autor: instructores[0].nombreCompleto,
        texto:
            'Bienvenidos al taller de voleibol. El primer entrenamiento '
            'es el lunes a las 17:00.',
        fecha: hoy
            .subtract(const Duration(days: 10))
            .add(const Duration(hours: 9)),
      ),
      MensajeChat(
        id: 2,
        tallerId: 1,
        rol: Rol.alumno,
        autor: alumnos[0].nombreCompleto,
        texto: '¡Gracias profe! ¿Hay que llevar tenis blancos?',
        fecha: hoy
            .subtract(const Duration(days: 10))
            .add(const Duration(hours: 11)),
      ),
      MensajeChat(
        id: 3,
        tallerId: 1,
        rol: Rol.instructor,
        autor: instructores[0].nombreCompleto,
        texto: 'Sí, tenis y ropa deportiva. Nos vemos en el gimnasio.',
        fecha: hoy
            .subtract(const Duration(days: 9))
            .add(const Duration(hours: 8)),
      ),
      MensajeChat(
        id: 4,
        tallerId: 2,
        rol: Rol.instructor,
        autor: instructores[1].nombreCompleto,
        texto: 'Recuerden traer su balón si tienen uno propio.',
        fecha: hoy
            .subtract(const Duration(days: 8))
            .add(const Duration(hours: 15)),
      ),
      MensajeChat(
        id: 5,
        tallerId: 2,
        rol: Rol.alumno,
        autor: alumnos[1].nombreCompleto,
        texto: 'Profe, ¿la práctica del jueves es en la cancha techada?',
        fecha: hoy
            .subtract(const Duration(days: 8))
            .add(const Duration(hours: 16)),
      ),
      MensajeChat(
        id: 6,
        tallerId: 2,
        rol: Rol.instructor,
        autor: instructores[1].nombreCompleto,
        texto: 'Sí, en la cancha techada. Lleguen 10 minutos antes.',
        fecha: hoy
            .subtract(const Duration(days: 7))
            .add(const Duration(hours: 9)),
      ),
      MensajeChat(
        id: 7,
        tallerId: 3,
        rol: Rol.instructor,
        autor: instructores[2].nombreCompleto,
        texto: 'El ensayo de esta semana es el jueves a las 18:00.',
        fecha: hoy
            .subtract(const Duration(days: 5))
            .add(const Duration(hours: 13)),
      ),
      MensajeChat(
        id: 8,
        tallerId: 3,
        rol: Rol.alumno,
        autor: alumnos[3].nombreCompleto,
        texto: '¿Llevamos el vestuario nuevo?',
        fecha: hoy
            .subtract(const Duration(days: 5))
            .add(const Duration(hours: 14)),
      ),
      MensajeChat(
        id: 9,
        tallerId: 6,
        rol: Rol.instructor,
        autor: instructores[5].nombreCompleto,
        texto: 'El viernes armamos los equipos de robótica.',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 11)),
      ),
      MensajeChat(
        id: 10,
        tallerId: 6,
        rol: Rol.alumno,
        autor: alumnos[2].nombreCompleto,
        texto: '¿Puedo llevar mi Arduino?',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 12)),
      ),
      MensajeChat(
        id: 11,
        tallerId: 6,
        rol: Rol.instructor,
        autor: instructores[5].nombreCompleto,
        texto: 'Claro, trae tus componentes y cables.',
        fecha: hoy
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 9)),
      ),
    ];

    for (final m in mensajes) {
      await repo.guardarMensaje(m);
    }

    await repo.guardarEstadoChat(1, anclado: true, fondo: 1);
    await repo.guardarEstadoChat(2, fondo: 2);

    // =========================================================
    // 7. Encuestas
    // =========================================================
    final encuestas = <RespuestaEncuesta>[
      RespuestaEncuesta(
        id: 1,
        tallerId: 1,
        numeroControl: alumnos[0].numeroControl,
        califClub: 5,
        califInstructor: 5,
        comentario: 'Muy buen ambiente y el profe explica con paciencia.',
        fecha: hoy
            .subtract(const Duration(days: 4))
            .add(const Duration(hours: 18)),
      ),
      RespuestaEncuesta(
        id: 2,
        tallerId: 1,
        numeroControl: alumnos[1].numeroControl,
        califClub: 4,
        califInstructor: 5,
        comentario: 'Me gustaría que hubiera más partidos.',
        fecha: hoy
            .subtract(const Duration(days: 4))
            .add(const Duration(hours: 19)),
      ),
      RespuestaEncuesta(
        id: 3,
        tallerId: 1,
        numeroControl: alumnos[2].numeroControl,
        califClub: 5,
        califInstructor: 4,
        comentario: '',
        fecha: hoy
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 10)),
      ),
      RespuestaEncuesta(
        id: 4,
        tallerId: 1,
        numeroControl: alumnos[3].numeroControl,
        califClub: 4,
        califInstructor: 4,
        comentario: 'Buen entrenamiento.',
        fecha: hoy
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 11)),
      ),
      RespuestaEncuesta(
        id: 5,
        tallerId: 2,
        numeroControl: alumnos[1].numeroControl,
        califClub: 5,
        califInstructor: 5,
        comentario: 'Las prácticas son dinámicas.',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 17)),
      ),
      RespuestaEncuesta(
        id: 6,
        tallerId: 2,
        numeroControl: alumnos[6].numeroControl,
        califClub: 4,
        califInstructor: 5,
        comentario: '',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 18)),
      ),
      RespuestaEncuesta(
        id: 7,
        tallerId: 3,
        numeroControl: alumnos[0].numeroControl,
        califClub: 5,
        califInstructor: 5,
        comentario: 'El montaje quedó increíble.',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 19)),
      ),
      RespuestaEncuesta(
        id: 8,
        tallerId: 3,
        numeroControl: alumnos[3].numeroControl,
        califClub: 5,
        califInstructor: 4,
        comentario: '',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 20)),
      ),
      RespuestaEncuesta(
        id: 9,
        tallerId: 3,
        numeroControl: alumnos[5].numeroControl,
        califClub: 4,
        califInstructor: 5,
        comentario: 'Muy divertido.',
        fecha: hoy
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 15)),
      ),
      RespuestaEncuesta(
        id: 10,
        tallerId: 4,
        numeroControl: alumnos[4].numeroControl,
        califClub: 5,
        califInstructor: 5,
        comentario: 'Aprendí mucho en poco tiempo.',
        fecha: hoy
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 16)),
      ),
      RespuestaEncuesta(
        id: 11,
        tallerId: 6,
        numeroControl: alumnos[2].numeroControl,
        califClub: 5,
        califInstructor: 5,
        comentario: 'El laboratorio está muy bien equipado.',
        fecha: hoy.subtract(const Duration(hours: 20)),
      ),
    ];

    for (final e in encuestas) {
      await repo.guardarEncuesta(e);
    }

    // =========================================================
    // 8. Solicitudes al administrador
    // =========================================================
    final solicitudes = <SolicitudAdmin>[
      SolicitudAdmin(
        id: 1,
        tallerId: 6,
        instructorId: instructores[5].id,
        instructorNombre: instructores[5].nombreCompleto,
        tipo: TipoSolicitud.ampliarCupo,
        mensaje:
            'El laboratorio tiene espacio para 3 alumnos más. '
            '¿Podemos ampliar el cupo?',
        fecha: hoy
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 12)),
      ),
      SolicitudAdmin(
        id: 2,
        tallerId: 4,
        instructorId: instructores[3].id,
        instructorNombre: instructores[3].nombreCompleto,
        tipo: TipoSolicitud.clubLleno,
        mensaje: 'El taller se llenó y hay 2 alumnos en lista de espera.',
        fecha: hoy
            .subtract(const Duration(days: 8))
            .add(const Duration(hours: 10)),
        estado: EstadoSolicitud.atendida,
        respuesta: 'Se amplió el cupo a 4 lugares.',
        cupoExtra: 1,
      ),
    ];

    for (final s in solicitudes) {
      await repo.guardarSolicitud(s);
    }

    // =========================================================
    // 9. Favoritos, bajas y reportes
    // =========================================================
    await repo.guardarFavorito(2, true);
    await repo.guardarFavorito(3, true);
    await repo.guardarFavorito(5, true);

    await repo.guardarBaja(6, 1);

    await repo.guardarReporte(
      'Inscripciones por taller',
      'PDF',
      hoy.subtract(const Duration(days: 7)),
    );
    await repo.guardarReporte(
      'Asistencia general',
      'Excel',
      hoy.subtract(const Duration(days: 2)),
    );

    // =========================================================
    // 10. Contadores (para que los altas nuevas sigan la secuencia)
    // =========================================================
    final contadores = <String, int>{
      'folio': inscripciones.length + 1,
      'taller': talleres.length + 1,
      'instructor': _instructores.last.id + 1,
      'aviso': avisos.length + 1,
      'mensaje': mensajes.length + 1,
      'encuesta': encuestas.length + 1,
      'solicitud': solicitudes.length + 1,
      'usuario': _alumnos.last.id + 1,
    };
    for (final e in contadores.entries) {
      await repo.guardarContador(e.key, e.value);
    }

    // =========================================================
    // 11. Verificación
    // =========================================================
    final datos = await repo.cargarTodo();
    expect(datos.categorias.length, 4);
    expect(datos.instructores.length, _instructores.length);
    expect(datos.alumnos.length, _alumnos.length);
    expect(datos.talleres.length, talleres.length);
    expect(datos.inscripciones.length, _planInscripciones.length);
    expect(datos.avisos.length, avisos.length);
    expect(datos.encuestas.length, encuestas.length);
    expect(datos.solicitudes.length, solicitudes.length);
    expect(datos.favoritos.length, 3);
    expect(datos.bajas[6], 1);
    expect(datos.reportes.length, 2);
    expect(
      datos.chats.values.fold<int>(0, (a, l) => a + l.length),
      mensajes.length,
    );
    expect(datos.contadores['usuario'], _alumnos.last.id + 1);
    expect(datos.talleres.firstWhere((t) => t.id == 4).hayCupo, isFalse);

    final cuentasFinales = await repo.cargarCuentas();
    expect(cuentasFinales.length, cuentas.length);
    for (final c in cuentasFinales) {
      expect(
        contrasenaCorrecta(c.sal, c.hash, _contrasena),
        isTrue,
        reason: 'La contraseña de ${c.usuario} no coincide',
      );
    }

    final asistencias = await repo.cargarAsistencias();
    final totalMarcas = asistencias.values.fold<int>(0, (a, m) => a + m.length);

    await bd.cerrar();

    // =========================================================
    // 12. Resumen
    // =========================================================
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('Datos de prueba creados en: $destino');
    // ignore: avoid_print
    print(
      'Talleres: ${talleres.length} · '
      'Inscripciones: ${inscripciones.length} · '
      'Marcas de asistencia: $totalMarcas · '
      'Mensajes: ${mensajes.length}',
    );
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('Cuentas (contraseña: $_contrasena)');
    // ignore: avoid_print
    print('  Admin:       admin');
    // ignore: avoid_print
    print('  Instructores: ${_instructores.map((i) => i.usuario).join(', ')}');
    // ignore: avoid_print
    print('  Alumnos:      ${_alumnos.map((a) => a.usuario).join(', ')}');
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('Para usarla en la app de Linux (con la app cerrada):');
    // ignore: avoid_print
    print('  cp "$destino" "\$HOME/Documentos/activa.db"');
    // ignore: avoid_print
    print('');
  }, timeout: const Timeout(Duration(minutes: 2)));
}

// -------------------------------------------------------------------
// Utilidades
// -------------------------------------------------------------------

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _prefijo(String nombre) {
  const acentos = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n'};
  final limpio = nombre
      .toLowerCase()
      .split('')
      .map((c) => acentos[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z]'), '');
  return limpio.substring(0, 3).toUpperCase();
}

/// Últimas 8 fechas en las que el taller tiene sesión (sin contar hoy).
List<DateTime> _sesionesDe(Taller t, DateTime hoy) {
  final dias = t.horarios.map((h) => h.dia.weekday).toSet();
  final encontradas = <DateTime>[];
  for (var i = 1; i <= 90 && encontradas.length < 8; i++) {
    final d = hoy.subtract(Duration(days: i));
    if (dias.contains(d.weekday)) encontradas.add(d);
  }
  return encontradas.reversed.toList();
}
