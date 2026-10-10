import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sub_scaffold.dart';
import '../../../data/app_state.dart';
import '../../../data/mock/mock_data.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});
  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _search = TextEditingController();
  int _f = 0; // 0 todos, 1 con 60 h, 2 en proceso, 3 sin actividad

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _search.text.trim().toLowerCase();
    final lista = s.todosAlumnos.where((a) {
      final h = s.horasAlumno(a);
      final ok = switch (_f) {
        1 => h >= metaHoras,
        2 => h > 0 && h < metaHoras,
        3 => h == 0,
        _ => true,
      };
      return ok &&
          (a.nombreCompleto.toLowerCase().contains(q) ||
              a.numeroControl.contains(q));
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Alumnos',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text('${s.todosAlumnos.length} alumnos registrados',
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre o número de control',
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, n) in ['Todos', 'Con 60 h', 'En proceso', 'Sin actividad'].indexed) ...[
                  ChoiceChip(
                    label: Text(n),
                    selected: _f == i,
                    onSelected: (_) => setState(() => _f = i),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: Text('No hay alumnos con ese filtro')),
            ),
          for (final a in lista)
            Builder(builder: (_) {
              final h = s.horasAlumno(a);
              final completo = h >= metaHoras;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.background,
                        child: Text(iniciales(a.nombre, a.apellidoPaterno),
                            style: const TextStyle(
                                color: AppColors.navy, fontWeight: FontWeight.bold)),
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
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (h / metaHoras).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.background,
                                color: completo ? AppColors.teal : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$h / $metaHoras h',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: completo ? AppColors.teal : Colors.black87)),
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

class InstructorsScreen extends StatelessWidget {
  const InstructorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SubScaffold(
      title: 'Instructores',
      fallback: '/admin/profile',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('${s.instructores.length} instructores activos',
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 10),
                for (final i in s.instructores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Text(iniciales(i.nombre, i.apellidoPaterno),
                                style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i.nombreCompleto,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    '${i.especialidad} · ${s.alumnosDeInstructor(i.id)} alumnos',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/admin/instructors/new'),
              icon: const Icon(Icons.add),
              label: const Text('Agregar instructor'),
            ),
          ),
        ],
      ),
    );
  }
}

class NewInstructorScreen extends StatefulWidget {
  const NewInstructorScreen({super.key});
  @override
  State<NewInstructorScreen> createState() => _NewInstructorScreenState();
}

class _NewInstructorScreenState extends State<NewInstructorScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _pat = TextEditingController();
  final _mat = TextEditingController();
  final _correo = TextEditingController();
  final _esp = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nombre, _pat, _mat, _correo, _esp]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  void _save() {
    if (!_form.currentState!.validate()) return;
    final msg = ScaffoldMessenger.of(context);
    context.read<AppState>().agregarInstructor(
          nombre: _nombre.text,
          paterno: _pat.text,
          materno: _mat.text,
          correo: _correo.text,
          especialidad: _esp.text,
        );
    context.pop();
    msg.showSnackBar(const SnackBar(content: Text('Instructor agregado')));
  }

  @override
  Widget build(BuildContext context) => SubScaffold(
        title: 'Agregar instructor',
        fallback: '/admin/instructors',
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _label('Nombre(s)'),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
                validator: _req,
              ),
              _label('Apellido paterno'),
              TextFormField(
                controller: _pat,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                validator: _req,
              ),
              _label('Apellido materno (opcional)'),
              TextFormField(
                controller: _mat,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
              ),
              _label('Correo institucional'),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.email)),
                validator: (v) =>
                    (v ?? '').trim().toLowerCase().endsWith('@utng.edu.mx')
                        ? null
                        : 'Usa un correo @utng.edu.mx',
              ),
              _label('Especialidad'),
              TextFormField(
                controller: _esp,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.sports)),
                validator: _req,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Guardar instructor')),
            ],
          ),
        ),
      );
}