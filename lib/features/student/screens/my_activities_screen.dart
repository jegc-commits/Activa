import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/app_state.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/inscripcion.dart';
import '../widgets/taller_thumb.dart';

class MyActivitiesScreen extends StatelessWidget {
  const MyActivitiesScreen({super.key});

   Future<void> _baja(BuildContext context, Inscripcion i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('¿Darte de baja?'),
        content: Text(
            'Dejarás de pertenecer a ${i.taller.nombre} y se liberará tu lugar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Darme de baja'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AppState>().cancelar(i.folio);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te diste de baja de ${i.taller.nombre}')));
    }
  }


  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lista = s.misInscripciones;
    final h = s.horasRealizadas;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Mis actividades',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                        child: Text('Horas acumuladas',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Text('$h / $metaHoras',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (h / metaHoras).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  const Text('Aún no estás inscrito en ninguna actividad'),
                  TextButton(
                    onPressed: () => context.go('/student/explore'),
                    child: const Text('Explorar actividades'),
                  ),
                ],
              ),
            ),
          for (final i in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => context.push('/enrollment/${i.folio}'),
                child: Row(
                  children: [
                    TallerThumb(i.taller, size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.taller.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(i.taller.horarioTexto.replaceAll(' | ', ' · '),
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                          Text('Folio ${i.folio}',
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 11)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => v == 'ver'
                          ? context.push('/enrollment/${i.folio}')
                          : _baja(context, i),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'ver', child: Text('Ver comprobante')),
                        PopupMenuItem(value: 'baja', child: Text('Darme de baja')),
                      ],
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