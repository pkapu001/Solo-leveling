/// Solo Leveling flavor text for notifications and level-up messages.
library;

const List<String> kMorningNotifications = [
  'Wake up, Hunter. Another day to get stronger awaits you.',
  'Rise. Every champion was once a beginner who refused to give up.',
  'The System has reset. Your quest begins now — don\'t waste the day.',
  'A new dawn, a new chance to surpass your limits. Arise.',
  'The shadows grow stronger while you sleep in. Get up, Hunter.',
  'Sung Jin-Woo rose from the weakest to the strongest. Your story starts this morning.',
  'Open your eyes. The gate is already open and time is ticking.',
  'Today\'s grind is tomorrow\'s power. Get up and earn it.',
  'You were given another day to level up. Don\'t squander it.',
  'Every legend started with a single morning they chose to get up and fight.',
];

const List<String> kEveningNotifications = [
  'Still sitting? Move your ass — you don\'t wanna die a weak nobody.',
  'Your quests aren\'t going to finish themselves, you lazy hunter.',
  'The weak rest. The strong train. Which one are you tonight?',
  'Every minute you waste, someone else is out there getting stronger than you.',
  'You really gonna let today go to waste? Pathetic. Move.',
  'The System has no mercy for slackers. Get off the couch.',
  'Still no workout? Embarrassing. Get up before you become permanently weak.',
  'You want power? Stop sulking and go earn it, Hunter.',
  'The shadows are watching. Don\'t embarrass yourself tonight.',
  'Last call. Finish your quests or stay weak forever — your choice.',
];

const List<String> kDailyQuestNotifications = [
  'Arise. Your daily quest awaits, Hunter.',
  'A new gate has opened. Will you step through?',
  'The System demands your growth.',
  'You have not yet reached your limit.',
  'Complete your daily quest or remain weak forever.',
  'Every rep brings you closer to becoming the Shadow Monarch.',
  'Your body is the dungeon. Conquer it.',
  'The weakest hunters quit. You are not weak.',
  'Pain is temporary. Your rank is permanent.',
  'The System watches. Do not disappoint it.',
  'Another day. Another chance to level up.',
  'Shadows are forged through suffering and discipline.',
  'Sung Jin-Woo did not stop. Neither will you.',
  "I alone level up — today's quest begins now.",
  'Your daily quest has reset. Time to prove your worth.',
  'A hunter who rests is a hunter who falls behind.',
  'The gate will close. Complete your quest before it does.',
  'Power is earned, not given. Begin your training.',
];

const List<String> kLevelUpMessages = [
  'Level Up! The System acknowledges your growth.',
  'You have grown stronger, Hunter.',
  'Your power increases. The shadows bow to you.',
  'Another level cleared. You are becoming unstoppable.',
  'The System is pleased. Your dedication is noted.',
  'Power surge detected. You have leveled up.',
  'Weak hunters plateau. You keep climbing.',
  'A new tier of strength unlocked.',
];

const List<String> kQuestCompleteMessages = [
  'Quest complete. Well done, Hunter.',
  'Daily quest cleared. XP awarded.',
  'Outstanding. The System records your performance.',
  'You did not yield. Quest complete.',
  'Another day conquered. Rest and rise again.',
];

const List<String> kStreakMessages = [
  'Streak maintained. Consistency is the path to the throne.',
  'You keep showing up. That alone sets you apart.',
  '{n}-day streak! The shadows grow with you.',
];

String streakMessage(int days) {
  final msg = kStreakMessages[days % kStreakMessages.length];
  return msg.replaceAll('{n}', days.toString());
}

String randomNotification() {
  final idx =
      DateTime.now().millisecondsSinceEpoch % kDailyQuestNotifications.length;
  return kDailyQuestNotifications[idx];
}

String randomMorningNotification() {
  final idx =
      DateTime.now().millisecondsSinceEpoch % kMorningNotifications.length;
  return kMorningNotifications[idx];
}

String randomEveningNotification() {
  final idx =
      DateTime.now().millisecondsSinceEpoch % kEveningNotifications.length;
  return kEveningNotifications[idx];
}
