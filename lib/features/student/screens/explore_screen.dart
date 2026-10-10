import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/app_state.dart';

import '../widgets/taller_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialCat});
  final String? initialCat;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}
class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String? _cat; // clave de categoría, null = todas

  @override
  void initState() {
    super.initState();
    _cat = widget.initialCat;
  }

  @override
  void didUpdateWidget(ExploreScreen old) {
    super.didUpdateWidget(old);
    if (old.initialCat != widget.initialCat) {
      setState(() => _cat = widget.initialCat);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
final q = _search.text.trim().toLowerCase();
final lista = state.talleres
    .where((t) =>
        t.activo &&
        (_cat == null || t.categoria.clave == _cat) &&
        t.nombre.toLowerCase().contains(q))
    .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Explorar actividades',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '¿Qué actividad buscas?',
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
  label: const Text('Todas'),
  selected: _cat == null,
  onSelected: (_) => setState(() => _cat = null),
),
for (final c in state.categorias) ...[
  const SizedBox(width: 8),
  ChoiceChip(
    label: Text(c.nombre),
    selected: _cat == c.clave,
    onSelected: (_) => setState(() => _cat = c.clave),
  ),
],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: lista.isEmpty
                  ? const Center(child: Text('No encontramos actividades'))
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisExtent: 268,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => TallerCard(lista[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}