// ===================================================================
// pantallas_admin_extra.dart
// pantallas del perfil del admin que decian "proximamente":
// periodo escolar, validacion de horas y avisos generales
// ===================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../datos/estado_app.dart';
import '../../../datos/constantes_app.dart';
import '../../../modelos/categoria.dart';
import '../../../modelos/enums.dart';
import '../../../nucleo/componentes/avisos.dart';
import '../../../nucleo/componentes/boton_activa.dart';
import '../../../nucleo/componentes/dialogo_confirmar.dart';
import '../../../nucleo/componentes/estructura_subpantalla.dart';
import '../../../nucleo/componentes/tarjeta_app.dart';
import '../../../nucleo/tema/tema_app.dart';
import '../../../nucleo/utilidades/formateadores.dart';

// ───────────────────── periodo escolar ─────────────────────
class PantallaPeriodoEscolar extends StatefulWidget {
  const PantallaPeriodoEscolar({super.key});
  @override
  State<PantallaPeriodoEscolar> createState() => _EstadoPeriodoEscolar();
}

class _EstadoPeriodoEscolar extends State<PantallaPeriodoEscolar> {
  bool _inscripcionesAbiertas = true; // interruptor de inscripciones
  bool _bajasAbiertas = true;

  Widget _fila(IconData icono, String titulo, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icono, color: ColoresApp.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(valor, style: const TextStyle(color: ColoresApp.muted)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return EstructuraSubpantalla(
      title: 'Periodo escolar',
      fallback: '/admin/perfil',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TarjetaApp(
            child: Column(
              children: [
                _fila(Icons.calendar_today, 'Periodo', periodoActual),
                const Divider(height: 1),
                _fila(
                  Icons.groups,
                  'Talleres',
                  '${context.watch<EstadoApp>().talleres.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TarjetaApp(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.how_to_reg,
                    color: ColoresApp.primary,
                  ),
                  title: const Text(
                    'Inscripciones abiertas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  value: _inscripcionesAbiertas,
                  onChanged: (v) => setState(() => _inscripcionesAbiertas = v),
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.exit_to_app,
                    color: ColoresApp.primary,
                  ),
                  title: const Text(
                    'Permitir bajas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  value: _bajasAbiertas,
                  onChanged: (v) => setState(() => _bajasAbiertas = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BotonActiva(
            etiqueta: 'Guardar periodo',
            alPresionar: () => ScaffoldMessenger.of(context).showSnackBar(
              avisoSnack(content: const Text('Periodo actualizado')),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── especialidades (registro de alumno) ─────────────────────
class PantallaEspecialidades extends StatefulWidget {
  const PantallaEspecialidades({super.key});
  @override
  State<PantallaEspecialidades> createState() => _EstadoEspecialidades();
}

class _EstadoEspecialidades extends State<PantallaEspecialidades> {
  final _nueva = TextEditingController();

  @override
  void dispose() {
    _nueva.dispose();
    super.dispose();
  }

  void _agregar() {
    final texto = _nueva.text.trim();
    if (texto.isEmpty) return;
    final agregada = context.read<EstadoApp>().agregarEspecialidad(texto);
    if (!agregada) {
      ScaffoldMessenger.of(context).showSnackBar(
        avisoSnack(content: const Text('Esa especialidad ya está en la lista')),
      );
      return;
    }
    _nueva.clear();
  }

  void _eliminar(String nombre) {
    context.read<EstadoApp>().eliminarEspecialidad(nombre);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(avisoSnack(content: Text('Se quitó "$nombre"')));
  }

  Future<void> _editar(String nombre) async {
    final ctrl = TextEditingController(text: nombre);
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Editar especialidad',
          style: TextStyle(fontWeight: FontWeight.w800, color: ColoresApp.navy),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (nuevo == null || nuevo.isEmpty || nuevo == nombre) return;
    final error = await s.editarEspecialidad(nombre, nuevo);
    msg.showSnackBar(
      avisoSnack(content: Text(error ?? 'Especialidad actualizada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final especialidades = context.watch<EstadoApp>().especialidades;
    return EstructuraSubpantalla(
      title: 'Especialidades',
      fallback: '/admin/perfil',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Son las opciones que ven los alumnos al registrarse, en el '
            'campo "Especialidad".',
            style: TextStyle(color: ColoresApp.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TarjetaApp(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nueva,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Nueva especialidad',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _agregar(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: ColoresApp.primary),
                  onPressed: _agregar,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (especialidades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay especialidades todavía',
                  style: TextStyle(color: ColoresApp.muted),
                ),
              ),
            )
          else
            TarjetaApp(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final e in especialidades) ...[
                    ListTile(
                      leading: const Icon(
                        Icons.school_outlined,
                        color: ColoresApp.primary,
                      ),
                      title: Text(e),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: ColoresApp.primary,
                            ),
                            onPressed: () => _editar(e),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: ColoresApp.danger,
                            ),
                            onPressed: () => _eliminar(e),
                          ),
                        ],
                      ),
                    ),
                    if (e != especialidades.last) const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────── avisos generales ─────────────────────
class PantallaAvisosGenerales extends StatelessWidget {
  const PantallaAvisosGenerales({super.key});

  // hoja de abajo para escribir un aviso nuevo
  void _nuevo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider<EstadoApp>.value(
        value: context.read<EstadoApp>(),
        child: const _HojaNuevoAviso(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EstadoApp>();
    final avisos = s.avisos;
    return EstructuraSubpantalla(
      title: 'Avisos generales',
      fallback: '/admin/perfil',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          BotonActiva(
            etiqueta: 'Nuevo aviso',
            icono: Icons.add_rounded,
            alPresionar: () => _nuevo(context),
          ),
          const SizedBox(height: 16),
          for (final a in avisos) ...[
            TarjetaApp(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: Text(a.tipo.etiqueta)),
                      const Spacer(),
                      Text(
                        tiempoRelativo(a.fecha),
                        style: const TextStyle(
                          color: ColoresApp.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    a.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ColoresApp.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(a.mensaje, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  // Si el aviso no tiene taller (es global), muestra "Aviso general"
                  Text(
                    a.tallerId == null
                        ? 'Aviso general'
                        : s.tallerPorId(a.tallerId!).nombre,
                    style: const TextStyle(
                      color: ColoresApp.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _HojaNuevoAviso extends StatefulWidget {
  const _HojaNuevoAviso();
  @override
  State<_HojaNuevoAviso> createState() => _EstadoHojaNuevoAviso();
}

class _EstadoHojaNuevoAviso extends State<_HojaNuevoAviso> {
  final _titulo = TextEditingController();
  final _mensaje = TextEditingController();
  int? _tallerId;

  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  void _publicar() {
    // Solo validamos que el título y el mensaje no estén vacíos.
    // El taller ahora es opcional.
    if (_titulo.text.trim().isEmpty || _mensaje.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        avisoSnack(
          content: const Text('El título y el mensaje son obligatorios'),
        ),
      );
      return;
    }

    context.read<EstadoApp>().publicarAviso(
      tallerId: _tallerId, // Acepta null si es aviso general
      tipo: TipoAviso.informativo,
      titulo: _titulo.text,
      mensaje: _mensaje.text,
    );
    final m = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    m.showSnackBar(avisoSnack(content: const Text('Aviso publicado')));
  }

  @override
  Widget build(BuildContext context) {
    final talleres = context.read<EstadoApp>().talleres;
    return Padding(
      // sube la hoja cuando sale el teclado
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo aviso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ColoresApp.navy,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _tallerId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.campaign_rounded),
                labelText: 'Taller (Opcional)',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos (Aviso general)'),
                ),
                for (final t in talleres)
                  DropdownMenuItem<int?>(value: t.id, child: Text(t.nombre)),
              ],
              onChanged: (v) => setState(() => _tallerId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titulo,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.title),
                hintText: 'Título',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mensaje,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Mensaje'),
            ),
            const SizedBox(height: 18),
            BotonActiva(etiqueta: 'Publicar aviso', alPresionar: _publicar),
          ],
        ),
      ),
    );
  }
}
// ───────────────────── categorías de talleres ─────────────────────
const _coloresCategoria = <({String nombre, int valor})>[
  (nombre: 'Naranja', valor: 0xFFE08A3C),
  (nombre: 'Rosa', valor: 0xFFD1457B),
  (nombre: 'Morado', valor: 0xFF6C4FD1),
  (nombre: 'Azul', valor: 0xFF3C8DE0),
  (nombre: 'Verde', valor: 0xFF2E9E6B),
  (nombre: 'Rojo', valor: 0xFFD64545),
  (nombre: 'Amarillo', valor: 0xFFC9A227),
];

String _claveCategoria(String texto) {
  const acentos = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  final limpio = texto
      .toLowerCase()
      .split('')
      .map((c) => acentos[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return limpio.isEmpty ? 'categoria' : limpio;
}

class PantallaCategorias extends StatefulWidget {
  const PantallaCategorias({super.key});
  @override
  State<PantallaCategorias> createState() => _EstadoPantallaCategorias();
}

class _EstadoPantallaCategorias extends State<PantallaCategorias> {
  Future<void> _abrirFormulario({Categoria? actual}) async {
    final nombre = TextEditingController(text: actual?.nombre ?? '');
    final etiqueta = TextEditingController(text: actual?.etiqueta ?? '');
    final clave = TextEditingController(text: actual?.clave ?? '');
    var color = actual?.colorValue ?? _coloresCategoria.first.valor;
    var icono = actual?.icono ?? kIconos.keys.first;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            actual == null ? 'Nueva categoría' : 'Editar categoría',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: ColoresApp.navy,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombre,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Deportes',
                  ),
                  onChanged: (v) {
                    if (actual == null) clave.text = _claveCategoria(v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: etiqueta,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta',
                    hintText: 'Ej. Deportiva',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clave,
                  decoration: const InputDecoration(
                    labelText: 'Clave (para filtros)',
                    hintText: 'deportes',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: color,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Color'),
                  items: [
                    for (final c in _coloresCategoria)
                      DropdownMenuItem(
                        value: c.valor,
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Color(c.valor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c.nombre),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => color = v ?? color),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: icono,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ícono'),
                  items: [
                    for (final e in kIconos.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Row(
                          children: [
                            Icon(e.value, size: 20),
                            const SizedBox(width: 8),
                            Text(e.key),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => icono = v ?? icono),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nombre.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(actual == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    if (guardar != true) {
      nombre.dispose();
      etiqueta.dispose();
      clave.dispose();
      return;
    }

    final n = nombre.text.trim();
    final et = etiqueta.text.trim();
    final cl = _claveCategoria(
      clave.text.trim().isEmpty ? n : clave.text.trim(),
    );
    nombre.dispose();
    etiqueta.dispose();
    clave.dispose();

    if (!mounted) return;
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final cat = Categoria(
      id: actual?.id ?? 0,
      clave: cl,
      nombre: n,
      etiqueta: et.isEmpty ? n : et,
      colorValue: color,
      icono: icono,
      activa: true,
    );
    if (actual == null) {
      final creada = await s.agregarCategoria(cat);
      msg.showSnackBar(
        avisoSnack(
          content: Text(
            creada == null
                ? 'No se pudo crear la categoría'
                : 'Categoría agregada',
          ),
        ),
      );
    } else {
      final error = await s.editarCategoria(cat);
      msg.showSnackBar(
        avisoSnack(content: Text(error ?? 'Categoría actualizada')),
      );
    }
  }

  Future<void> _eliminar(Categoria c) async {
    final s = context.read<EstadoApp>();
    final msg = ScaffoldMessenger.of(context);
    final ok = await confirmarAccion(
      context,
      titulo: '¿Eliminar categoría?',
      mensaje:
          'Se quitará "${c.nombre}". Si hay talleres con esta categoría, '
          'se ocultará pero no se borrarán los talleres.',
      textoConfirmar: 'Eliminar',
      icono: Icons.delete_outline_rounded,
      peligro: true,
    );
    if (!ok) return;
    final error = await s.eliminarCategoria(c.id);
    msg.showSnackBar(
      avisoSnack(content: Text(error ?? 'Categoría eliminada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<EstadoApp>().categorias;
    return EstructuraSubpantalla(
      title: 'Categorías',
      fallback: '/admin/perfil',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Las categorías agrupan los talleres (Deportes, Cultura, etc.) '
            'y son las que ven los alumnos al explorar.',
            style: TextStyle(color: ColoresApp.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (cats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay categorías todavía',
                  style: TextStyle(color: ColoresApp.muted),
                ),
              ),
            )
          else
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TarjetaApp(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: c.color,
                      child: Icon(iconoDe(c.icono), color: Colors.white),
                    ),
                    title: Text(
                      c.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${c.etiqueta} · ${c.clave}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: ColoresApp.primary,
                          ),
                          onPressed: () => _abrirFormulario(actual: c),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: ColoresApp.danger,
                          ),
                          onPressed: () => _eliminar(c),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar categoría'),
          ),
        ],
      ),
    );
  }
}
