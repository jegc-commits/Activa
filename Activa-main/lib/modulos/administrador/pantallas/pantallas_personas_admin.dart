import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/tema/tema_app.dart';
import '../../../nucleo/utilidades/formateadores.dart';
import '../../../nucleo/componentes/tarjeta_app.dart';
import '../../../datos/estado_app.dart';
import '../../../datos/constantes_app.dart';

class PantallaAlumnosAdmin extends StatefulWidget {
  const PantallaAlumnosAdmin({super.key});
  @override
  State<PantallaAlumnosAdmin> createState() => _EstadoPantallaAlumnosAdmin();
}

class _EstadoPantallaAlumnosAdmin extends State<PantallaAlumnosAdmin> {
  final _search = TextEditingController();
  int _f = 0; // 0 todos, 1 c
  // filtros que pide la "LISTA DE ALUMNOS": grupo y carrera (el estatus ya
  // lo cubren los chips de arriba, y la búsqueda ya cubre nombre/matrícula)
  String? _grupoFiltro;
  String? _carreraFiltro;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EstadoApp>();
    final q = _search.text.trim().toLowerCase();
    final todos = s.todosAlumnos;
    final grupos = todos.map((a) => a.grupo).where((g) => g.isNotEmpty).toSet().toList()
      ..sort();
    final carreras = todos.map((a) => a.carrera).where((c) => c.isNotEmpty).toSet().toList()
      ..sort();
    final lista = todos.where((a) {
      final h = s.horasAlumno(a);
      final ok = switch (_f) {
        1 => h >= metaHoras,
        2 => h > 0 && h < metaHoras,
        3 => h == 0,
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
                  'Con 60 h',
                  'En proceso',
                  'Sin Taller',
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
                  decoration: const InputDecoration(labelText: 'Carrera'),
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
            Builder(
              builder: (_) {
                final h = s.horasAlumno(a);
                final completo = h >= metaHoras;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TarjetaApp(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: ColoresApp.background,
                          child: Text(
                            iniciales(a.nombre, a.apellidoPaterno),
                            style: const TextStyle(
                              color: ColoresApp.navy,
                              fontWeight: FontWeight.bold,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                a.numeroControl,
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (h / metaHoras).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: ColoresApp.background,
                                  color: completo
                                      ? ColoresApp.teal
                                      : ColoresApp.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$h / $metaHoras h',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: completo ? ColoresApp.teal : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
