import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/app_state.dart';
import '../../../models/taller.dart';
import 'taller_thumb.dart';

class CupoLabel extends StatelessWidget {
  const CupoLabel(this.taller, {super.key});
  final Taller taller;

  @override
  Widget build(BuildContext context) {
    final ok = taller.hayCupo;
    final n = taller.cuposDisponibles;
    final color = ok ? AppColors.teal : AppColors.danger;
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            ok ? '$n ${n == 1 ? 'lugar disponible' : 'lugares disponibles'}' : 'Cupo lleno',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class HeartButton extends StatelessWidget {
  const HeartButton(this.tallerId, {super.key, this.radius = 16});
  final int tallerId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fav = context.select<AppState, bool>((s) => s.esFavorito(tallerId));
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => context.read<AppState>().toggleFavorito(tallerId),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Icon(
          fav ? Icons.favorite : Icons.favorite_border,
          size: radius + 2,
          color: fav ? AppColors.danger : AppColors.navy,
        ),
      ),
    );
  }
}

class TallerCard extends StatelessWidget {
  const TallerCard(this.taller, {super.key});
  final Taller taller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/activity/${taller.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TallerBanner(
              taller,
              height: 110,
              child: Positioned(top: 8, right: 8, child: HeartButton(taller.id)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(taller.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(taller.categoria.etiqueta,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 6),
                  Text(taller.instructor.nombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 11)),
                  Text(taller.horarioTexto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 11)),
                  const SizedBox(height: 4),
                  CupoLabel(taller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}