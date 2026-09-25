import 'dart:math';
import 'package:flutter/material.dart';
import '../style/app_color.dart';

class GalaxyBackground extends StatefulWidget {
  final Widget child;
  const GalaxyBackground({super.key, required this.child});

  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Base Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: AppColor.backgroundGradient,
          ),
        ),

        // Animated Ambient Glow Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * pi;
            return CustomPaint(
              painter: _AmbientGlowPainter(t),
              child: const SizedBox.expand(),
            );
          },
        ),

        // Subtle Trading Grid Pattern
        CustomPaint(
          painter: _GridBackgroundPainter(),
          child: const SizedBox.expand(),
        ),

        // Child Content
        widget.child,
      ],
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  final double progress;
  _AmbientGlowPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final orb1Center = Offset(
      size.width * 0.2 + cos(progress) * 40,
      size.height * 0.3 + sin(progress) * 30,
    );
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C4DFF).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: 260));
    canvas.drawCircle(orb1Center, 260, orb1Paint);

    final orb2Center = Offset(
      size.width * 0.8 + sin(progress) * 50,
      size.height * 0.7 + cos(progress) * 40,
    );
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: 300));
    canvas.drawCircle(orb2Center, 300, orb2Paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) => true;
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;

    const double step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
