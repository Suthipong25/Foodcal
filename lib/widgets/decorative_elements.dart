import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

class LeafDecoration extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;
  final double angle;

  const LeafDecoration({
    super.key,
    required this.alignment,
    this.color = AppTheme.leafGreen,
    this.size = 60,
    this.opacity = 0.15,
    this.angle = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment.y < 0 ? -size * 0.34 : null,
      right: alignment.x > 0 ? -size * 0.34 : null,
      bottom: alignment.y > 0 ? -size * 0.34 : null,
      left: alignment.x < 0 ? -size * 0.34 : null,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: size,
            height: size * 1.36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(size),
            ),
          ),
        ),
      ),
    );
  }
}

class OrganicCircleDecoration extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;

  const OrganicCircleDecoration({
    super.key,
    required this.alignment,
    required this.color,
    this.size = 92,
    this.opacity = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment.y < 0 ? -size * 0.42 : null,
      right: alignment.x > 0 ? -size * 0.38 : null,
      bottom: alignment.y > 0 ? -size * 0.42 : null,
      left: alignment.x < 0 ? -size * 0.38 : null,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class SparkleDecoration extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const SparkleDecoration({
    super.key,
    required this.alignment,
    this.color = AppTheme.aiColor,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment.y < 0 ? -size * 0.15 : null,
      right: alignment.x > 0 ? -size * 0.08 : null,
      bottom: alignment.y > 0 ? -size * 0.15 : null,
      left: alignment.x < 0 ? -size * 0.08 : null,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(size, size),
          painter: _SparklePainter(color),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  const _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.16);
    final centers = [
      Offset(size.width * 0.2, size.height * 0.34),
      Offset(size.width * 0.68, size.height * 0.24),
      Offset(size.width * 0.46, size.height * 0.72),
    ];

    for (final center in centers) {
      final radius = size.shortestSide * 0.08;
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final r = i.isEven ? radius * 1.9 : radius * 0.45;
        final angle = -math.pi / 2 + i * math.pi / 4;
        final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
