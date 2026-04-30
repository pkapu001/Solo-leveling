# Solo Leveling Fitness Tracker

Dark-gold Shadow Monarch themed Android fitness tracker built with Flutter. Train like a hunter — log workouts, gain XP, level up through hunter ranks, unlock achievements, and face weekly Shadow Trials.

---

## Setup (required before first build)

### 1. Install Flutter
Download from https://docs.flutter.dev/get-started/install/windows  
Add `<flutter-sdk>/bin` to your PATH.

### 2. Download Rajdhani font
1. Go to https://fonts.google.com/specimen/Rajdhani
2. Download the family
3. Copy `Rajdhani-Regular.ttf`, `Rajdhani-SemiBold.ttf`, `Rajdhani-Bold.ttf` into `assets/fonts/`

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

## Features

### Onboarding
A 5-page first-run wizard:
1. **Hunter identity** — enter your player name
2. **Fitness check** — records whether you can do push-ups / pull-ups (gates ability-locked exercises)
3. **Exercise selection** — pick from the exercise library (locked exercises are shown but disabled)
4. **Target & scaling setup** — set weekly targets and auto-scaling percentages per exercise
5. **Notifications** — choose morning and evening reminder times

### Home Screen (Daily Quest)
- **Player card** — name, level badge, rank title, XP progress bar, current streak
- **Daily Quest board** — each active exercise shows its target, current progress, and log/undo buttons with smart step sizing (reps, km, or seconds)
- **Full-quest bonus** — completing every exercise in a day awards a streak XP multiplier
- **Shadow Trial card** — weekly challenge against a locked exercise; completing it permanently unlocks that exercise and awards a volume bonus
- **Overlays** — level-up celebration, XP gain popup, achievement unlocked card, Shadow Trial completion screen

### Quest Log
- **Weekly XP bar chart** — last 8 ISO weeks at a glance
- **Quest history** — expandable list of all completed quests with date, total XP, and per-exercise breakdown
- **By-exercise tab** — per-exercise volume history over time

### Achievements
25 achievements across 5 categories, each awarding XP on unlock:

| Category | Achievements |
|----------|-------------|
| Quests | First Step (1), Persistent (10), Century (100) |
| Streak | Awakening (3 days), Iron Will (7), Shadow Disciple (30), Immortal (100) |
| Rank | Reaching D through Shadow Monarch rank |
| XP | Rookie (1 K), Veteran (10 K), Legend (100 K) |
| Exercise | Per-exercise volume milestones (10 / 50 / 100 units) |

Locked achievements show a progress bar with current / required values.

### Stats
- Hero header: level badge, name, rank, join date
- 8-item stats grid: Level, Total XP, Current Streak, Longest Streak, Days Active, Days Since Start, Achievements Unlocked, XP to Next Level
- Lifetime volume totals per exercise (with imperial / metric conversion)

### Settings
- **Notifications** — morning and evening reminder time pickers
- **Daily Quest** — add / remove exercises, adjust targets, configure weekly scaling %, toggle imperial / metric
- **Custom Exercises** — create exercises with a name, emoji, type (reps / distance / duration), muscle group, difficulty (1–5 ★), and auto-calculated XP per unit
- **Appearance** — choose from 4 visual themes (see below)
- **Danger Zone** — reset all progress

---

## Themes

| Theme | Description |
|-------|-------------|
| **Gold** (default) | Classic Solo Leveling system UI — deep black + gold |
| **Shadow Monarch** | Deep violet of Sung Jin-Woo's shadow powers |
| **Crimson Gate** | Blood-red danger-gate aesthetic |
| **System Frost** | Cold electric-blue system window |

---

## Rank progression

| Levels | Rank |
|--------|------|
| 1 – 10 | E-Class Hunter |
| 11 – 20 | D-Class Hunter |
| 21 – 35 | C-Class Hunter |
| 36 – 50 | B-Class Hunter |
| 51 – 65 | A-Class Hunter |
| 66 – 80 | S-Class Hunter |
| 81 – 95 | National Level Hunter |
| 96+ | **Shadow Monarch** |

---

## XP & leveling formula

```
xpToNextLevel(n) = 105·n + 3·n^1.5   (hybrid linear + power-law)
```

**Per-quest XP**:
- Each exercise: `volume × xpPerUnit` (difficulty-scaled; e.g. push-ups 2.0/rep, pull-ups 5.0/rep, running 25.0/km)
- 1.2× multiplier when an exercise's target is fully hit
- Flat +5 XP when the entire quest is completed
- Streak multiplier applied on top for consecutive days

**Weekly scaling**:
- Reps / duration: `newTarget = floor(current × (1 + scalingPct / 100))`, min +1
- Distance: decimal-preserving, min +0.1 km

---

## Exercise library

25+ built-in exercises organised by muscle group:

| Group | Exercises |
|-------|-----------|
| Push | Wall Push-ups → Handstand Push-ups, Dips (difficulty 1–5) |
| Pull | Inverted Rows, Assisted Pull-ups, Pull-ups, Chin-ups |
| Core | Sit-ups, Russian Twists, Spiderman Plank |
| Legs | Squats, Lunges, Bulgarian Split Squats, Jump Squats |
| Cardio | Running, Cycling, Jumping Jacks, Burpees, Jump Rope |
| Flexibility | Stretching, Handstand Holds, Push-up Hold |

**Ability-locked system** — exercises stay locked until prerequisites are met (e.g. regular pull-ups are locked until 100 assisted pull-ups are logged). Shadow Trials are the primary path to unlocking these exercises.

---

## Shadow Trials (weekly challenges)

Each week a locked exercise is selected as a Shadow Trial:
- A target amount is set; the player logs reps/volume toward it
- Completing the trial awards bonus XP and a permanent volume bonus on the prerequisite exercise
- Skipping a week is tracked; the trial resets the following week

---

## Sound effects

Four sound effects (pre-loaded, routed through Android game audio to avoid DAC delays):
- Progress increment / undo
- Quest complete
- Level up

Can be globally enabled / disabled.

---

## Notifications

- **Morning reminder** — scheduled daily at the player's chosen time; randomised Solo Leveling–flavoured messages
- **Evening reminder** — warns if the daily quest is incomplete by evening
- Timezone-aware using the device's local timezone
- Uses Android exact alarms with inexact fallback for older devices

---

## Project structure
```
lib/
├── main.dart                        # App entry point, Hive + notification + sound init
├── constants/
│   ├── exercises.dart               # Built-in exercise library (25+ exercises)
│   ├── achievements.dart            # 25 achievement definitions with XP rewards
│   ├── xp_config.dart               # XP formula, level thresholds, rank titles, xpPerUnit map
│   └── flavor_text.dart             # Solo Leveling quotes for notifications
├── models/                          # Hive data models (hand-written .g.dart adapters)
│   ├── player.dart / .g.dart        # Player profile, streak, ability locks, bonus maps
│   ├── quest_item.dart / .g.dart    # Single exercise within a daily quest
│   ├── daily_quest.dart / .g.dart   # One day's quest (items, XP delta, streak multiplier)
│   ├── exercise_config.dart / .g.dart  # Active exercise target + scaling %
│   ├── achievement.dart / .g.dart   # Unlock state + timestamp
│   ├── custom_exercise.dart / .g.dart  # User-created exercises
│   └── weekly_challenge.dart / .g.dart # Shadow Trial state per ISO week
├── services/
│   ├── storage_service.dart         # All Hive CRUD (8 boxes + personal bests)
│   ├── xp_service.dart              # XP calculation, streak management, personal records
│   ├── scaling_service.dart         # Weekly progressive difficulty scaling
│   ├── achievement_service.dart     # Achievement condition checks + XP rewards
│   ├── notification_service.dart    # Morning + evening scheduled reminders
│   ├── sound_service.dart           # Pre-loaded sound effect playback
│   └── providers.dart               # Riverpod providers for all state
├── theme/
│   └── app_theme.dart               # 4 Material 3 themes + helper methods
├── screens/
│   ├── onboarding/                  # 5-page first-run setup wizard
│   ├── home/                        # Dashboard: player card, daily quest, Shadow Trial
│   ├── quest_log/                   # History list + by-exercise tab + weekly XP chart
│   ├── achievements/                # Achievement grid with progress + unlock details
│   ├── stats/                       # Player stats grid + lifetime exercise totals
│   └── settings/
│       ├── settings_screen.dart          # Top-level settings
│       ├── daily_quest_settings_screen.dart  # Exercise targets + scaling
│       ├── manage_custom_exercises_screen.dart
│       ├── add_custom_exercise_screen.dart
│       └── theme_picker_screen.dart
└── widgets/
    ├── xp_bar.dart                       # Animated gold XP progress bar
    ├── level_badge.dart                  # Circular level badge with rank glow
    ├── rank_title.dart                   # Colour-coded rank label
    ├── quest_item_card.dart              # Exercise row: progress + log/undo buttons
    ├── exercise_picker.dart              # Searchable exercise picker dialog
    ├── exercise_config_tile.dart         # Target input + scaling slider
    ├── scaling_slider.dart               # 0–100 % weekly scaling slider
    ├── shadow_trial_card.dart            # Weekly challenge progress card
    ├── level_up_overlay.dart             # Full-screen level-up celebration
    ├── xp_gain_popup.dart                # Corner "+X XP" popup
    ├── achievement_unlocked_overlay.dart # Achievement card with confetti
    └── shadow_trial_complete_overlay.dart  # Bonus volume earned screen
```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `hive` + `hive_flutter` | Local offline storage |
| `flutter_local_notifications` | Daily reminders |
| `timezone` + `flutter_timezone` | Timezone-aware scheduling |
| `fl_chart` | Weekly XP bar chart |
| `audioplayers` | Sound effects |
| `google_fonts` | Rajdhani font fallback |
| `lottie` | Animation assets |
| `uuid` | Custom exercise IDs |
| `intl` | Date formatting |

---

## Notes
- Fully offline — no network, no auth, no cloud
- All data stored locally via Hive
- `.g.dart` adapter files are hand-written / pre-generated (no need to run `build_runner`)
