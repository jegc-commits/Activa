// ===================================================================
// Cuadrito TallerThumb y banner TallerBanner de cada actividad
// ===================================================================

// Widgets de Flutter
import 'package:flutter/material.dart';
// para usar iconoDe() que convierte la clave en un ícono
import '../../../models/categoria.dart';
// Para saber qué es un taller
import '../../../models/taller.dart';

// cuadrito pequeño con el ícono de la categoría
class TallerThumb extends StatelessWidget {
  const TallerThumb(this.taller, {super.key, this.size = 56});
  // la actividad que se va a dibujar
  final Taller taller;
  // tamaño del cuadrito (ancho y alto)
  final double size;

  @override
  Widget build(BuildContext context) {
    // categoría de la actividad (trae su color y su ícono)
    final c = taller.categoria;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // degradado del color de la categoría a una versión más oscura
        gradient: LinearGradient(
          colors: [c.color, Color.lerp(c.color, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        // Sombra del mismo color de la categoría
        boxShadow: [
          BoxShadow(
            color: c.color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Ícono blanco centrado
      child: Icon(iconoDe(c.icono), color: Colors.white, size: size * 0.5),
    );
  }
}

// banner grande que va arriba de las tarjetas
class TallerBanner extends StatelessWidget {
  const TallerBanner(this.taller, {super.key, this.height = 110, this.child});
  final Taller taller;
  // Alto del banner
  final double height;
  // Widget extra encima (ej. el corazón), debe ser un Positioned
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = taller.categoria;
    return Container(
      height: height,
      width: double.infinity,
      // degradado de fondo
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.color, Color.lerp(c.color, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // stack pone los adornos uno encima del otro
      child: Stack(
        children: [
          // circulo decorativo arriba a la izquierda
          Positioned(
            left: -20,
            top: -24,
            child: _Circulo(size: height * 0.9, alpha: 0.10),
          ),
          // circulo decorativo abajo a la derecha
          Positioned(
            right: -14,
            bottom: -30,
            child: _Circulo(size: height * 0.8, alpha: 0.12),
          ),
          // Ícono grande al centro
          Center(
            child: Icon(
              iconoDe(c.icono),
              size: height * 0.45,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          // Si mandaron un child (el corazón) lo dibuja encima
          if (child != null) child!,
        ],
      ),
    );
  }
}

// cirrculo blanco transparente es solo adorno
class _Circulo extends StatelessWidget {
  const _Circulo({required this.size, required this.alpha});
  // diametro del círculo
  final double size;
  // q tan visible es (0 = invisible, 1 = blanco total)
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}