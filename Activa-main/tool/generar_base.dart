// ===================================================================
// generar_base.dart
// Genera el archivo activa.sqlite (junto a la carpeta lib) con el
// esquema, el catálogo y el administrador inicial, sin datos de ejemplo.
//
// Uso:
//   flutter test tool/generar_base.dart
// ===================================================================

import 'dart:io';

import 'package:activa/datos/bd/base_datos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('genera activa.sqlite limpio', () async {
    sqfliteFfiInit();
    final destino = File('activa.sqlite').absolute.path;
    final archivo = File(destino);
    if (archivo.existsSync()) archivo.deleteSync();

    final bd = BaseDatos.pruebas(databaseFactoryFfi, destino);
    await bd.abrir();
    await bd.cerrar();

    expect(archivo.existsSync(), isTrue);
    expect(archivo.lengthSync(), greaterThan(0));
    // ignore: avoid_print
    print('Base creada en: $destino');
  });
}
