// ===================================================================
// catalogo.dart
// Catálogo base del sistema (categorías de actividades y especialidades
// de alumno). No son datos de ejemplo: son los valores reales con los
// que arranca ACTIVA; el admin puede agregar o quitar especialidades
// después desde la app.
// ===================================================================

import '../modelos/categoria.dart';

/// Especialidades con las que arranca la app. El admin puede agregar o
/// eliminar especialidades desde la pantalla de Especialidades; esto
/// solo define con qué empieza una base de datos nueva.
const especialidadesIniciales = <String>[
  'Administración de Recursos Humanos',
  'Contabilidad',
  'Electricidad',
  'Logística',
  'Mecánica Industrial',
  'Programación',
  'Soporte y Mantenimiento de Equipo de Cómputo',
];

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