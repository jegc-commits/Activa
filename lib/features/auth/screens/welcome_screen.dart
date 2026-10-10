import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.primary],
          ),
        ),
        child: Column(
          children: [
            const Expanded(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tu universidad\ntambién se vive\nfuera del aula',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 84),
                    const SizedBox(height: 12),
                    const Text('ACTIVA',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    const SizedBox(height: 4),
                    const Text(
                      'Activación de Clubes y Talleres Institucionales para la Vida Académica',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Benefit(Icons.emoji_events, 'Suma horas'),
                        _Benefit(Icons.people, 'Haz amigos'),
                        _Benefit(Icons.star, 'Vive experiencias'),
                        _Benefit(Icons.bar_chart, 'Crece'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => context.push('/register'),
                      child: const Text('Crear cuenta'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/student'),
                      child: const Text('Explorar sin cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
}