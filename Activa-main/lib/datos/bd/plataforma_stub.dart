// Implementación de respaldo (no debería usarse en ninguna plataforma real).
import 'package:sqflite_common/sqlite_api.dart';

DatabaseFactory fabricaSqlite() =>
    throw UnsupportedError('Plataforma no soportada para SQLite');

Future<String> rutaBaseDatos() async => 'activa.db';
