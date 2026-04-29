import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 4)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  bool isUnlocked;

  @HiveField(2)
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    this.isUnlocked = false,
    this.unlockedAt,
  });
}
