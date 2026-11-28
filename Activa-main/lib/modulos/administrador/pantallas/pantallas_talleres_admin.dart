import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/tema/tema_app.dart';
import '../../../nucleo/componentes/tarjeta_app.dart';
import '../../../nucleo/componentes/estructura_subpantalla.dart';
import '../../../datos/estado_app.dart';
import '../../../modelos/enums.dart';
import '../../../modelos/taller.dart';
import '../../alumno/componentes/miniatura_taller.dart';
import '../../../nucleo/componentes/avisos.dart';

import '../../../nucleo/componentes/dialogo_confirmar.dart';

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

// ───────────────── Lista ─────────────────
class PantallaTalleresAdmin extends StatefulWidget {
  const PantallaTalleresAdmin({super.key});
  @override
  State<PantallaTalleresAdmin> createState() =>
      _EstadoPantallaActividadesAdmin();
}

class _EstadoPantallaActividadesAdmin extends State<PantallaTalleresAdmin> {
  final _search = TextEditingController();
  int _f = 0; // 0 todas, 1 activas, 2 llenas, 3 inactivas
  String? _catFiltro; // clave de categoría, null = todas
  int? _instructorFiltro; // id de instructor, null = todos

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(avisoSnack(content: Text(m)));

  Future<void> _alternarActivo(Taller t) async {
    final nuevo = !t.activo;
    final ok = await confirmarAccion(
      context,
      titulo: nuevo ? '¿Reactivar taller?' : '¿Desactivar taller?',
      mensaje: nuevo
          ? '${t.nombre} volverá a estar visible para los alumnos.'
          : '${t.nombre} dejará de mostrarse a los alumnos. '
                'Podrás reactivarlo cuando quieras.',
      textoConfirmar: nuevo ? 'Reactivar' : 'Desactivar',
      icono: nuevo ? Icons.visibility_rounded : Icons.visibility_off_rounded,
    );
    if (!ok || !mounted) return;
    final err = await context.read<EstadoApp>().cambiarActivoTaller(
      t.id,
      nuevo,
    );
    if (!mounted) return;
    _snack(err ?? (nuevo ? 'Taller reactivado' : 'Taller desactivado'));
  }

  Future<void> _eliminar(Taller t) async {
    final ok = await confirmarAccion(
      context,
      titulo: '¿Eliminar taller?',
      mensaje:
          'Se eliminará ${t.nombre} con su historial. Esta acción no se '
          'puede deshacer.',
      textoConfirmar: 'Eliminar',
      icono: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    final err = await context.read<EstadoApp>().eliminarTaller(t.id);
    if (!mounted) return;
    _snack(err ?? 'Taller eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EstadoApp>();
    final q = _search.text.trim().toLowerCase();
    final lista = s.talleres.where((t) {
      final ok = switch (_f) {
        1 => t.activo,
        2 => !t.hayCupo,
        3 => !t.activo,
        _ => true,
      };
      final okCat = _catFiltro == null || t.categoria.clave == _catFiltro;
      final okInstructor =
          _instructorFiltro == null || t.instructor.id == _instructorFiltro;
      final okBusqueda =
          q.isEmpty ||
          t.nombre.toLowerCase().contains(q) ||
          t.lugar.toLowerCase().contains(q);
      return ok && okCat && okInstructor && okBusqueda;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/taller/nuevo'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo taller'),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          children: [
            const Text(
              'Talleres',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: ColoresApp.navy,
              ),
            ),
            Text(
              '${s.talleres.length} talleres registrados',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre o lugar',
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, n) in [
                    'Todas',
                    'Activas',
                    'Llenas',
                    'Inactivas',
                  ].indexed) ...[
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _catFiltro,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      for (final c in s.categorias)
                        DropdownMenuItem(value: c.clave, child: Text(c.nombre)),
                    ],
                    onChanged: (v) => setState(() => _catFiltro = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _instructorFiltro,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Instructor'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (final i in s.instructores)
                        DropdownMenuItem(
                          value: i.id,
                          child: Text(
                            i.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _instructorFiltro = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('No hay talleres')),
              ),
            for (final t in lista)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Opacity(
                  opacity: t.activo ? 1 : 0.6,
                  child: TarjetaApp(
                    onTap: () => context.push('/taller/${t.id}'),
                    child: Row(
                      children: [
                        MiniaturaTaller(t, size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: [
                                  _Etiqueta(
                                    t.categoria.etiqueta,
                                    ColoresApp.primary,
                                  ),
                                  _Etiqueta(
                                    t.activo ? 'Activa' : 'Inactiva',
                                    t.activo ? ColoresApp.teal : Colors.black45,
                                  ),
                                  if (!t.hayCupo)
                                    const _Etiqueta(
                                      'Cupo lleno',
                                      ColoresApp.danger,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t.instructor.nombreCompleto} · ${t.inscritos}/${t.cupoMaximo}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: ColoresApp.primary,
                          ),
                          onSelected: (v) {
                            switch (v) {
                              case 'editar':
                                context.push('/admin/taller/${t.id}/editar');
                              case 'activo':
                                _alternarActivo(t);
                              case 'eliminar':
                                _eliminar(t);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit),
                                title: Text('Editar'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'activo',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  t.activo
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                title: Text(
                                  t.activo ? 'Desactivar' : 'Reactivar',
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.delete_outline_rounded,
                                  color: ColoresApp.danger,
                                ),
                                title: Text(
                                  'Eliminar',
                                  style: TextStyle(color: ColoresApp.danger),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── Formulario (2 pasos) ─────────────────
class PantallaFormularioActividad extends StatefulWidget {
  const PantallaFormularioActividad({super.key, this.tallerId});
  final int? tallerId; // null = nueva
  @override
  State<PantallaFormularioActividad> createState() =>
      _EstadoPantallaFormularioActividad();
}

class _EstadoPantallaFormularioActividad
    extends State<PantallaFormularioActividad> {
  final _form1 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();
  late final Taller? _edit;
  late final TextEditingController _nombre, _desc, _lugar, _cupo;
  String? _cat; // clave de categoría
  int? _instId;
  final Set<Dia> _dias = {};
  late TimeOfDay _ini, _fin;
  Uint8List? _foto; // foto de la actividad (opcional)
  bool _activo = true;
  int _step = 0;

  static TimeOfDay _parse(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final s = context.read<EstadoApp>();
    _edit = widget.tallerId == null ? null : s.tallerPorId(widget.tallerId!);
    final t = _edit;
    _nombre = TextEditingController(text: t?.nombre ?? '');
    _desc = TextEditingController(text: t?.descripcion ?? '');
    _lugar = TextEditingController(text: t?.lugar ?? '');
    _cupo = TextEditingController(text: t == null ? '' : '${t.cupoMaximo}');
    _cat = t?.categoria.clave;
    _instId = t?.instructor.id;
    if (t != null) _dias.addAll(t.horarios.map((h) => h.dia));
    _ini = _parse(
      (t != null && t.horarios.isNotEmpty)
          ? t.horarios.first.horaInicio
          : '17:00',
    );
    _fin = _parse(
      (t != null && t.horarios.isNotEmpty) ? t.horarios.first.horaFin : '18:30',
    );
    _activo = t?.activo ?? true;
    _foto = t?.foto;
  }

  @override
  void dispose() {
    for (final c in [_nombre, _desc, _lugar, _cupo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(avisoSnack(content: Text(m)));

  Future<void> _elegirFoto() async {
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (fuente == null) return;
    try {
      final x = await ImagePicker().pickImage(
        source: fuente,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (x == null) return;
      final b = await x.readAsBytes();
      if (mounted) setState(() => _foto = b);
    } catch (_) {
      if (mounted) _snack('No se pudo abrir la foto');
    }
  }

  Future<void> _pick(bool inicio) async {
    final r = await showTimePicker(
      context: context,
      initialTime: inicio ? _ini : _fin,
    );
    if (r == null) return;
    setState(() {
      if (inicio) {
        _ini = r;
      } else {
        _fin = r;
      }
    });
  }

  bool _mismos(List<Horario> a, List<Horario> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].dia != b[i].dia ||
          a[i].horaInicio != b[i].horaInicio ||
          a[i].horaFin != b[i].horaFin) {
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (_form1.currentState!.validate()) setState(() => _step = 1);
  }

  Future<void> _save() async {
    if (!_form2.currentState!.validate()) return;
    if (_dias.isEmpty) {
      _snack('Selecciona al menos un día');
      return;
    }
    if (_fin.hour * 60 + _fin.minute <= _ini.hour * 60 + _ini.minute) {
      _snack('La hora de fin debe ser mayor a la de inicio');
      return;
    }
    final s = context.read<EstadoApp>();
    final inst = s.instructores.firstWhere((i) => i.id == _instId);
    final cat = s.categorias.firstWhere((c) => c.clave == _cat);
    final horarios = [
      for (final d in Dia.values.where(_dias.contains))
        Horario(d, _fmt(_ini), _fmt(_fin)),
    ];
    final base = _edit;
    final cupo = int.parse(_cupo.text);
    // "Horas que otorga" ya no se usa en ningún lado: el avance de los
    // alumnos ahora se mide por sesiones asistidas, no por horas. Se deja
    // en 0 para que quede claro que el campo no se usa.
    final t = base == null
        ? Taller(
            id: s.siguienteTallerId,
            nombre: _nombre.text.trim(),
            descripcion: _desc.text.trim(),
            categoria: cat,
            lugar: _lugar.text.trim(),
            cupoMaximo: cupo,
            horasOtorga: 0,
            activo: _activo,
            instructor: inst,
            horarios: horarios,
            inscritos: 0,
            foto: _foto,
          )
        : base.copyWith(
            nombre: _nombre.text.trim(),
            descripcion: _desc.text.trim(),
            categoria: cat,
            lugar: _lugar.text.trim(),
            cupoMaximo: cupo,
            activo: _activo,
            instructor: inst,
            horarios: horarios,
            foto: _foto,
          );

    // Solo validamos traslapes si es nueva o cambió horario, lugar o instructor
    final cambio =
        base == null ||
        base.lugar != t.lugar ||
        base.instructor.id != t.instructor.id ||
        !_mismos(base.horarios, horarios);
    if (cambio && _activo) {
      final c = s.conflictoHorario(t);
      if (c != null) {
        _snack('Traslape: $c');
        return;
      }
    }

    final ok = await confirmarAccion(
      context,
      titulo: base == null ? '¿Crear taller?' : '¿Guardar cambios?',
      mensaje: base == null
          ? 'Se publicará ${t.nombre} para que los alumnos puedan inscribirse.'
          : 'Se actualizará ${t.nombre}.',
      textoConfirmar: base == null ? 'Crear' : 'Guardar',
      icono: Icons.event_available_rounded,
    );
    if (!ok || !mounted) return;

    final guardado = await s.guardarTaller(t);
    if (!mounted) return;
    if (guardado == null) {
      _snack('No se pudo guardar el taller. Revisa la conexión.');
      return;
    }
    final msg = ScaffoldMessenger.of(context);
    context.pop();
    msg.showSnackBar(
      avisoSnack(
        content: Text(base == null ? 'Taller creado' : 'Cambios guardados'),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _stepOne(EstadoApp s) => Form(
    key: _form1,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Foto del taller'),
        GestureDetector(
          onTap: _elegirFoto,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColoresApp.mist,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ColoresApp.line),
              image: _foto == null
                  ? null
                  : DecorationImage(
                      image: MemoryImage(_foto!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: _foto == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: ColoresApp.primary,
                        size: 34,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Toca para agregar una foto',
                        style: TextStyle(color: ColoresApp.muted, fontSize: 12),
                      ),
                    ],
                  )
                : const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: ColoresApp.primary,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        _label('Nombre del taller'),
        TextFormField(
          controller: _nombre,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.star)),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
        _label('Categoría'),
        DropdownButtonFormField<String>(
          initialValue: _cat,
          isExpanded: true,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.category)),
          items: [
            for (final c in s.categorias)
              DropdownMenuItem(value: c.clave, child: Text(c.nombre)),
          ],
          onChanged: (v) => setState(() => _cat = v),
          validator: (v) => v == null ? 'Selecciona una categoría' : null,
        ),
        _label('Instructor'),
        DropdownButtonFormField<int>(
          initialValue: _instId,
          isExpanded: true,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
          hint: const Text('Selecciona un instructor'),
          items: [
            // los instructores desactivados ya no se pueden elegir
            for (final i in s.instructores.where(
              (x) => x.activo || x.id == _instId,
            ))
              DropdownMenuItem(value: i.id, child: Text(i.nombreCompleto)),
          ],
          onChanged: (v) => setState(() => _instId = v),
          validator: (v) => v == null ? 'Selecciona un instructor' : null,
        ),
        _label('Descripción'),
        TextFormField(
          controller: _desc,
          maxLength: 200,
          maxLines: 4,
          decoration: const InputDecoration(),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _next, child: const Text('Continuar')),
      ],
    ),
  );

  Widget _stepTwo() => Form(
    key: _form2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Días de la semana'),
        Wrap(
          spacing: 8,
          children: [
            for (final d in Dia.values)
              FilterChip(
                label: Text(d.corto),
                selected: _dias.contains(d),
                onSelected: (v) =>
                    setState(() => v ? _dias.add(d) : _dias.remove(d)),
              ),
          ],
        ),
        _label('Horario'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => _pick(true),
                icon: const Icon(Icons.access_time, size: 18),
                label: Text('Inicio ${_fmt(_ini)}'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => _pick(false),
                icon: const Icon(Icons.access_time, size: 18),
                label: Text('Fin ${_fmt(_fin)}'),
              ),
            ),
          ],
        ),
        _label('Lugar'),
        TextFormField(
          controller: _lugar,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
        _label('Cupo máximo'),
        TextFormField(
          controller: _cupo,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.groups)),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1) return 'Escribe un número válido';
            final ins = _edit?.inscritos ?? 0;
            if (n < ins) return 'Ya hay $ins inscritos';
            return null;
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Activa y visible para los alumnos'),
          value: _activo,
          onChanged: (v) => setState(() => _activo = v),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Guardar taller'),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text('Regresar'),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EstadoApp>();
    return EstructuraSubpantalla(
      title: _edit == null ? 'Nuevo taller' : 'Editar taller',
      fallback: '/admin/talleres',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              for (var i = 0; i < 2; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? ColoresApp.primary : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          if (_step == 0) _stepOne(s) else _stepTwo(),
        ],
      ),
    );
  }
}