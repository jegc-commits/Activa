// Envía el código de recuperación de contraseña por correo real, usando
// EmailJS (https://www.emailjs.com) — un servicio gratuito que manda el
// correo directo desde la app (sin necesitar un servidor propio) usando
// una cuenta de Gmail conectada desde su panel.
//
// Para activarlo, sigue GUIA_CORREO_RECUPERACION.md y pega aquí tus 3
// datos de EmailJS (Service ID, Template ID y Public Key).
import 'dart:convert';
import 'package:http/http.dart' as http;


class ServicioCorreoRecuperacion {
  // ====== PEGA AQUÍ TUS DATOS DE EMAILJS (ver la guía) ======
  static const String _serviceId = 'service_uqe3iqn';
  static const String _templateId = 'template_tf2xubn';
  static const String _publicKey = 'syiA-ZlfIHBP7Ddyx';
  // ===========================================================

  /// true cuando ya se pegaron los 3 datos de arriba.
  static bool get estaConfigurado =>
      _serviceId != 'TU_SERVICE_ID' &&
      _templateId != 'TU_TEMPLATE_ID' &&
      _publicKey != 'TU_PUBLIC_KEY';

  /// Manda el correo con el código de 6 dígitos. Regresa true si EmailJS
  /// contestó que sí lo envió.
  static Future<bool> enviarCodigo({
    required String correoDestino,
    required String nombre,
    required String codigo,
  }) async {
    if (!estaConfigurado) return false;
    try {
      final resp = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': correoDestino,
            'nombre': nombre,
            'codigo': codigo,
          },
        }),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}