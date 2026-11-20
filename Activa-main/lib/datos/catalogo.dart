// ===================================================================
// catalogo.dart
// Catálogo base del sistema (categorías de actividades). No son datos
// de ejemplo: son las categorías reales con las que trabaja ACTIVA.
// ===================================================================

import '../modelos/categoria.dart';

const categoriasIniciales = <Categoria>[
  Categoria(
    id: 1,
    clave: 'deportes',
    nombre: 'Deportes',
    etiqueta: 'Deportiva',
    colorValue: 0xFFE08A3C,
    icono: 'deportes',
  ),
  Categoria(
    id: 2,
    clave: 'cultura',
    nombre: 'Cultura',
    etiqueta: 'Cultural',
    colorValue: 0xFFD1457B,
    icono: 'cultura',
  ),
  Categoria(
    id: 3,
    clave: 'recreativa',
    nombre: 'Recreativa',
    etiqueta: 'Recreativa',
    colorValue: 0xFF6C4FD1,
    icono: 'recreativa',
  ),
  Categoria(
    id: 4,
    clave: 'otros',
    nombre: 'Otros',
    etiqueta: 'Otra',
    colorValue: 0xFF3C8DE0,
    icono: 'otros',
  ),
];
