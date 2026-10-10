import 'package:activa/features/student/widgets/taller_thumb.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../data/app_state.dart';
import '../../../../data/mock/mock_data.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Widget _action(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final casi = s.talleres
        .where((t) => t.activo && t.hayCupo && t.cuposDisponibles <= 3)
        .toList();
    final activos = s.talleres.where((t) => t.activo).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panel de coordinación',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    Text('Ciclo $mockPeriodo',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.navy,
                child: Text('CP',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: StatCard(Icons.groups, '${s.todosAlumnos.length}', 'Estudiantes')),
              const SizedBox(width: 10),
              Expanded(child: StatCard(Icons.star, '${s.talleres.length}', 'Actividades')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: StatCard(Icons.check_circle, '${s.totalInscripciones}', 'Inscripciones')),
              const SizedBox(width: 10),
              Expanded(child: StatCard(Icons.event_seat, '${s.totalCupos}', 'Cupos disp.')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _action(Icons.add, 'Nueva actividad',
                  () => context.push('/admin/activity/new')),
              const SizedBox(width: 10),
              _action(Icons.person_add, 'Instructores',
                  () => context.push('/admin/instructors')),
              const SizedBox(width: 10),
              _action(Icons.bar_chart, 'Reportes',
                  () => context.go('/admin/reports')),
            ],
          ),
          if (casi.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Por revisar',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 10),
            AppCard(
              onTap: () => context.go('/admin/activities'),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                    child: const Icon(Icons.star, color: AppColors.danger),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actividades casi llenas',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Con 3 cupos o menos',
                            style: TextStyle(color: Colors.black54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('${casi.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Actividades activas',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 10),
          for (final t in activos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => context.push('/admin/activity/${t.id}/edit'),
                child: Row(
                  children: [
                    TallerThumb(t, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(t.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Text('${t.inscritos} / ${t.cupoMaximo}',
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: t.inscritos / t.cupoMaximo,
                              minHeight: 7,
                              backgroundColor: AppColors.background,
                              color: t.hayCupo ? AppColors.teal : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}