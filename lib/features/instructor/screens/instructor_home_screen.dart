import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/app_state.dart';
import '../../../data/mock/mock_data.dart';
import '../../student/widgets/taller_thumb.dart';

class InstructorHomeScreen extends StatelessWidget {
  const InstructorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final i = s.instructor;
    final grupos = s.misGrupos;
    final alumnos = grupos.fold<int>(0, (a, t) => a + t.inscritos);
    final t = grupos.isEmpty ? null : grupos.first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Hola, ${i.nombre.split(' ').first}!',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    Text('Instructor de ${i.especialidad}',
                        style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.navy,
                child: Text(iniciales(i.nombre, i.apellidoPaterno),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (t == null)
            const AppCard(child: Text('Aún no tienes grupos asignados'))
          else
            _SessionCard(taller: t),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(Icons.groups, '$alumnos', 'Alumnos'),
              const SizedBox(width: 10),
              const _Stat(Icons.check_circle, '$mockAsistenciaInstructor %', 'Asistencia'),
              const SizedBox(width: 10),
              _Stat(Icons.apps, '${grupos.length}', 'Grupos'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text('Mis grupos',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
              ),
              TextButton(
                  onPressed: () => context.go('/instructor/groups'),
                  child: const Text('Ver todos ›')),
            ],
          ),
          for (final g in grupos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => context.push('/instructor/group/${g.id}'),
                child: Row(
                  children: [
                    TallerThumb(g, size: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(g.horarioTexto,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${g.inscritos} / ${g.cupoMaximo}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.taller});
  final dynamic taller; // Taller

  @override
  Widget build(BuildContext context) {
    final t = taller;
    final f = t.sesionReciente() as DateTime;
    final hoy = mismoDia(f, DateTime.now());
    final h = t.horarioDe(f);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(hoy ? 'Sesión de hoy' : 'Última sesión',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(hoy ? 'Hoy · ${h.horaInicio}' : fechaConDia(f),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TallerThumb(t, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nombre as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${h.horaInicio} – ${h.horaFin}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    Text(t.lugar as String,
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push(
                      '/instructor/take/${t.id}?fecha=${fechaIso(f)}'),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Pasar lista'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => context.push('/instructor/group/${t.id}'),
                  icon: const Icon(Icons.groups, size: 18),
                  label: const Text('Ver alumnos'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
              Text(label,
                  style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
        ),
      );
}