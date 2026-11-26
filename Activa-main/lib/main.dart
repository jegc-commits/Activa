import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'aplicacion.dart';
import 'datos/almacen_cuentas.dart';
import 'datos/estado_app.dart';
import 'datos/sesion.dart';

const String _supabaseUrl = 'https://xxfasklvsoqvhfkhevxf.supabase.co';
const String _supabaseAnonKey =
    'sb_publishable_-hS0MGHlpe3_5JjnIrvN9A_v1Vk6hua';

final supabase = Supabase.instance.client;

// arranca la app con los 2 estados: datos (EstadoApp) y sesion (quien entro + fotos)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  final almacen = await AlmacenCuentas.cargar();
  final estado = EstadoApp(almacen);
  await estado.cargar();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: estado),
        ChangeNotifierProvider<EstadoSesion>(
          create: (_) => EstadoSesion(almacen),
        ),
      ],
      child: const AplicacionActiva(),
    ),
  );
}
