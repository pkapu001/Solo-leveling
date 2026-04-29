import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/achievements.dart';
import '../theme/app_theme.dart';

/// Animated overlay shown when the player earns an achievement.
/// Auto-dismisses after [_kDisplayDuration]; also dismissible by tap.
class AchievementUnlockedOverlay extends StatefulWidget {
  final AchievementDefinition def;
  final VoidCallback onDismiss;

  const AchievementUnlockedOverlay({
    super.key,
    required this.def,
    required this.onDismiss,
  });

  @override
  State<AchievementUnlockedOverlay> createState() =>
      _AchievementUnlockedOverlayState();
}

const Duration _kDisplayDuration = Duration(seconds: 4);
const Duration _kAnimDuration = Duration(milliseconds: 500);

class _AchievementUnlockedOverlayState extends State<AchievementUnlockedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  Timer? _dismissTimer;
  // Guard against double-dismiss (timer fires after user tap).
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _kAnimDuration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_kDisplayDuration, _dismiss);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _dismissTimer?.cancel();
    widget.onDismiss();
  }

  @override
  void didUpdateWidget(AchievementUnlockedOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new achievement was queued while this widget is in the tree.
    // Reset the animation and restart the timer for the new one.
    if (oldWidget.def != widget.def) {
      _dismissed = false;
      _ctrl.forward(from: 0);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      // SizedBox.expand fills the parent Stack space.
      // Positioned.fill only works as a direct Stack child; using it inside
      // a GestureDetector was incorrect.
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Dim background
            Container(color: Colors.black.withValues(alpha: 0.6)),
            // Shimmer particles
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, __) => CustomPaint(
                painter: _AchievementParticlePainter(
                  progress: _ctrl.value,
                  accentColor: context.slColors.accent,
                ),
                size: Size.infinite,
              ),
            ),
            // Card
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Builder(
                        builder: (context) {
                          final colors = context.slColors;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: colors.accent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accentGlow,
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '★  ACHIEVEMENT UNLOCKED  ★',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accent,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.def.emoji,
                                  style: const TextStyle(fontSize: 52),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.def.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.def.description,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (widget.def.xpReward > 0) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colors.accentDeep
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: colors.accentDark, width: 1),
                                    ),
                                    child: Text(
                                      '✨  +${widget.def.xpReward} XP',
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Text(
                                  'Tap anywhere to continue',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
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
// Simple golden particle shimmer for the achievement popup
// ---------------------------------------------------------------------------
class _AchievementParticlePainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  static final List<_Pt> _pts = _generate();

  _AchievementParticlePainter({
    required this.progress,
    required this.accentColor,
  });

  static List<_Pt> _generate() {
    final rng = Random(7);
    return List.generate(
        24,
        (_) => _Pt(
              x: rng.nextDouble(),
              y: 0.3 + rng.nextDouble() * 0.7,
              spd: 0.3 + rng.nextDouble() * 0.7,
              r: 1.5 + rng.nextDouble() * 2.5,
              op: 0.25 + rng.nextDouble() * 0.45,
            ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pts) {
      final t = (progress * p.spd) % 1.0;
      final y = (p.y - t * p.y) * size.height;
      final x =
          p.x * size.width + sin(progress * 2 * pi * p.spd + p.x * 8) * 14;
      final opacity = p.op * (1.0 - t);
      if (opacity <= 0) continue;
      canvas.drawCircle(
        Offset(x, y),
        p.r,
        Paint()
          ..color = accentColor.withValues(alpha: opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_AchievementParticlePainter old) =>
      old.progress != progress;
}

class _Pt {
  final double x, y, spd, r, op;
  const _Pt({
    required this.x,
    required this.y,
    required this.spd,
    required this.r,
    required this.op,
  });
}
