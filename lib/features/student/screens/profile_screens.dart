import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/app_state.dart';
import '../../../data/mock/mock_data.dart';
import '../widgets/taller_thumb.dart';

void _soon(BuildContext c) => ScaffoldMessenger.of(c)
    .showSnackBar(const SnackBar(content: Text('Próximamente')));

// Estructura común de las sub-pantallas (flecha atrás + título)
class _Sub extends StatelessWidget {
  const _Sub(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          scrolledUnderElevation: 0,
          leading: BackButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/student/profile')),
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
        body: SafeArea(child: child),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.chip = false});
  final String label;
  final String value;
  final bool chip;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 100,
                child: Text(label,
                    style: const TextStyle(color: Colors.black45, fontSize: 12))),
            Expanded(
              child: chip
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(value,
                            style: const TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    )
                  : Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

// ───────────────────────── Perfil ─────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _item(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AppState>().alumno;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.navy,
              child: Text(inicialesDe(a.nombre),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Text(a.nombreCompleto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text('Número de Control: ${a.numeroControl}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 20),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: ListTile.divideTiles(context: context, tiles: [
                _item(Icons.school, 'Mis datos académicos',
                    () => context.push('/profile/academic')),
                _item(Icons.calendar_today, 'Mis actividades',
                    () => context.go('/student/activities')),
                _item(Icons.description, 'Mis comprobantes',
                    () => context.push('/profile/receipts')),
                _item(Icons.bar_chart, 'Mi progreso',
                    () => context.push('/profile/progress')),
                _item(Icons.edit, 'Editar perfil',
                    () => context.push('/profile/edit')),
                _item(Icons.settings, 'Configuración',
                    () => context.push('/profile/settings')),
              ]).toList(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            onPressed: () => context.go('/admin'),
            child: const Text('Ver panel de coordinador (demo)'),
          ),
          TextButton(
            onPressed: () => context.go('/welcome'),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Datos académicos ─────────────────────
class AcademicScreen extends StatelessWidget {
  const AcademicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.alumno;
    final h = s.horasRealizadas;
    return _Sub(
      'Mis datos académicos',
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.navy,
                  child: Text(inicialesDe(a.nombre),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.nombreCompleto,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('Número de Control: ${a.numeroControl}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                const _Line('Universidad',
                    'Universidad Tecnológica del Norte de Guanajuato'),
                _Line('Carrera', a.carrera),
                _Line('Grupo', a.grupo),
                const _Line('Periodo', mockPeriodo),
                const _Line('Estatus', 'Activo', chip: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                        child: Text('Actividad paraescolar',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Text('$h / $metaHoras horas',
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
                const SizedBox(height: 8),
                Text(
                  h >= metaHoras
                      ? '¡Completaste tu actividad paraescolar!'
                      : 'Te faltan ${metaHoras - h} horas para completar tu actividad paraescolar.',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Comprobantes ─────────────────────
class _Doc {
  const _Doc(this.esHoras, this.titulo, this.detalle, {this.locked = false});
  final bool esHoras;
  final String titulo;
  final String detalle;
  final bool locked;
}

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});
  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  int _tab = 0; // 0 inscripciones, 1 horas, 2 todos

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final h = s.horasRealizadas;
    final docs = <_Doc>[
      for (final i in s.misInscripciones)
        _Doc(false, 'Comprobante de inscripción',
            '${i.taller.nombre} · Folio ${i.folio}\nEmitido el ${fechaLarga(i.fechaInscripcion)}'),
      _Doc(true, 'Constancia parcial de horas',
          '$h de $metaHoras horas acumuladas\nActualizada hoy'),
      _Doc(true, 'Constancia final de horas',
          'Se habilita al completar las $metaHoras horas',
          locked: h < metaHoras),
    ];
    final visibles = docs
        .where((d) => _tab == 2 || (_tab == 1) == d.esHoras)
        .toList();

    return _Sub(
      'Mis comprobantes',
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              for (final (i, t) in ['Inscripciones', 'Horas', 'Todos'].indexed) ...[
                ChoiceChip(
                  label: Text(t),
                  selected: _tab == i,
                  onSelected: (_) => setState(() => _tab = i),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (final d in visibles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(Icons.description,
                          color: d.locked ? Colors.black26 : AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(d.detalle,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(d.locked ? Icons.lock : Icons.download,
                          color: d.locked ? Colors.black26 : AppColors.primary),
                      onPressed: d.locked ? null : () => _soon(context),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Presenta tus comprobantes con tu instructor o en la coordinación cuando te los pidan.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Progreso ─────────────────────
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

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final h = s.horasRealizadas;
    final pct = (h / metaHoras).clamp(0.0, 1.0);
    return _Sub(
      'Mi progreso',
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 14,
                          backgroundColor: AppColors.background,
                          color: AppColors.primary,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$h',
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy)),
                          Text('de $metaHoras horas',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('${(pct * 100).round()} % completado',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  h >= metaHoras
                      ? '¡Meta del cuatrimestre cumplida!'
                      : 'Te faltan ${metaHoras - h} horas para tu meta del cuatrimestre.',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(Icons.star, '${s.misInscripciones.length}', 'Actividades'),
              const SizedBox(width: 10),
              const _Stat(Icons.access_time, '$mockHorasMes h', 'Este mes'),
              const SizedBox(width: 10),
              const _Stat(Icons.check_circle, '$mockAsistencia %', 'Asistencia'),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Horas por actividad',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                for (final i in s.misInscripciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        TallerThumb(i.taller, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.taller.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (s.horasDe(i.folio) / metaHoras).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: AppColors.background,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${s.horasDe(i.folio)} h',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
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

// ───────────────────── Editar perfil ─────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _nombre =
      TextEditingController(text: context.read<AppState>().alumno.nombreCompleto);
  late final _tel =
      TextEditingController(text: context.read<AppState>().alumno.telefono ?? '');

  @override
  void dispose() {
    _nombre.dispose();
    _tel.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<AppState>().actualizarPerfil(_nombre.text, _tel.text);
    final m = ScaffoldMessenger.of(context);
    context.pop();
    m.showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _locked(IconData icon, String value) => TextFormField(
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(prefixIcon: Icon(icon)),
      );

  @override
  Widget build(BuildContext context) {
    final a = context.read<AppState>().alumno;
    return _Sub(
      'Editar perfil',
      Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.navy,
                child: Text(inicialesDe(a.nombre),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ),
            ),
            Center(
              child: TextButton(
                  onPressed: () => _soon(context), child: const Text('Cambiar foto')),
            ),
            _label('Nombre completo'),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
              validator: (v) => (v ?? '').trim().split(RegExp(r'\s+')).length >= 2
                  ? null
                  : 'Escribe nombre y apellido',
            ),
            _label('Correo institucional'),
            _locked(Icons.email, a.correo),
            _label('Teléfono'),
            TextFormField(
              controller: _tel,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.phone)),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return d.length == 10 ? null : 'Escribe 10 dígitos';
              },
            ),
            _label('Número de control'),
            _locked(Icons.school, a.numeroControl),
            _label('Grupo'),
            _locked(Icons.groups, a.grupo),
            const SizedBox(height: 28),
            FilledButton(onPressed: _save, child: const Text('Guardar cambios')),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Configuración ─────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TODO: persistir en backend (hoy no hay tabla de preferencias)
  bool _avisos = true, _horario = true, _recordatorios = true, _cupos = false;

  Widget _sw(String t, IconData i, bool v, ValueChanged<bool> f) => SwitchListTile(
        secondary: Icon(i, color: AppColors.primary),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        value: v,
        onChanged: (x) => setState(() => f(x)),
      );

  Widget _nav(String t, IconData i, VoidCallback f, {String? trailing}) => ListTile(
        leading: Icon(i, color: AppColors.primary),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing, style: const TextStyle(color: Colors.black45)),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
        onTap: f,
      );

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 16)),
      );

  @override
  Widget build(BuildContext context) {
    return _Sub(
      'Configuración',
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _title('Notificaciones'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _sw('Avisos de actividades', Icons.notifications, _avisos, (v) => _avisos = v),
              _sw('Cambios de horario', Icons.access_time, _horario, (v) => _horario = v),
              _sw('Recordatorios de clase', Icons.calendar_today, _recordatorios, (v) => _recordatorios = v),
              _sw('Cupos disponibles', Icons.star, _cupos, (v) => _cupos = v),
            ]),
          ),
          _title('Cuenta'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _nav('Cambiar contraseña', Icons.lock, () => context.push('/forgot')),
              _nav('Idioma', Icons.language, () => _soon(context), trailing: 'Español'),
            ]),
          ),
          _title('Privacidad y ayuda'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _nav('Aviso de privacidad', Icons.shield, () => _soon(context)),
              _nav('Ayuda y soporte', Icons.help_outline, () => _soon(context)),
            ]),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/welcome'),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: AppColors.danger)),
          ),
          const Center(
            child: Text('ACTIVA · Versión 1.0',
                style: TextStyle(color: Colors.black38, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}