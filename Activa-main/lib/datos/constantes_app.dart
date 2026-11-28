// ===================================================================
// constantes_app.dart
// Reglas y datos de configuración reales de ACTIVA (no son datos de
// ejemplo). Antes vivían mezclados con los datos simulados.
// ===================================================================

/// Meta de sesiones paraescolares por cuatrimestre.
const metaSesiones = 60;

/// Periodo escolar que se muestra en la app, calculado con la fecha actual.
String get periodoActual {
  final ahora = DateTime.now();
  final anio = ahora.year;
  if (ahora.month >= 9) return 'Septiembre – Diciembre $anio';
  if (ahora.month >= 5) return 'Mayo – Agosto $anio';
  return 'Enero – Abril $anio';
}

// ---- Cuenta de administrador que se crea la primera vez ----
// Solo se crea si la base de datos no tiene ningún administrador.
// La contraseña se guarda con hash, nunca en texto.
const usuarioAdminInicial = 'admin';
const correoAdminInicial = 'admin@utng.edu.mx';
const contrasenaAdminInicial = 'Activa2026!';
const nombreAdminInicial = 'Coordinación';
const apellidoAdminInicial = 'de Paraescolares';