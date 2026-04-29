import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/xp_config.dart';

/// Full-screen level-up overlay shown when the player levels up.
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _particleCtrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = rankForLevel(widget.newLevel);
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Gold particle shimmer
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    progress: _particleCtrl.value,
                    color: rank.color,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            Positioned.fill(
              child: FadeTransition(
                opacity: _opacity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '⚡ LEVEL UP ⚡',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: context.slColors.accent,
                                  letterSpacing: 4,
                                  shadows: [
                                    Shadow(
                                      color: context.slColors.accent
                                          .withValues(alpha: 0.8),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _GlowingLevelCircle(
                                level: widget.newLevel, color: rank.color),
                            const SizedBox(height: 24),
                            Text(
                              rank.title,
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: rank.color,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The System acknowledges your growth.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Tap anywhere to continue',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingLevelCircle extends StatelessWidget {
  final int level;
  final Color color;

  const _GlowingLevelCircle({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 5),
        ],
      ),
      child: Center(
        child: Text(
          level.toString(),
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Particle painter — floating gold dots for level-up shimmer effect
// ---------------------------------------------------------------------------
class _Particle {
  final double x; // 0.0–1.0 normalized x
  final double startY; // 0.0–1.0 normalized starting y (bottom half)
  final double speed; // relative speed multiplier
  final double size; // dot radius
  final double opacity;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final double progress; // 0.0–1.0 (repeating animation)
  final Color color;

  static final List<_Particle> _particles = _generateParticles();

  _ParticlePainter({required this.progress, required this.color});

  static List<_Particle> _generateParticles() {
    final rng = Random(42); // fixed seed for consistent layout
    return List.generate(40, (i) {
      return _Particle(
        x: rng.nextDouble(),
        startY: 0.4 + rng.nextDouble() * 0.6,
        speed: 0.4 + rng.nextDouble() * 0.6,
        size: 2.0 + rng.nextDouble() * 3.0,
        opacity: 0.3 + rng.nextDouble() * 0.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed) % 1.0;
      // Particles drift upward from their start position
      final y = (p.startY - t * p.startY) * size.height;
      final x =
          p.x * size.width + sin(progress * 2 * pi * p.speed + p.x * 10) * 20;
      final opacity = p.opacity * (1.0 - t); // fade out as they rise

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.color != color;
}
