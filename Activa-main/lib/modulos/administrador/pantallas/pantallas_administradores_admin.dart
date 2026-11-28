import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../datos/almacen_cuentas.dart';
import '../../../datos/estado_app.dart';
import '../../../nucleo/componentes/avisos.dart';
import '../../../nucleo/componentes/dialogo_confirmar.dart';
import '../../../nucleo/componentes/estructura_subpantalla.dart';
import '../../../nucleo/componentes/tarjeta_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../../nucleo/utilidades/formateadores.dart';
import '../../../nucleo/utilidades/reglas_contrasena.dart';
import '../../../nucleo/utilidades/validadores.dart';

// ===================================================================
// LISTA DE ADMINISTRADORES
// ===================================================================
class PantallaAdministradores extends StatefulWidget {
  const PantallaAdministradores({super.key});

  @override
  State<PantallaAdministradores> createState() =>
      _EstadoPantallaAdministradores();
}

class _EstadoPantallaAdministradores extends State<PantallaAdministradores> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Pide la contraseña del admin AFECTADO (no la del que está logueado).
  Future<bool> _pedirContrasena(CuentaGuardada c) async {
    final s = context.read<EstadoApp>();
    final ctrl = TextEditingController();
    String? error;
    bool ver = false;
    bool validando = false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            'Confirmar con contraseña',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ColoresApp.navy,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Escribe la contraseña de ${c.nombreCompleto}.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: !ver,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  errorText: error,
                  suffixIcon: IconButton(
                    icon: Icon(ver ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => set(() => ver = !ver),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: validando ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: validando
                  ? null
                  : () async {
                      set(() => validando = true);
                      final valida = await s.verificarContrasenaAdministrador(
                        c.id,
                        ctrl.text,
                      );
                      if (!ctx.mounted) return;
                      if (valida) {
                        Navigator.of(ctx).pop(true);
                      } else {
                        set(() {
                          validando = false;
                          error = 'Contraseña incorrecta';
                        });
                      }
                    },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _editar(CuentaGuardada c) async {
    final ok = await _pedirContrasena(c);
    if (!ok || !mounted) return;
    context.push('/admin/administradores/${c.id}/editar');
  }

  Future<void> _cambiarEstado(CuentaGuardada c) async {
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final activar = !c.activo;
    final ok = await confirmarAccion(
      context,
      titulo: activar
          ? '¿Activar administrador?'
          : '¿Desactivar administrador?',
      mensaje: activar
          ? '${c.nombreCompleto} podrá volver a entrar al panel.'
          : '${c.nombreCompleto} ya no podrá entrar al panel.',
      textoConfirmar: activar ? 'Activar' : 'Desactivar',
      icono: activar ? Icons.check_circle_outline : Icons.block_rounded,
      peligro: !activar,
    );
    if (!ok || !mounted) return;
    if (!await _pedirContrasena(c) || !mounted) return;
    final error = await s.cambiarActivoAdministrador(c.id, activar);
    if (!mounted) return;
    msg.showSnackBar(
      avisoSnack(
        content: Text(
          error ??
              (activar
                  ? 'Administrador activado'
                  : 'Administrador desactivado'),
        ),
        tipo: error == null ? TipoToast.exito : TipoToast.error,
      ),
    );
  }

  Future<void> _restablecer(CuentaGuardada c) async {
    final s = context.read<EstadoApp>();
    final ok = await confirmarAccion(
      context,
      titulo: '¿Restablecer contraseña?',
      mensaje:
          'Se creará una contraseña temporal nueva para ${c.nombreCompleto}.',
      textoConfirmar: 'Restablecer',
      icono: Icons.lock_reset_rounded,
      peligro: true,
    );
    if (!ok || !mounted) return;
    if (!await _pedirContrasena(c) || !mounted) return;
    final temporal = AlmacenCuentas.generarTemporal();
    final error = await s.restablecerContrasenaAdministrador(c.id, temporal);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(avisoSnack(content: Text(error), tipo: TipoToast.error));
      return;
    }
    await _mostrarCredenciales(
      context,
      nombre: c.nombreCompleto,
      usuario: c.usuario,
      correo: c.correo,
      contrasena: temporal,
    );
  }

  Future<void> _eliminar(CuentaGuardada c) async {
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final ok = await confirmarAccion(
      context,
      titulo: '¿Eliminar administrador?',
      mensaje:
          'Se borrará la cuenta de ${c.nombreCompleto}. Esta acción no se '
          'puede deshacer.',
      textoConfirmar: 'Eliminar',
      icono: Icons.delete_outline_rounded,
      peligro: true,
    );
    if (!ok || !mounted) return;
    if (!await _pedirContrasena(c) || !mounted) return;
    final error = await s.eliminarAdministrador(c.id);
    if (!mounted) return;
    msg.showSnackBar(
      avisoSnack(
        content: Text(error ?? 'Administrador eliminado'),
        tipo: error == null ? TipoToast.exito : TipoToast.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EstadoApp>();
    final yo = s.admin.id;
    final q = _search.text.trim().toLowerCase();
    final lista = s.administradores.where((c) {
      return q.isEmpty ||
          c.nombreCompleto.toLowerCase().contains(q) ||
          c.correo.toLowerCase().contains(q) ||
          c.usuario.toLowerCase().contains(q);
    }).toList();

    // FIX: Material como ancestro para TextField / ListTile / InkWell.
    return EstructuraSubpantalla(
      title: 'Administradores',
      fallback: '/admin',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Administradores',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ColoresApp.navy,
            ),
          ),
          Text(
            '${s.administradores.length} '
            '${s.administradores.length == 1 ? 'administrador' : 'administradores'} '
            'con acceso al panel',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre, correo o usuario',
            ),
          ),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text('No hay administradores con ese filtro'),
              ),
            ),
          for (final c in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TarjetaApp(
                onTap: () => _editar(c),
                child: Row(
                  children: [
                    Opacity(
                      opacity: c.activo ? 1 : 0.45,
                      child: CircleAvatar(
                        backgroundColor: ColoresApp.background,
                        child: Text(
                          iniciales(c.nombre, c.apellidoPaterno),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  c.nombreCompleto,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: c.activo ? null : Colors.black45,
                                  ),
                                ),
                              ),
                              if (c.id == yo) ...[
                                const SizedBox(width: 6),
                                _chip('Tú', ColoresApp.primary),
                              ],
                            ],
                          ),
                          Text(
                            '@${c.usuario} · ${c.correo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _chip(
                                c.activo ? 'Activo' : 'Desactivado',
                                c.activo ? ColoresApp.teal : ColoresApp.danger,
                              ),
                              if (c.debeCambiarContrasena)
                                _chip(
                                  'Contraseña temporal',
                                  ColoresApp.warning,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'editar':
                            _editar(c);
                            break;
                          case 'estado':
                            _cambiarEstado(c);
                            break;
                          case 'contrasena':
                            _restablecer(c);
                            break;
                          case 'eliminar':
                            _eliminar(c);
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
                          child: Text(c.activo ? 'Desactivar' : 'Activar'),
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
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/admin/administradores/nuevo'),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            label: const Text('Agregar administrador'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

// ===================================================================
// FORMULARIO DE ADMINISTRADOR (crear / editar)
// ===================================================================
class PantallaFormularioAdministrador extends StatefulWidget {
  const PantallaFormularioAdministrador({super.key, this.administradorId});

  /// null = crear; con id = editar
  final int? administradorId;

  @override
  State<PantallaFormularioAdministrador> createState() =>
      _EstadoPantallaFormularioAdministrador();
}

class _EstadoPantallaFormularioAdministrador
    extends State<PantallaFormularioAdministrador> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _pat = TextEditingController();
  final _mat = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _pass = TextEditingController(text: AlmacenCuentas.generarTemporal());

  CuentaGuardada? _edit;
  bool _verPass = false;
  bool _guardando = false;

  bool get _editando => widget.administradorId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.administradorId;
    if (id == null) return;
    for (final c in context.read<EstadoApp>().administradores) {
      if (c.id == id) {
        _edit = c;
        _nombre.text = c.nombre;
        _pat.text = c.apellidoPaterno;
        _mat.text = c.apellidoMaterno;
        _correo.text = c.correo;
        _telefono.text = c.telefono;
        break;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _pat, _mat, _correo, _telefono, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  void _snack(String t, {TipoToast? tipo}) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(avisoSnack(content: Text(t), tipo: tipo));

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final n = capitalizar(_nombre.text);
    final p = capitalizar(_pat.text);
    final m = capitalizar(_mat.text);
    final correo = _correo.text.trim().toLowerCase();
    final telefono = _telefono.text.trim();

    final ok = await confirmarAccion(
      context,
      titulo: _editando ? '¿Guardar cambios?' : '¿Agregar administrador?',
      mensaje: _editando
          ? 'Se actualizarán los datos de $n $p.'
          : 'Se dará acceso al panel a $n $p con una contraseña temporal.',
      textoConfirmar: _editando ? 'Guardar' : 'Agregar',
      icono: _editando
          ? Icons.save_rounded
          : Icons.admin_panel_settings_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _guardando = true);

    if (!_editando) {
      final r = await s.crearAdministrador(
        nombre: n,
        paterno: p,
        materno: m,
        correo: correo,
        telefono: telefono,
        contrasena: _pass.text,
      );
      if (!mounted) return;
      setState(() => _guardando = false);
      if (r.error != null || r.cuenta == null) {
        _snack(r.error ?? 'Error: no se pudo crear el administrador');
        return;
      }
      await _mostrarCredenciales(
        context,
        nombre: '$n $p',
        usuario: r.cuenta!.usuario,
        correo: r.cuenta!.correo,
        contrasena: _pass.text,
      );
      if (!mounted) return;
      router.pop();
      msg.showSnackBar(
        avisoSnack(
          content: const Text('Administrador agregado'),
          tipo: TipoToast.exito,
        ),
      );
      return;
    }

    final error = await s.editarAdministrador(
      widget.administradorId!,
      nombre: n,
      paterno: p,
      materno: m,
      correo: correo,
      telefono: telefono,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      _snack(error, tipo: TipoToast.error);
      return;
    }
    router.pop();
    msg.showSnackBar(
      avisoSnack(
        content: const Text('Cambios guardados'),
        tipo: TipoToast.exito,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_editando && _edit == null) {
      return const EstructuraSubpantalla(
        title: 'Editar administrador',
        fallback: '/admin/administradores',
        child: Center(child: Text('No se encontró al administrador')),
      );
    }

    final reglas = ReglasContrasena(_pass.text);

    return EstructuraSubpantalla(
      title: _editando ? 'Editar administrador' : 'Agregar administrador',
      fallback: '/admin/administradores',
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColoresApp.mist,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: ColoresApp.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Los administradores pueden crear, editar y eliminar '
                      'talleres, alumnos, instructores y catálogos.',
                      style: TextStyle(fontSize: 12, color: ColoresApp.muted),
                    ),
                  ),
                ],
              ),
            ),
            _label('Nombre(s)'),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              inputFormatters: formatoNombre(),
              decoration: const InputDecoration(hintText: 'Ej. María Fernanda'),
              validator: (v) => validarNombre(v, campo: 'El nombre'),
            ),
            _label('Apellido paterno'),
            TextFormField(
              controller: _pat,
              textCapitalization: TextCapitalization.words,
              inputFormatters: formatoNombre(),
              decoration: const InputDecoration(hintText: 'Ej. García'),
              validator: (v) => validarNombre(v, campo: 'El apellido'),
            ),
            _label('Apellido materno (opcional)'),
            TextFormField(
              controller: _mat,
              textCapitalization: TextCapitalization.words,
              inputFormatters: formatoNombre(),
              decoration: const InputDecoration(hintText: 'Ej. López'),
              validator: (v) =>
                  validarNombre(v, campo: 'El apellido', obligatorio: false),
            ),
            _label('Correo electrónico'),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'nombre@correo.com'),
              validator: validarCorreoInstitucional,
            ),
            _label('Teléfono (opcional)'),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '10 dígitos'),
            ),
            if (!_editando) ...[
              _label('Contraseña inicial'),
              TextFormField(
                controller: _pass,
                obscureText: !_verPass,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Mínimo 8 caracteres',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _verPass ? 'Ocultar' : 'Mostrar',
                        icon: Icon(
                          _verPass ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _verPass = !_verPass),
                      ),
                      IconButton(
                        tooltip: 'Generar otra',
                        icon: const Icon(Icons.autorenew_rounded),
                        onPressed: () => setState(() {
                          _pass.text = AlmacenCuentas.generarTemporal();
                          _verPass = true;
                        }),
                      ),
                    ],
                  ),
                ),
                validator: (v) => ReglasContrasena(v ?? '').valid
                    ? null
                    : 'Usa 8+ caracteres, una mayúscula y un número',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: i < reglas.score
                              ? (reglas.score >= 3
                                    ? ColoresApp.teal
                                    : ColoresApp.warning)
                              : ColoresApp.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    reglas.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ColoresApp.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Al entrar por primera vez se le pedirá cambiarla.',
                style: TextStyle(fontSize: 11, color: ColoresApp.muted),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_editando ? Icons.save_rounded : Icons.check_rounded),
              label: Text(
                _guardando
                    ? 'Guardando...'
                    : (_editando ? 'Guardar cambios' : 'Agregar administrador'),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _guardando ? null : () => context.pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Ventanita con los datos de acceso del nuevo administrador.
Future<void> _mostrarCredenciales(
  BuildContext context, {
  required String nombre,
  required String usuario,
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
        'Datos de acceso',
        style: TextStyle(fontWeight: FontWeight.w800, color: ColoresApp.navy),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entrégaselos a $nombre. Puede entrar con el usuario o el correo:',
          ),
          const SizedBox(height: 12),
          _dato('Usuario', usuario),
          const SizedBox(height: 8),
          _dato('Correo', correo),
          const SizedBox(height: 8),
          _dato('Contraseña temporal', contrasena, destacado: true),
          const SizedBox(height: 12),
          const Text(
            'Al iniciar sesión por primera vez se le pedirá crear una '
            'contraseña nueva.',
            style: TextStyle(fontSize: 11, color: ColoresApp.muted),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

Widget _dato(String etiqueta, String valor, {bool destacado = false}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      etiqueta,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ColoresApp.muted,
      ),
    ),
    const SizedBox(height: 3),
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColoresApp.mist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        valor,
        style: TextStyle(
          fontSize: destacado ? 18 : 14,
          fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: destacado ? 1.2 : 0,
        ),
      ),
    ),
  ],
);
