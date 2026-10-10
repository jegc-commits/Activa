import 'package:activa/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sub_scaffold.dart';
import '../../../data/app_state.dart';
import '../../../models/taller.dart';

class AttendanceTabScreen extends StatelessWidget {
  const AttendanceTabScreen({super.key});

  Future<void> _otraFecha(BuildContext context, Taller t) async {
    final inicial = t.sesionReciente();
    final f = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2026, 9, 1),
      lastDate: inicial,
      // solo días en que el grupo tiene clase
      selectableDayPredicate: (d) =>
          t.horarios.any((h) => h.dia.weekday == d.weekday),
    );
    if (f != null && context.mounted) {
      context.push('/instructor/take/${t.id}?fecha=${fechaIso(f)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Asistencia',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 14),
          for (final t in s.misGrupos)
            Builder(builder: (_) {
              final f = t.sesionReciente();
              final total = s.alumnosDe(t.id).length;
              final marcados = s.asistenciaDe(t.id, f).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('Sesión: ${fechaConDia(f)} · ${t.horarioDe(f).horaInicio}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      Text('Lista tomada: $marcados de $total alumnos',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: marcados == 0 ? AppColors.warning : AppColors.teal)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.push(
                            '/instructor/take/${t.id}?fecha=${fechaIso(f)}'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(marcados == 0 ? 'Pasar lista' : 'Editar lista'),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () => _otraFecha(context, t),
                          child: const Text('Otra fecha'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ───────── Pasar lista ─────────
class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen(
      {super.key, required this.tallerId, required this.fecha});
  final int tallerId;
  final DateTime fecha;
  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  // numControl -> presente. Si no está en el mapa = sin marcar.
  late final Map<String, bool> _m =
      context.read<AppState>().asistenciaDe(widget.tallerId, widget.fecha);

  void _set(String c, bool v) => setState(() {
        if (_m[c] == v) {
          _m.remove(c); // tocar de nuevo desmarca
        } else {
          _m[c] = v;
        }
      });

  void _save() {
    final s = context.read<AppState>();
    final t = s.tallerPorId(widget.tallerId);
    final msg = ScaffoldMessenger.of(context);
    s.guardarAsistencia(t, widget.fecha, _m);
    context.pop();
    msg.showSnackBar(const SnackBar(content: Text('Asistencia guardada')));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.tallerPorId(widget.tallerId);
    final alumnos = s.alumnosDe(t.id);
    final h = t.horarioDe(widget.fecha);
    final presentes = _m.values.where((v) => v).length;
    final faltas = _m.values.where((v) => !v).length;
    final sin = alumnos.length - presentes - faltas;

    return SubScaffold(
      title: 'Pasar lista',
      fallback: '/instructor/attendance',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(
                          '${fechaConDia(widget.fecha)} · ${h.horaInicio} – ${h.horaFin}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      Text('Cada asistencia suma ${t.horasPorSesion} h',
                          style: const TextStyle(color: Colors.black45, fontSize: 11)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Count('Presentes', presentes, AppColors.teal),
                          const SizedBox(width: 8),
                          _Count('Faltas', faltas, AppColors.danger),
                          const SizedBox(width: 8),
                          _Count('Sin marcar', sin, Colors.black45),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final a in alumnos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Text(iniciales(a.nombre, a.apellidoPaterno),
                                style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.nombreCompleto,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(a.numeroControl,
                                    style: const TextStyle(
                                        color: Colors.black45, fontSize: 11)),
                              ],
                            ),
                          ),
                          _Mark(Icons.check, _m[a.numeroControl] == true,
                              AppColors.teal, () => _set(a.numeroControl, true)),
                          const SizedBox(width: 8),
                          _Mark(Icons.close, _m[a.numeroControl] == false,
                              AppColors.danger, () => _set(a.numeroControl, false)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    for (final a in alumnos) {
                      _m[a.numeroControl] = true;
                    }
                  }),
                  child: const Text('Marcar todos presentes'),
                ),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Guardar asistencia'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
}

class _Mark extends StatelessWidget {
  const _Mark(this.icon, this.active, this.color, this.onTap);
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.transparent,
            border: Border.all(color: active ? color : Colors.black26),
          ),
          child: Icon(icon, size: 20, color: active ? Colors.white : Colors.black38),
        ),
      );
}