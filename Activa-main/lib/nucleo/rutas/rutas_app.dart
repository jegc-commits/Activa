import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../datos/sesion.dart';
import '../../modelos/enums.dart';
import '../../modulos/autenticacion/pantallas/pantalla_cambiar_contrasena.dart';
import '../../modulos/autenticacion/pantallas/pantalla_carga.dart';
import '../../modulos/alumno/pantallas/pantallas_ayuda.dart';
import '../../modulos/autenticacion/pantallas/pantalla_olvide_contrasena.dart';
import '../../modulos/autenticacion/pantallas/pantalla_inicio_sesion.dart';
import '../../modulos/autenticacion/pantallas/pantalla_contrasena_actualizada.dart';
import '../../modulos/autenticacion/pantallas/pantalla_registro.dart';
import '../../modulos/autenticacion/pantallas/pantalla_bienvenida.dart';
import '../../modulos/alumno/pantallas/pantalla_detalle_taller.dart';
import '../../modulos/alumno/pantallas/pantalla_inscripcion_exitosa.dart';
import '../../modulos/alumno/pantallas/pantalla_explorar.dart';
import '../../modulos/alumno/pantallas/pantalla_inicio_alumno.dart';
import '../../modulos/alumno/pantallas/pantalla_mis_talleres.dart';
import '../../modulos/alumno/pantallas/pantalla_avisos.dart';
import '../../modulos/alumno/pantallas/pantallas_perfil.dart';
import '../../modulos/alumno/pantallas/estructura_alumno.dart';
import '../../modulos/perfil/pantalla_editar_foto.dart';
import '../../modulos/perfil/pantalla_editar_perfil.dart';
import '../../modulos/instructor/pantallas/pantalla_historial_asistencia.dart';
import '../../modulos/administrador/pantallas/pantallas_admin_extra.dart';
import '../../modulos/instructor/pantallas/pantallas_asistencia.dart';
import '../../modulos/instructor/pantallas/pantallas_grupos.dart';
import '../../modulos/instructor/pantallas/pantalla_inicio_instructor.dart';
import '../../modulos/instructor/pantallas/pantalla_perfil_instructor.dart';
import '../../modulos/instructor/pantallas/estructura_instructor.dart';
import '../../modulos/instructor/pantallas/pantallas_avisos_instructor.dart';
import '../../modulos/administrador/pantallas/pantallas_talleres_admin.dart';
import '../../modulos/administrador/pantallas/pantalla_inicio_admin.dart';
import '../../modulos/administrador/pantallas/pantallas_personas_admin.dart';
import '../../modulos/administrador/pantallas/pantallas_reportes_perfil_admin.dart';
import '../../modulos/administrador/pantallas/estructura_admin.dart';
import '../../modulos/chat/pantallas_chat.dart';
import '../../modulos/alumno/pantallas/pantallas_encuestas.dart';
import '../../modulos/instructor/pantallas/pantalla_solicitudes_instructor.dart';
import '../../modulos/administrador/pantallas/pantalla_solicitudes_admin.dart';
import '../../modulos/alumno/pantallas/pantalla_acerca_de.dart';
import '../../modulos/administrador/pantallas/pantallas_instructores_admin.dart';

// 👇 AQUÍ ESTÁ LA VARIABLE QUE TU APLICACION ESTÁ BUSCANDO
/// Sesión activa, para que el enrutador pueda bloquear las rutas /admin
/// cuando quien entró no es administrador.
EstadoSesion? sesionActiva;

final enrutadorApp = GoRouter(
  initialLocation: '/carga',
  redirect: (_, state) {
    final sesion = sesionActiva;
    final esAdmin = state.matchedLocation.startsWith('/admin');
    if (!esAdmin) return null;
    if (sesion?.rol == Rol.admin) return null;
    return switch (sesion?.rol) {
      Rol.alumno => '/alumno',
      Rol.instructor => '/instructor',
      _ => '/inicio-sesion',
    };
  },
  routes: [
    // Ruta raíz
    GoRoute(path: '/', redirect: (_, _) => '/carga'),

    // Rutas de autenticación
    GoRoute(
      path: '/cambiar-contrasena',
      builder: (_, _) => const PantallaCambiarContrasena(),
    ),
    GoRoute(path: '/carga', builder: (_, _) => const PantallaCarga()),
    GoRoute(path: '/bienvenida', builder: (_, _) => const PantallaBienvenida()),
    GoRoute(
      path: '/inicio-sesion',
      builder: (_, _) => const PantallaInicioSesion(),
    ),
    GoRoute(path: '/registro', builder: (_, _) => const PantallaRegistro()),
    GoRoute(
      path: '/olvide-contrasena',
      builder: (_, _) => const PantallaOlvideContrasena(),
    ),
    GoRoute(
      path: '/contrasena-actualizada',
      builder: (_, _) => const PantallaContrasenaActualizada(),
    ),

    // Chats y encuestas
    GoRoute(path: '/chats', builder: (_, _) => const PantallaListaChats()),
    GoRoute(
      path: '/chat/:id',
      builder: (_, s) =>
          PantallaChatGrupal(tallerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/encuestas',
      builder: (_, _) => const PantallaEncuestasAlumno(),
    ),
    GoRoute(
      path: '/encuesta/:id',
      builder: (_, s) =>
          PantallaEncuesta(tallerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/instructor/solicitudes',
      builder: (_, _) => const PantallaSolicitudesInstructor(),
    ),
    GoRoute(
      path: '/admin/solicitudes',
      builder: (_, _) => const PantallaSolicitudesAdmin(),
    ),

    // ==========================================
    // ALUMNO: 5 PESTAÑAS
    // ==========================================
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => EstructuraAlumno(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alumno',
              builder: (_, _) => const PantallaInicioAlumno(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alumno/explorar',
              builder: (_, s) =>
                  PantallaExplorar(initialCat: s.uri.queryParameters['cat']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alumno/actividades', // Ruta real de Mis Talleres
              builder: (_, _) => const PantallaMisTalleres(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alumno/avisos',
              builder: (_, _) => const PantallaAvisos(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alumno/perfil',
              builder: (_, _) => const PantallaPerfil(),
            ),
          ],
        ),
      ],
    ),

    // ==========================================
    // RUTAS INDEPENDIENTES (PANTALLAS COMPLETAS)
    // ==========================================
    GoRoute(
      path: '/taller/:id',
      builder: (_, s) =>
          PantallaDetalleTaller(tallerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/inscripcion/:folio',
      builder: (_, s) =>
          PantallaInscripcionExitosa(folio: s.pathParameters['folio']!),
    ),
    GoRoute(
      path: '/perfil/academico',
      builder: (_, _) => const PantallaDatosAcademicos(),
    ),
    GoRoute(
      path: '/perfil/comprobantes',
      builder: (_, _) => const PantallaComprobantes(),
    ),
    GoRoute(
      path: '/perfil/progreso',
      builder: (_, _) => const PantallaProgreso(),
    ),
    GoRoute(
      path: '/perfil/favoritos',
      builder: (_, _) => const PantallaFavoritos(),
    ),
    GoRoute(path: '/perfil/idioma', builder: (_, _) => const PantallaIdioma()),
    GoRoute(
      path: '/perfil/privacidad',
      builder: (_, _) => const PantallaAvisoPrivacidad(),
    ),
    GoRoute(path: '/perfil/ayuda', builder: (_, _) => const PantallaAyuda()),
    GoRoute(
      path: '/perfil/editar',
      builder: (_, _) => const PantallaEditarPerfilGeneral(),
    ),
    GoRoute(
      path: '/perfil/configuracion',
      builder: (_, _) => const PantallaConfiguracion(),
    ),
    // Única ruta de foto
    GoRoute(
      path: '/perfil/foto',
      builder: (_, s) =>
          PantallaEditarFoto(fuente: s.uri.queryParameters['fuente']),
    ),
    GoRoute(
      path: '/perfil/acerca',
      builder: (_, _) => const PantallaAcercaDe(),
    ),

    // ==========================================
    // INSTRUCTOR: 5 PESTAÑAS
    // ==========================================
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => EstructuraInstructor(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/instructor',
              builder: (_, _) => const PantallaInicioInstructor(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/instructor/grupos',
              builder: (_, _) => const PantallaGrupos(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/instructor/asistencia',
              builder: (_, _) => const PantallaAsistenciaPestana(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/instructor/avisos',
              builder: (_, _) => const PantallaAvisosInstructor(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/instructor/perfil',
              builder: (_, _) => const PantallaPerfilInstructor(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/instructor/grupo/:id',
      builder: (_, s) =>
          PantallaAlumnosGrupo(tallerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/instructor/pasar-lista/:id',
      builder: (_, s) => PantallaPasarLista(
        tallerId: int.parse(s.pathParameters['id']!),
        fecha: DateTime.parse(s.uri.queryParameters['fecha']!),
      ),
    ),
    GoRoute(
      path: '/instructor/nuevo-aviso',
      builder: (_, _) => const PantallaNuevoAviso(),
    ),
    GoRoute(
      path: '/instructor/historial',
      builder: (_, _) => const PantallaHistorialAsistencia(),
    ),
    GoRoute(
      path: '/instructor/mis-grupos',
      builder: (_, _) => const PantallaGrupos(conAtras: true),
    ),
    GoRoute(
      path: '/instructor/mis-avisos',
      builder: (_, _) => const PantallaAvisosInstructor(conAtras: true),
    ),

    // ==========================================
    // ADMINISTRADOR: 5 PESTAÑAS
    // ==========================================
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => EstructuraAdmin(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin',
              builder: (_, _) => const PantallaInicioAdmin(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/talleres',
              builder: (_, _) => const PantallaTalleresAdmin(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/alumnos',
              builder: (_, _) => const PantallaAlumnosAdmin(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/reportes',
              builder: (_, _) => const PantallaReportes(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/perfil',
              builder: (_, _) => const PantallaPerfilAdmin(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/admin/taller/nuevo',
      builder: (_, _) => const PantallaFormularioActividad(),
    ),
    GoRoute(
      path: '/admin/taller/:id/editar',
      builder: (_, s) => PantallaFormularioActividad(
        tallerId: int.parse(s.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/admin/alumnos/nuevo',
      builder: (_, _) => const PantallaFormularioAlumno(),
    ),
    GoRoute(
      path: '/admin/alumnos/:id/editar',
      builder: (_, s) => PantallaFormularioAlumno(
        alumnoId: int.parse(s.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/admin/instructores',
      builder: (_, _) => const PantallaInstructoresAdmin(),
    ),
    GoRoute(
      path: '/admin/instructores/nuevo',
      builder: (_, _) => const PantallaFormularioInstructor(),
    ),
    GoRoute(
      path: '/admin/instructores/:id/editar',
      builder: (_, s) => PantallaFormularioInstructor(
        instructorId: int.parse(s.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/admin/periodo',
      builder: (_, _) => const PantallaPeriodoEscolar(),
    ),
    GoRoute(
      path: '/admin/avisos',
      builder: (_, _) => const PantallaAvisosGenerales(),
    ),
    GoRoute(
      path: '/admin/especialidades',
      builder: (_, _) => const PantallaEspecialidades(),
    ),
    GoRoute(
      path: '/admin/categorias',
      builder: (_, _) => const PantallaCategorias(),
    ),
  ],
);