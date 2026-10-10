import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class ActivaApp extends StatelessWidget {
  const ActivaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'ACTIVA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      );
}