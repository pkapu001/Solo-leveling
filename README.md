# Solo Leveling Fitness Tracker

Dark-gold Shadow Monarch themed Android fitness tracker built with Flutter.

---

## Setup (required before first build)

### 1. Install Flutter
Download from https://docs.flutter.dev/get-started/install/windows
Add `<flutter-sdk>/bin` to your PATH.

### 2. Download Rajdhani font
1. Go to https://fonts.google.com/specimen/Rajdhani
2. Download the family
3. Copy `Rajdhani-Regular.ttf`, `Rajdhani-SemiBold.ttf`, `Rajdhani-Bold.ttf`
   into `assets/fonts/`

### 3. Install dependencies
```bash
cd solo_leveling_fitness
flutter pub get
```

### 4. Run on device / emulator
```bash
flutter run
```

### 5. Build release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Project structure
```
lib/
├── main.dart                   # App entry point, Hive + notification init
├── constants/
│   ├── exercises.dart          # Standard exercise library (11 exercises)
│   ├── xp_config.dart          # XP formula, level thresholds, rank titles
│   └── flavor_text.dart        # Solo Leveling quotes for notifications
├── models/                     # Hive data models (with hand-written .g.dart adapters)
│   ├── player.dart / .g.dart
│   ├── quest_item.dart / .g.dart
│   ├── daily_quest.dart / .g.dart
│   └── exercise_config.dart / .g.dart
├── services/
│   ├── storage_service.dart    # All Hive CRUD
│   ├── xp_service.dart         # XP award, level-up detection, streak tracking
│   ├── scaling_service.dart    # Weekly difficulty scaling per exercise
│   ├── notification_service.dart  # Daily quest push notification
│   └── providers.dart          # Riverpod providers for all state
├── theme/
│   └── app_theme.dart          # Dark gold Material3 theme + helpers
├── screens/
│   ├── onboarding/             # 3-step first-run setup
│   ├── home/                   # Dashboard: player card, daily quest, streak
│   ├── quest_log/              # History + weekly XP bar chart
│   └── settings/               # Edit exercises, targets, scaling %, notification time
└── widgets/
    ├── xp_bar.dart             # Animated gold XP progress bar
    ├── level_badge.dart        # Hexagonal level badge with rank glow
    ├── rank_title.dart         # Colored rank label
    ├── quest_item_card.dart    # Exercise row with progress + log button
    └── level_up_overlay.dart   # Full-screen level-up animation overlay
```

---

## Rank progression

| Level | Rank |
|-------|------|
| 1–10 | E-Class Hunter |
| 11–20 | D-Class Hunter |
| 21–35 | C-Class Hunter |
| 36–50 | B-Class Hunter |
| 51–65 | A-Class Hunter |
| 66–80 | S-Class Hunter |
| 81–95 | National Level Hunter |
| 96+ | **Shadow Monarch** |

---

## XP formula
- Each exercise: `xp = baseXp * (completed / target)` + 20% bonus if fully completed
- Level threshold: `xpNeeded(level) = 100 * level + 10 * level²`
- Weekly scaling: `newTarget = floor(current * (1 + scalingPct / 100))`, min +1

---

## Notes
- Fully offline — no network, no auth, no cloud
- All data stored via Hive on device
- `.g.dart` adapter files are pre-generated (no need to run `build_runner`)
