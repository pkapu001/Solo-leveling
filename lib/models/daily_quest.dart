import 'package:hive/hive.dart';
import 'quest_item.dart';

part 'daily_quest.g.dart';

@HiveType(typeId: 2)
class DailyQuest extends HiveObject {
  /// Date key in "yyyy-MM-dd" format
  @HiveField(0)
  String dateKey;

  @HiveField(1)
  List<QuestItem> items;

  @HiveField(2)
  double xpEarned;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  bool isRestDay;

  @HiveField(5)
  double streakMultiplier;

  DailyQuest({
    required this.dateKey,
    required this.items,
    this.xpEarned = 0.0,
    this.isCompleted = false,
    this.isRestDay = false,
    this.streakMultiplier = 1.0,
  });

  double get overallProgress {
    if (items.isEmpty) return 0;
    final sum = items.fold<double>(0, (acc, i) => acc + i.progress);
    return sum / items.length;
  }

  int get completedCount => items.where((i) => i.isCompleted).length;
}
