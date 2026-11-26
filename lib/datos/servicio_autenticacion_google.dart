// ===================================================================
// servicio_autenticacion_google.dart
// Variante FOSS (F-Droid): el login con Google (Firebase) se eliminó
// porque depende de SDKs propietarios. Esta implementación no-op mantiene
// la misma API para que el resto de la app compile sin cambios; el botón
// "Continuar con Google" queda siempre oculto (`disponible == false`).
// ===================================================================

import 'package:flutter/foundation.dart';

class ResultadoGoogle {
  final bool ok;
  final String? correo;
  final String? error;
  const ResultadoGoogle({required this.ok, this.correo, this.error});
}

class ServicioAutenticacionGoogle {
  ServicioAutenticacionGoogle._();
  static final instancia = ServicioAutenticacionGoogle._();

  bool _disponible = false;
  bool get disponible => _disponible;

  Future<void> inicializar() async {
    _disponible = false;
    debugPrint('ACTIVA (FOSS): login con Google no disponible en esta build.');
  }

  Future<ResultadoGoogle> iniciarSesion() async {
    return const ResultadoGoogle(
      ok: false,
      error: 'El login con Google no está disponible en esta versión',
    );
  }

  Future<void> cerrarSesion() async {}
}
