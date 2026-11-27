// ===================================================================
// Notificaciones push reales (locales): cuando se publica un aviso,
// el teléfono muestra de verdad una notificación del sistema, no
// solo un aviso dentro de la app.
//
// Usa flutter_local_notifications. En Android hay que pedir permiso
// (Android 13+) antes de que aparezcan; eso se hace una sola vez al
// iniciar la app, en Notificaciones.inicializar().
// ===================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notificaciones {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _listo = false;

  /// Llamar una sola vez al arrancar la app (ver main.dart).
  /// En la versión web (GitHub Pages) esto no hace nada: esa versión del
  /// paquete no trae soporte de navegador, y así evitamos que la app web
  /// truene al arrancar. En Android/iOS sí muestra notificaciones reales.
  static Future<void> inicializar() async {
    if (_listo || kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios, macOS: ios),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _listo = true;
    } catch (_) {
      // Si el dispositivo niega el permiso o algo falla, la app sigue
      // funcionando normal; solo no se mostrará la notificación.
    }
  }

  /// Muestra una notificación real en la barra del sistema.
  static Future<void> mostrar({
    required String titulo,
    required String cuerpo,
  }) async {
    if (kIsWeb) return;
    try {
      if (!_listo) await inicializar();
      const detalles = NotificationDetails(
        android: AndroidNotificationDetails(
          'activa_avisos',
          'Avisos de ACTIVA',
          channelDescription: 'Avisos de talleres, clubes y actividades',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titulo,
        cuerpo,
        detalles,
      );
    } catch (_) {
      // Nunca dejamos que un problema con notificaciones tumbe la app.
    }
  }
}