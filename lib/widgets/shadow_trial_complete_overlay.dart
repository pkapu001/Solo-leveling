import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen celebration overlay shown when the player completes a Shadow Trial.
class ShadowTrialCompleteOverlay extends StatefulWidget {
  final String exerciseName;

  /// Bonus volume that was awarded to prereq exercises on this completion.
  /// Null means it was already awarded in a previous session (shouldn't happen
  /// for the first-completion path, but guard regardless).
  final double? bonusVolume;

  final VoidCallback onDismiss;

  const ShadowTrialCompleteOverlay({
    super.key,
    required this.exerciseName,
    required this.bonusVolume,
    required this.onDismiss,
  });

  @override
  State<ShadowTrialCompleteOverlay> createState() =>
      _ShadowTrialCompleteOverlayState();
}

class _ShadowTrialCompleteOverlayState extends State<ShadowTrialCompleteOverlay>
    with TickerProviderStateMixin {
  static const _trialColor = Color(0xFF9C27B0);
  static const _trialColorLight = Color(0xFFCE93D8);

  late AnimationController _mainCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scale = CurvedAnimation(parent: _mainCtrl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _mainCtrl, curve: Curves.easeIn);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _mainCtrl.forward();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.90),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Purple particle shimmer
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) => CustomPaint(
                painter: _TrialParticlePainter(
                  progress: _particleCtrl.value,
                  color: _trialColor,
                ),
                size: Size.infinite,
              ),
            ),
            // Central content
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
                            // Header
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '🌑  SHADOW TRIAL  🌑',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _trialColorLight,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: _trialColor.withValues(alpha: 0.8),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'COMPLETE',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 56,
                                  fontWeight: FontWeight.w800,
                                  color: _trialColorLight,
                                  letterSpacing: 6,
                                  shadows: [
                                    Shadow(
                                      color: _trialColor,
                                      blurRadius: 30,
                                    ),
                                    Shadow(
                                      color: _trialColor.withValues(alpha: 0.4),
                                      blurRadius: 60,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Glowing emblem
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (_, child) => Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  border:
                                      Border.all(color: _trialColor, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _trialColor.withValues(
                                          alpha: 0.3 + _pulse.value * 0.5),
                                      blurRadius: 20 + _pulse.value * 30,
                                      spreadRadius: 2 + _pulse.value * 6,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '⚔',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Exercise name
                            Text(
                              widget.exerciseName,
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _trialColorLight,
                                letterSpacing: 2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The Gate has been cleared.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                            // Bonus volume notice
                            if (widget.bonusVolume != null &&
                                widget.bonusVolume! > 0) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _trialColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _trialColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'UNLOCK PROGRESS AWARDED',
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _trialColorLight,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${widget.bonusVolume!.toStringAsFixed(0)} bonus volume toward unlocking ${widget.exerciseName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 36),
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

// ---------------------------------------------------------------------------
// Purple particle painter for Shadow Trial
// ---------------------------------------------------------------------------
class _TrialParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  static final List<_Particle> _particles = _generateParticles();

  _TrialParticlePainter({required this.progress, required this.color});

  static List<_Particle> _generateParticles() {
    final rng = Random(7); // different seed from level-up
    return List.generate(50, (i) {
      return _Particle(
        x: rng.nextDouble(),
        startY: 0.2 + rng.nextDouble() * 0.8,
        speed: 0.3 + rng.nextDouble() * 0.7,
        size: 1.5 + rng.nextDouble() * 3.5,
        opacity: 0.2 + rng.nextDouble() * 0.6,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed) % 1.0;
      final y = (p.startY - t * p.startY) * size.height;
      final x =
          p.x * size.width + sin(progress * 2 * pi * p.speed + p.x * 8) * 24;
      final opacity = p.opacity * (1.0 - t);

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_TrialParticlePainter old) =>
      old.progress != progress || old.color != color;
}

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double opacity;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}
