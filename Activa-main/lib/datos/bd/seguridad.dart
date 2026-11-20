// ===================================================================
// seguridad.dart
// Utilidades para guardar contraseñas de forma segura: una sal aleatoria
// por cuenta y un hash SHA-256. La contraseña nunca se guarda en texto.
// ===================================================================

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Sal aleatoria de 16 bytes en base64url.
String generarSal() {
  final r = Random.secure();
  return base64UrlEncode(List.generate(16, (_) => r.nextInt(256)));
}

/// Hash SHA-256 de "sal:contraseña".
String hashContrasena(String sal, String contrasena) =>
    sha256.convert(utf8.encode('$sal:$contrasena')).toString();

/// Compara una contraseña escrita con el hash guardado.
bool contrasenaCorrecta(String sal, String hash, String contrasena) =>
    hash.isNotEmpty && hash == hashContrasena(sal, contrasena);
