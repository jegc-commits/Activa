import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../datos/almacen_cuentas.dart';
import '../../../datos/estado_app.dart';
import '../../../modelos/usuario.dart';
import '../../../nucleo/componentes/avisos.dart';
import '../../../nucleo/componentes/dialogo_confirmar.dart';
import '../../../nucleo/componentes/estructura_subpantalla.dart';
import '../../../nucleo/componentes/tarjeta_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../../nucleo/utilidades/formateadores.dart';
import '../../../nucleo/utilidades/reglas_contrasena.dart';
import '../../../nucleo/utilidades/validadores.dart';

// ===================================================================
// LISTA DE ALUMNOS
// ===================================================================
class PantallaAlumnosAdmin extends StatefulWidget {
  const PantallaAlumnosAdmin({super.key});
  @override
  State<PantallaAlumnosAdmin> createState() => _EstadoPantallaAlumnosAdmin();
}

class _EstadoPantallaAlumnosAdmin extends State<PantallaAlumnosAdmin> {
  final _search = TextEditingController();
  int _f = 0; // 0 todos, 1 con sesiones, 2 sin sesiones
  String? _grupoFiltro;
  String? _carreraFiltro;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _cambiarEstado(Alumno a) async {
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final activar = !a.activo;
    final ok = await confirmarAccion(
      context,
      titulo: activar ? '¿Activar alumno?' : '¿Desactivar alumno?',
      mensaje: activar
          ? '${a.nombreCompleto} podrá iniciar sesión otra vez.'
          : '${a.nombreCompleto} ya no podrá iniciar sesión.',
      textoConfirmar: activar ? 'Activar' : 'Desactivar',
      icono: activar ? Icons.check_circle_outline : Icons.block_rounded,
      peligro: !activar,
    );
    if (!ok) return;
    final error = await s.cambiarActivoAlumno(a.id, activar);
    msg.showSnackBar(
      avisoSnack(
        content: Text(
          error ??
              (activar ? 'Alumno activado' : 'Alumno desactivado'),
        ),
      ),
    );
  }

  Future<void> _restablecer(Alumno a) async {
    final s = context.read<EstadoApp>();
    final ok = await confirmarAccion(
      context,
      titulo: '¿Restablecer contraseña?',
      mensaje:
          'Se creará una contraseña temporal nueva para ${a.nombreCompleto}.',
      textoConfirmar: 'Restablecer',
      icono: Icons.lock_reset_rounded,
      peligro: true,
    );
    if (!ok || !mounted) return;
    final temporal = AlmacenCuentas.generarTemporal();
    final error = await s.restablecerContrasenaAlumno(a.id, temporal);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(avisoSnack(content: Text(error)));
      return;
    }
    await _mostrarContrasenaTemporal(
      context,
      nombre: a.nombreCompleto,
      correo: a.correo,
      contrasena: temporal,
    );
  }

  Future<void> _eliminar(Alumno a) async {
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final ok = await confirmarAccion(
      context,
      titulo: '¿Eliminar alumno?',
      mensaje:
          'Se borrará la cuenta de ${a.nombreCompleto} y sus inscripciones. '
          'Esta acción no se puede deshacer.',
      textoConfirmar: 'Eliminar',
      icono: Icons.delete_outline_rounded,
      peligro: true,
    );
    if (!ok) return;
    final error = await s.eliminarAlumno(a.id);
    msg.showSnackBar(
      avisoSnack(
        content: Text(error ?? 'Alumno eliminado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EstadoApp>();
    final q = _search.text.trim().toLowerCase();
    final todos = s.todosAlumnos;
    final grupos = todos
        .map((a) => a.grupo)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final carreras = todos
        .map((a) => a.carrera)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final lista = todos.where((a) {
      final h = s.horasAlumno(a);
      final ok = switch (_f) {
        1 => h > 0,
        2 => h == 0,
        _ => true,
      };
      final okGrupo = _grupoFiltro == null || a.grupo == _grupoFiltro;
      final okCarrera = _carreraFiltro == null || a.carrera == _carreraFiltro;
      return ok &&
          okGrupo &&
          okCarrera &&
          (a.nombreCompleto.toLowerCase().contains(q) ||
              a.numeroControl.contains(q));
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Alumnos',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ColoresApp.navy,
            ),
          ),
          Text(
            '${s.todosAlumnos.length} alumnos registrados',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
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
                for (final (i, n) in [
                  'Todos',
                  'Con sesiones',
                  'Sin sesiones',
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
                  initialValue: _grupoFiltro,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Grupo'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    for (final g in grupos)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) => setState(() => _grupoFiltro = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _carreraFiltro,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Especialidad'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final c in carreras)
                      DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _carreraFiltro = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: Text('No hay alumnos con ese filtro')),
            ),
          for (final a in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(
                builder: (_) {
                  final h = s.horasAlumno(a);
                  final tieneSesiones = h > 0;
                  return TarjetaApp(
                    onTap: () =>
                        context.push('/admin/alumnos/${a.id}/editar'),
                    child: Row(
                      children: [
                        Opacity(
                          opacity: a.activo ? 1 : 0.45,
                          child: CircleAvatar(
                            backgroundColor: ColoresApp.background,
                            child: Text(
                              iniciales(a.nombre, a.apellidoPaterno),
                              style: const TextStyle(
                                color: ColoresApp.navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.nombreCompleto,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: a.activo ? null : Colors.black45,
                                ),
                              ),
                              Text(
                                '${a.numeroControl} · ${a.grupo}',
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 11,
                                ),
                              ),
                              if (a.carrera.isNotEmpty)
                                Text(
                                  a.carrera,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ColoresApp.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              if (!a.activo)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Desactivado',
                                    style: TextStyle(
                                      color: ColoresApp.danger,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$h ${h == 1 ? 'sesión' : 'sesiones'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: tieneSesiones
                                ? ColoresApp.teal
                                : Colors.black87,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            switch (v) {
                              case 'editar':
                                context.push('/admin/alumnos/${a.id}/editar');
                                break;
                              case 'estado':
                                _cambiarEstado(a);
                                break;
                              case 'contrasena':
                                _restablecer(a);
                                break;
                              case 'eliminar':
                                _eliminar(a);
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'estado',
                              child: Text(a.activo ? 'Desactivar' : 'Activar'),
                            ),
                            const PopupMenuItem(
                              value: 'contrasena',
                              child: Text('Restablecer contraseña'),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/admin/alumnos/nuevo'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Agregar alumno'),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// FORMULARIO DE ALUMNO (crear / editar)
// ===================================================================
class PantallaFormularioAlumno extends StatefulWidget {
  const PantallaFormularioAlumno({super.key, this.alumnoId});

  /// null = crear; con id = editar
  final int? alumnoId;

  @override
  State<PantallaFormularioAlumno> createState() =>
      _EstadoPantallaFormularioAlumno();
}

class _EstadoPantallaFormularioAlumno extends State<PantallaFormularioAlumno> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _pat = TextEditingController();
  final _mat = TextEditingController();
  final _correo = TextEditingController();
  final _control = TextEditingController();
  final _grupo = TextEditingController();
  final _telefono = TextEditingController();
  final _pass = TextEditingController(text: AlmacenCuentas.generarTemporal());

  Alumno? _edit;
  String? _carrera;
  bool _activo = true;
  bool _guardando = false;

  bool get _editando => widget.alumnoId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.alumnoId;
    if (id != null) {
      Alumno? a;
      for (final x in context.read<EstadoApp>().todosAlumnos) {
        if (x.id == id) {
          a = x;
          break;
        }
      }
      _edit = a;
      if (a != null) {
        _nombre.text = a.nombre;
        _pat.text = a.apellidoPaterno;
        _mat.text = a.apellidoMaterno;
        _correo.text = a.correo;
        _control.text = a.numeroControl;
        _grupo.text = a.grupo;
        _telefono.text = a.telefono ?? '';
        _carrera = a.carrera.isEmpty ? null : a.carrera;
        _activo = a.activo;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _pat,
      _mat,
      _correo,
      _control,
      _grupo,
      _telefono,
      _pass,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(avisoSnack(content: Text(t)));

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final n = capitalizar(_nombre.text);
    final p = capitalizar(_pat.text);
    final m = capitalizar(_mat.text);
    final correo = _correo.text.trim().toLowerCase();
    final control = _control.text.trim();
    final grupo = _grupo.text.trim().toUpperCase();
    final telefono = _telefono.text.trim();
    final carrera = (_carrera ?? '').trim();

    final ok = await confirmarAccion(
      context,
      titulo: _editando ? '¿Guardar cambios?' : '¿Agregar alumno?',
      mensaje: _editando
          ? 'Se actualizarán los datos de $n $p.'
          : 'Se dará de alta a $n $p con una contraseña temporal.',
      textoConfirmar: _editando ? 'Guardar' : 'Agregar',
      icono: _editando ? Icons.save_rounded : Icons.person_add_alt_1_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _guardando = true);

    if (!_editando) {
      final error = await s.crearAlumno(
        nombre: n,
        paterno: p,
        materno: m,
        correo: correo,
        numeroControl: control,
        grupo: grupo,
        carrera: carrera,
        telefono: telefono,
        contrasena: _pass.text,
      );
      if (!mounted) return;
      setState(() => _guardando = false);
      if (error != null) {
        _snack(error);
        return;
      }
      await _mostrarContrasenaTemporal(
        context,
        nombre: '$n $p',
        correo: correo,
        contrasena: _pass.text,
      );
      if (!mounted) return;
      router.pop();
      msg.showSnackBar(avisoSnack(content: const Text('Alumno agregado')));
      return;
    }

    final id = widget.alumnoId!;
    final error = await s.editarAlumno(
      id,
      nombre: n,
      paterno: p,
      materno: m,
      correo: correo,
      numeroControl: control,
      grupo: grupo,
      carrera: carrera,
      telefono: telefono,
    );
    var finalError = error;
    if (finalError == null) {
      finalError = await s.cambiarActivoAlumno(id, _activo);
    }
    if (!mounted) return;
    setState(() => _guardando = false);
    if (finalError != null) {
      _snack(finalError);
      return;
    }
    router.pop();
    msg.showSnackBar(avisoSnack(content: const Text('Cambios guardados')));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EstadoApp>();
    if (_editando && _edit == null) {
      return const EstructuraSubpantalla(
        title: 'Editar alumno',
        fallback: '/admin/alumnos',
        child: Center(child: Text('No se encontró al alumno')),
      );
    }

    final especialidades = List<String>.from(s.especialidades);
    if (_carrera != null &&
        _carrera!.isNotEmpty &&
        !especialidades.contains(_carrera)) {
      especialidades.add(_carrera!);
    }

    return EstructuraSubpantalla(
      title: _editando ? 'Editar alumno' : 'Agregar alumno',
      fallback: '/admin/alumnos',
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('Nombre(s)'),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: formatoNombre(),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
              validator: (v) => validarNombre(v, campo: 'El nombre'),
            ),
            _label('Apellido paterno'),
            TextFormField(
              controller: _pat,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: formatoNombre(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => validarNombre(v, campo: 'El apellido'),
            ),
            _label('Apellido materno (opcional)'),
            TextFormField(
              controller: _mat,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: formatoNombre(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  validarNombre(v, campo: 'El apellido', obligatorio: false),
            ),
            _label('Correo institucional'),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email),
                helperText: 'Con este correo inicia sesión',
              ),
              validator: (v) {
                final e = validarCorreoInstitucional(v);
                if (e != null) return e;
                final c = v!.trim().toLowerCase();
                final repetido = s.todosAlumnos.any(
                  (a) => a.id != _edit?.id && a.correo == c,
                );
                return repetido ? 'Ese correo ya está registrado' : null;
              },
            ),
            _label('Número de control'),
            TextFormField(
              controller: _control,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined),
                helperText: 'También sirve para iniciar sesión',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Campo requerido';
                if (t.length < 5) return 'Mínimo 5 dígitos';
                final repetido = s.todosAlumnos.any(
                  (a) => a.id != _edit?.id && a.numeroControl == t,
                );
                return repetido ? 'Ese número de control ya existe' : null;
              },
            ),
            _label('Grupo'),
            TextFormField(
              controller: _grupo,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Campo requerido';
                return null;
              },
            ),
            _label('Especialidad'),
            DropdownButtonFormField<String>(
              initialValue: _carrera,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: [
                for (final e in especialidades)
                  DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _carrera = v),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Elige una especialidad' : null,
            ),
            _label('Teléfono (opcional)'),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            if (!_editando) ...[
              _label('Contraseña'),
              TextFormField(
                controller: _pass,
                autocorrect: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.key_rounded),
                  helperText:
                      'Se la das al alumno; puede cambiarla desde su perfil',
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    tooltip: 'Generar otra',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => setState(
                      () => _pass.text = AlmacenCuentas.generarTemporal(),
                    ),
                  ),
                ),
                validator: (v) => ReglasContrasena(v ?? '').valid
                    ? null
                    : 'Mínimo 8 caracteres, una mayúscula y un número',
              ),
            ],
            if (_editando) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
                title: const Text(
                  'Alumno activo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Si lo desactivas ya no podrá iniciar sesión',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(
                _editando ? 'Guardar cambios' : 'Guardar alumno',
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ventanita que muestra la contraseña temporal para dársela al alumno
Future<void> _mostrarContrasenaTemporal(
  BuildContext context, {
  required String nombre,
  required String correo,
  required String contrasena,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'Contraseña temporal',
        style: TextStyle(fontWeight: FontWeight.w800, color: ColoresApp.navy),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Entrégasela a $nombre. Entra con:'),
          const SizedBox(height: 10),
          Text('Correo: $correo', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColoresApp.mist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              contrasena,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Después de cerrar esta ventana ya no se podrá volver a ver.',
            style: TextStyle(fontSize: 12, color: ColoresApp.muted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: contrasena)),
          child: const Text('Copiar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Listo'),
        ),
      ],
    ),
  );
}
