import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/app_state.dart';

class InstructorProfileScreen extends StatelessWidget {
  const InstructorProfileScreen({super.key});

  Widget _item(BuildContext c, IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      );

  void _soon(BuildContext c) => ScaffoldMessenger.of(c)
      .showSnackBar(const SnackBar(content: Text('Próximamente')));

  @override
  Widget build(BuildContext context) {
    final i = context.watch<AppState>().instructor;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.navy,
              child: Text(iniciales(i.nombre, i.apellidoPaterno),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Text(i.nombreCompleto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              const Chip(label: Text('Instructor')),
              Chip(label: Text(i.especialidad)),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: ListTile.divideTiles(context: context, tiles: [
                _item(context, Icons.groups, 'Mis grupos',
                    () => context.go('/instructor/groups')),
                _item(context, Icons.check_circle, 'Historial de asistencia',
                    () => _soon(context)),
                _item(context, Icons.notifications, 'Mis avisos publicados',
                    () => context.go('/instructor/notices')),
                _item(context, Icons.edit, 'Editar perfil', () => _soon(context)),
                _item(context, Icons.settings, 'Configuración', () => _soon(context)),
              ]).toList(),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/welcome'),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}