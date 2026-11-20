import 'package:activa/datos/almacen_cuentas.dart';
import 'package:activa/datos/bd/base_datos.dart';
import 'package:activa/datos/bd/repositorio_activa.dart';
import 'package:activa/datos/bd/seguridad.dart';
import 'package:activa/modelos/enums.dart';
import 'package:activa/modelos/inscripcion.dart';
import 'package:activa/modelos/taller.dart';
import 'package:activa/modelos/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('la base arranca limpia y guarda datos nuevos', () async {
    final bd = BaseDatos.pruebas(databaseFactoryFfi, inMemoryDatabasePath);
    final repo = RepositorioActiva(await bd.abrir());

    // ---- la base solo trae catálogo y administrador ----
    final datos = await repo.cargarTodo();
    expect(datos.categorias.length, 4);
    expect(datos.talleres, isEmpty);
    expect(datos.instructores, isEmpty);
    expect(datos.alumnos, isEmpty);
    expect(datos.inscripciones, isEmpty);
    expect(datos.avisos, isEmpty);
    expect(datos.chats, isEmpty);
    expect(datos.encuestas, isEmpty);
    expect(datos.solicitudes, isEmpty);
    expect(datos.contadores['folio'], 1);
    expect(datos.contadores['usuario'], 2);

    final cuentas = await repo.cargarCuentas();
    expect(cuentas.length, 1);
    final admin = cuentas.first;
    expect(admin.rol, Rol.admin);
    expect(admin.usuario, 'admin');
    expect(contrasenaCorrecta(admin.sal, admin.hash, 'Activa2026!'), isTrue);

    // ---- el administrador da de alta un instructor ----
    const instructor = Instructor(
      id: 2,
      nombre: 'Ana',
      apellidoPaterno: 'López',
      correo: 'ana@utng.edu.mx',
      especialidad: 'Voleibol',
    );
    await repo.guardarInstructor(instructor);

    final categoria = datos.categorias.first;
    final taller = Taller(
      id: 1,
      nombre: 'Voleibol',
      descripcion: 'Taller de prueba',
      categoria: categoria,
      lugar: 'Gimnasio',
      cupoMaximo: 20,
      inscritos: 1,
      instructor: instructor,
      horarios: const [Horario(Dia.lunes, '17:00', '18:30')],
      aprendizajes: const ['Trabajo en equipo'],
    );
    await repo.guardarTaller(taller);

    // ---- un alumno se registra ----
    final alumno = CuentaGuardada(
      id: 2,
      rol: Rol.alumno,
      usuario: 'alumno_prueba',
      correo: 'alumno@utng.edu.mx',
      nombre: 'Alumno',
      apellidoPaterno: 'Prueba',
      numeroControl: '999900001',
      grupo: 'GTID235',
      carrera: 'IDGS',
    );
    alumno.sal = generarSal();
    alumno.hash = hashContrasena(alumno.sal, 'Activa2026!');
    await repo.guardarCuentas([admin, alumno], siguienteId: 3);

    final alumnoGuardado = alumno.aAlumno();
    final inscripcion = Inscripcion(
      folio: 'VOL-2026-0001',
      alumno: alumnoGuardado,
      taller: taller,
      fechaInscripcion: DateTime(2026, 11, 19),
    );
    await repo.guardarInscripcion(inscripcion);
    await repo.guardarHorasFolio(inscripcion.folio, 4);

    // ---- todo sigue ahí al volver a leer ----
    final datos2 = await repo.cargarTodo();
    expect(datos2.instructores.length, 1);
    expect(datos2.talleres.length, 1);
    expect(datos2.talleres.first.horarios.length, 1);
    expect(datos2.alumnos.length, 1);
    expect(datos2.inscripciones.length, 1);
    expect(datos2.horasPorFolio['VOL-2026-0001'], 4);
    expect(datos2.alumnos.first.numeroControl, '999900001');

    final cuentas2 = await repo.cargarCuentas();
    expect(cuentas2.length, 2);
    expect(cuentas2.any((c) => c.usuario == 'alumno_prueba'), isTrue);
    expect(await repo.siguienteIdUsuario(), 3);

    await bd.reiniciar();
  });
}
