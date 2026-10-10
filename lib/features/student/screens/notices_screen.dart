import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/app_state.dart';
import '../../../models/enums.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  (Color, IconData) _style(TipoAviso t) => switch (t) {
        TipoAviso.cambioHorario => (AppColors.warning, Icons.access_time),
        TipoAviso.informativo => (AppColors.primary, Icons.person),
        TipoAviso.recordatorio => (AppColors.teal, Icons.star),
        TipoAviso.cancelacion => (AppColors.danger, Icons.cancel),
      };

  @override
  Widget build(BuildContext context) {
    final avisos = context.watch<AppState>().avisos;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Notificaciones',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 14),
          if (avisos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No tienes avisos')),
            ),
          for (final a in avisos)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: _style(a.tipo).$1.withValues(alpha: 0.18),
                      child: Icon(_style(a.tipo).$2, color: _style(a.tipo).$1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(a.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              if (esNuevo(a.fecha))
                                const Icon(Icons.circle, size: 8, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(tiempoRelativo(a.fecha),
                                  style: const TextStyle(
                                      color: Colors.black45, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(a.mensaje,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
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