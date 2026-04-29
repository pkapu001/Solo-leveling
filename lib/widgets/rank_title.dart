import 'package:flutter/material.dart';
import '../constants/xp_config.dart';

class RankTitle extends StatelessWidget {
  final int level;
  final double fontSize;

  const RankTitle({super.key, required this.level, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final rank = rankForLevel(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: rank.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '[ ${rank.title} ]',
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: rank.color,
          letterSpacing: 1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
