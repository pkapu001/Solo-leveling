import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Transient XP-gain popup shown after completing a quest item.
/// Floats up from the center, then fades out automatically.
class XpGainPopup extends StatefulWidget {
  final int xpGained;
  final bool allComplete; // true when all exercises in the quest are done
  final VoidCallback onDone;

  const XpGainPopup({
    super.key,
    required this.xpGained,
    required this.allComplete,
    required this.onDone,
  });

  @override
  State<XpGainPopup> createState() => _XpGainPopupState();
}

class _XpGainPopupState extends State<XpGainPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _rise;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Fade in quickly, hold, then fade out
    _opacity = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 35),
    ]).animate(_ctrl);

    // Rise upward 80 logical pixels over the full duration
    _rise = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(XpGainPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Each new XP increment restarts the hold timer
    if (oldWidget.xpGained != widget.xpGained) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition uses a compositing layer (no saveLayer) — reliable on
    // high-refresh-rate / Samsung Exynos devices.
    // Center fills the Stack body; the card is translated directly so the
    // fractional offset concerns don't apply.
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: AnimatedBuilder(
            animation: _rise,
            // child is cached — not rebuilt every animation frame
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -80 * _rise.value),
              child: child,
            ),
            child: _buildCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 48;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final colors = context.slColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.allComplete ? colors.accent : colors.accentDark,
          width: widget.allComplete ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.allComplete
                ? colors.accentGlow
                : colors.accent.withValues(alpha: 0.15),
            blurRadius: widget.allComplete ? 24 : 12,
            spreadRadius: widget.allComplete ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sparkle particles
          _SparkleRow(count: widget.allComplete ? 5 : 3),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.allComplete)
                Text(
                  'QUEST COMPLETE!',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                    letterSpacing: 2,
                  ),
                ),
              Text(
                '+${widget.xpGained} XP',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: widget.allComplete ? 28 : 22,
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                  shadows: [
                    Shadow(color: colors.accentGlow, blurRadius: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _SparkleRow(count: widget.allComplete ? 5 : 3),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple sparkle row — static coloured star/dot icons
// ---------------------------------------------------------------------------
class _SparkleRow extends StatefulWidget {
  final int count;
  const _SparkleRow({required this.count});

  @override
  State<_SparkleRow> createState() => _SparkleRowState();
}

class _SparkleRowState extends State<_SparkleRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<bool> _starTypes;

  @override
  void initState() {
    super.initState();
    // Pre-compute the star symbol sequence once; don't recreate Random every
    // frame inside the AnimatedBuilder (called at up to 120 fps).
    final rng = Random(widget.count);
    _starTypes = List.generate(widget.count, (_) => rng.nextBool());
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_SparkleRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When allComplete changes (count 3 → 5), regenerate _starTypes so the
    // build method never accesses an out-of-bounds index.
    if (oldWidget.count != widget.count) {
      final rng = Random(widget.count);
      _starTypes = List.generate(widget.count, (_) => rng.nextBool());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stars are fixed at a constant font size (no layout changes per frame).
    // Only opacity and scale are animated — these don't affect layout bounds
    // so the parent Row never overflows.
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.count, (i) {
            final phase = (i / widget.count);
            final v = sin((_ctrl.value + phase) * pi);
            final scale = 0.7 + v * 0.5;
            final opacity = 0.4 + v * 0.6;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.0, 1.2),
                  child: Text(
                    _starTypes[i] ? '✦' : '✧',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.slColors.accent,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
