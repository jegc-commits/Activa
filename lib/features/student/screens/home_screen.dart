import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/mock/mock_data.dart';
import '../widgets/taller_thumb.dart';
import 'package:provider/provider.dart';
import '../../../data/app_state.dart';
import '../../../core/utils/formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    
    final state = context.watch<AppState>();
    final nombre = state.alumno.nombre.split(' ').first;
    final iniciales = inicialesDe(nombre);
    final horas = state.horasRealizadas;
    final faltan = (metaHoras - horas).clamp(0, metaHoras);
    final sugerido = state.talleres.firstWhere(
      (t) => t.hayCupo && !state.estaInscrito(t.id),
      orElse: () => state.talleres.first,
    );
    final aviso = state.avisos.first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Saludo
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Hola, $nombre!',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    const Text('Descubre, participa y vive tu universidad.',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.navy,
                child: Text(iniciales,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progreso
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tu progreso paraescolar',
                              style: TextStyle(color: Colors.black54, fontSize: 13)),
                          Text('$horas / $metaHoras horas',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events, color: AppColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: horas / metaHoras,
                    minHeight: 10,
                    backgroundColor: AppColors.background,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  faltan == 0
                      ? '¡Completaste tus horas paraescolares!'
                      : 'Te faltan $faltan horas para completar tu actividad paraescolar. ¡Tú puedes!',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categorías
          _SectionHeader('Encuentra algo para ti',
              onSeeAll: () => context.go('/student/explore')),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Category(Icons.apps, 'Todas', () => context.go('/student/explore')),
              _Category(Icons.sports_soccer, 'Deportes', () => context.go('/student/explore')),
              _Category(Icons.theater_comedy, 'Cultura', () => context.go('/student/explore')),
              _Category(Icons.star, 'Otros', () => context.go('/student/explore')),
            ],
          ),
          const SizedBox(height: 24),

          // Actividad sugerida
          const Text('Actividad sugerida',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 12),
          AppCard(
            // TODO paso 6: context.push('/student/activity/${sugerido.id}')
            onTap: () => context.go('/student/explore'),
            child: Row(
              children: [
                TallerThumb(sugerido, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sugerido.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(sugerido.horarioTexto,
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      Text(sugerido.lugar,
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Avisos recientes
          _SectionHeader('Avisos recientes',
              onSeeAll: () => context.go('/student/notices')),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications, color: AppColors.warning),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aviso.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(aviso.mensaje,
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('Ver todos ›')),
        ],
      );
}

class _Category extends StatelessWidget {
  const _Category(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}