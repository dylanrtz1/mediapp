import 'dart:math';
import 'package:flutter/material.dart';

/// Un CustomPainter que dibuja un fondo animado de partículas suaves.
///
/// Este pintor es reutilizable y se controla mediante un [AnimationController]
/// para crear un efecto de movimiento infinito y elegante.
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  // El constructor requiere la animación que controlará el movimiento.
  BackgroundPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // --- CORRECCIÓN: Nueva paleta de colores azules y celestes ---
    // He reemplazado los tonos dorados por esta nueva paleta.

    final colors = [
      const Color(0xFF81D4FA).withOpacity(0.2), // Celeste (Light Blue)
      const Color(0xFF42A5F5).withOpacity(0.3), // Azul medio (Medium Blue)
      const Color(0xFF1976D2).withOpacity(0.2), // Azul más oscuro (Darker Blue)
    ];

    // Dibuja un color de fondo base para toda la pantalla.
    // Cambiado a blanco puro para un look más limpio con los azules.
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Dibuja 20 partículas en posiciones calculadas y animadas.
    for (int i = 0; i < 20; i++) {
      final paint = Paint()..color = colors[i % colors.length];

      // La lógica del movimiento de las partículas se mantiene igual.
      final dx = (sin(animation.value * 2 * pi + i * 0.5) * (size.width * 0.4)) + (size.width / 2) + (i * 20 - 200);
      final dy = (cos(animation.value * 2 * pi + i * 0.8) * (size.height * 0.4)) + (size.height / 2) + (i * 10 - 100);
      final radius = 20 + (i * 5); // Cada partícula tiene un radio diferente.

      canvas.drawCircle(Offset(dx, dy), radius.toDouble(), paint);
    }
  }

  // Siempre debe redibujar para que la animación sea visible.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

