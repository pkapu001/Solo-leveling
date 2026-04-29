import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/xp_config.dart';

class LevelBadge extends StatelessWidget {
  final int level;
  final double size;

  const LevelBadge({super.key, required this.level, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final rank = rankForLevel(level);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexPainter(
          borderColor: rank.color,
          fillColor: AppColors.surface,
        ),
        child: Center(
          child: Text(
            level.toString(),
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: size * 0.32,
              fontWeight: FontWeight.w700,
              color: rank.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  _HexPainter({required this.borderColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) * 0.88;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * (math.pi / 180);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Glow effect
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor.withValues(alpha: 0.3)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(_HexPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.fillColor != fillColor;
}
