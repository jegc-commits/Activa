// Web (Chrome/Edge): SQLite compilado a WebAssembly y guardado en IndexedDB.
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory fabricaSqlite() => databaseFactoryFfiWeb;

Future<String> rutaBaseDatos() async => 'activa.db';
