import 'package:flutter/material.dart';
import '../../../models/categoria.dart';
import '../../../models/taller.dart';

class TallerThumb extends StatelessWidget {
  const TallerThumb(this.taller, {super.key, this.size = 56});
  final Taller taller;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = taller.categoria;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(iconoDe(c.icono), color: Colors.white, size: size * 0.5),
    );
  }
}

class TallerBanner extends StatelessWidget {
  const TallerBanner(this.taller, {super.key, this.height = 110, this.child});
  final Taller taller;
  final double height;
  final Widget? child; // debe ser Positioned (va dentro de un Stack)

  @override
  Widget build(BuildContext context) {
    final c = taller.categoria;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.color, Color.lerp(c.color, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(child: Icon(iconoDe(c.icono), size: height * 0.5, color: Colors.white70)),
          if (child != null) child!,
        ],
      ),
    );
  }
}