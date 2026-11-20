// Android, iOS y escritorio (Linux, Windows, macOS).
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as movil;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseFactory fabricaSqlite() {
  if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  // Android / iOS: plugin oficial sqflite
  return movil.databaseFactory;
}

Future<String> rutaBaseDatos() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'activa.db');
}
