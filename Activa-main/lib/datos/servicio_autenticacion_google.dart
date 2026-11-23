// ===================================================================
// servicio_autenticacion_google.dart
// Login real con Google (Firebase Authentication + google_sign_in).
// No es simulado: usa las credenciales que generes siguiendo
// GUIA_LOGIN_GOOGLE.md. Mientras no configures Firebase, `disponible`
// es false y el botón "Continuar con Google" se queda oculto solo,
// así que el resto de la app sigue funcionando sin romperse.
// ===================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Se llama una sola vez al arrancar la app (ver main.dart). Si Firebase
  /// todavía no está configurado, falla en silencio y `disponible` queda
  /// en false: el resto de la app no se entera.
  Future<void> inicializar() async {
    try {
      await Firebase.initializeApp();
      await GoogleSignIn.instance.initialize();
      _disponible = true;
    } catch (e) {
      debugPrint('ACTIVA: login con Google no está configurado todavía: $e');
      _disponible = false;
    }
  }

  /// Abre el flujo de Google y, si todo sale bien, entra también a
  /// Firebase Auth. Devuelve el correo con el que se autenticó para que
  /// EstadoSesion busque la cuenta de ACTIVA que le corresponde.
  Future<ResultadoGoogle> iniciarSesion() async {
    if (!_disponible) {
      return const ResultadoGoogle(
        ok: false,
        error: 'El login con Google no está configurado en esta app todavía',
      );
    }
    try {
      final cuentaGoogle = await GoogleSignIn.instance.authenticate();
      final auth = cuentaGoogle.authentication;
      final credencial = GoogleAuthProvider.credential(idToken: auth.idToken);
      final resultado = await FirebaseAuth.instance.signInWithCredential(
        credencial,
      );
      final correo = resultado.user?.email ?? cuentaGoogle.email;
      return ResultadoGoogle(ok: true, correo: correo.toLowerCase());
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const ResultadoGoogle(ok: false); // el usuario canceló
      }
      return ResultadoGoogle(
        ok: false,
        error: 'No se pudo entrar con Google (${e.code.name})',
      );
    } catch (e) {
      return const ResultadoGoogle(
        ok: false,
        error: 'No se pudo entrar con Google. Intenta de nuevo',
      );
    }
  }

  Future<void> cerrarSesion() async {
    if (!_disponible) return;
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}