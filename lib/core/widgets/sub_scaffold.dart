import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SubScaffold extends StatelessWidget {
  const SubScaffold({
    super.key,
    required this.title,
    required this.child,
    this.fallback = '/welcome',
  });
  final String title;
  final Widget child;
  final String fallback; // a dónde ir si no hay pantalla previa

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          scrolledUnderElevation: 0,
          leading: BackButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(fallback)),
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
        body: SafeArea(child: child),
      );
}