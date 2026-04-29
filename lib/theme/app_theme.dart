import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Theme type enum
// ---------------------------------------------------------------------------

/// All selectable accent themes for the app.
enum AppThemeType {
  /// Classic gold — the default Solo Leveling system UI colour.
  gold,

  /// Shadow Monarch — the deep violet of Sung Jin-Woo's shadow powers.
  shadowMonarch,

  /// Crimson Gate — the blood-red danger of a high-rank dungeon gate.
  crimsonGate,

  /// System Frost — the cold electric blue of the System interface.
  systemFrost;

  String get displayName => switch (this) {
        AppThemeType.gold => 'Gold',
        AppThemeType.shadowMonarch => 'Shadow Monarch',
        AppThemeType.crimsonGate => 'Crimson Gate',
        AppThemeType.systemFrost => 'System Frost',
      };

  String get subtitle => switch (this) {
        AppThemeType.gold => 'The System\'s classic hunter interface',
        AppThemeType.shadowMonarch => 'Rise from the ashes of death itself',
        AppThemeType.crimsonGate => 'Blood spills inside the red gate',
        AppThemeType.systemFrost => 'Cold logic of the System\'s core',
      };

  String get emoji => switch (this) {
        AppThemeType.gold => '⚔️',
        AppThemeType.shadowMonarch => '👑',
        AppThemeType.crimsonGate => '🔴',
        AppThemeType.systemFrost => '❄️',
      };
}

// ---------------------------------------------------------------------------
// SLColors — ThemeExtension carrying per-theme accent palette
// ---------------------------------------------------------------------------

/// Per-theme accent colour set, injected into [ThemeData.extensions].
/// Access via [BuildContext.slColors].
class SLColors extends ThemeExtension<SLColors> {
  final Color accent;
  final Color accentDark;
  final Color accentDeep;
  final Color accentGlow;

  const SLColors({
    required this.accent,
    required this.accentDark,
    required this.accentDeep,
    required this.accentGlow,
  });

  // ── Static presets ────────────────────────────────────────────────────────

  static const SLColors gold = SLColors(
    accent: Color(0xFFFFD700),
    accentDark: Color(0xFFC0932F),
    accentDeep: Color(0xFF8B6914),
    accentGlow: Color(0x55FFD700),
  );

  static const SLColors shadowMonarch = SLColors(
    accent: Color(0xFFA855F7),
    accentDark: Color(0xFF7E22CE),
    accentDeep: Color(0xFF4C1D95),
    accentGlow: Color(0x55A855F7),
  );

  static const SLColors crimsonGate = SLColors(
    accent: Color(0xFFE53E3E),
    accentDark: Color(0xFF9B1B30),
    accentDeep: Color(0xFF6B1520),
    accentGlow: Color(0x55E53E3E),
  );

  static const SLColors systemFrost = SLColors(
    accent: Color(0xFF38BDF8),
    accentDark: Color(0xFF0284C7),
    accentDeep: Color(0xFF0C4A6E),
    accentGlow: Color(0x5538BDF8),
  );

  static SLColors forType(AppThemeType type) => switch (type) {
        AppThemeType.gold => SLColors.gold,
        AppThemeType.shadowMonarch => SLColors.shadowMonarch,
        AppThemeType.crimsonGate => SLColors.crimsonGate,
        AppThemeType.systemFrost => SLColors.systemFrost,
      };

  // ── ThemeExtension overrides ───────────────────────────────────────────────

  @override
  SLColors copyWith({
    Color? accent,
    Color? accentDark,
    Color? accentDeep,
    Color? accentGlow,
  }) =>
      SLColors(
        accent: accent ?? this.accent,
        accentDark: accentDark ?? this.accentDark,
        accentDeep: accentDeep ?? this.accentDeep,
        accentGlow: accentGlow ?? this.accentGlow,
      );

  @override
  SLColors lerp(SLColors? other, double t) {
    if (other == null) return this;
    return SLColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// AppColors — static, theme-invariant colour constants
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color cardBorder = Color(0xFF2A2A2A);

  // Gold constants kept for backward-compat where static access is needed
  // (e.g. const TextStyle default values). Prefer context.slColors for
  // accent colours that should change with the active theme.
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFC0932F);
  static const Color goldDeep = Color(0xFF8B6914);
  static const Color goldGlow = Color(0x55FFD700);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF555555);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFCF6679);

  // Rank colors
  static const Color rankE = Color(0xFF9E9E9E);
  static const Color rankD = Color(0xFF4CAF50);
  static const Color rankC = Color(0xFF2196F3);
  static const Color rankB = Color(0xFF9C27B0);
  static const Color rankA = Color(0xFFFF9800);
  static const Color rankS = Color(0xFFFFD700);
  static const Color rankNational = Color(0xFFFF4081);
  static const Color rankMonarch = Color(0xFFE040FB);
}

class AppTheme {
  AppTheme._();

  /// Returns [ThemeData] for the given [AppThemeType].
  static ThemeData forType(AppThemeType type) {
    final colors = SLColors.forType(type);
    return _buildTheme(colors);
  }

  /// Convenience getter – keeps existing call sites in [main.dart] working.
  static ThemeData get dark => forType(AppThemeType.gold);

  static ThemeData _buildTheme(SLColors colors) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        secondary: colors.accentDark,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.background,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      extensions: [colors],
      textTheme: _buildTextTheme(colors),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.accent,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: colors.accent),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      dividerColor: AppColors.cardBorder,
      iconTheme: IconThemeData(color: colors.accent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: AppColors.background,
          textStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent),
          textStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accent,
        inactiveTrackColor: AppColors.cardBorder,
        thumbColor: colors.accent,
        overlayColor: colors.accentGlow,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return AppColors.cardBorder;
        }),
        checkColor: WidgetStateProperty.all(AppColors.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      useMaterial3: true,
    );
  }

  static TextTheme _buildTextTheme(SLColors colors) {
    return TextTheme(
      displayLarge: GoogleFonts.rajdhani(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: colors.accent,
        letterSpacing: 2,
      ),
      displayMedium: GoogleFonts.rajdhani(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
      ),
      displaySmall: GoogleFonts.rajdhani(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
      headlineLarge: GoogleFonts.rajdhani(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
      ),
      headlineMedium: GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
      headlineSmall: GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      titleMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.accent,
        letterSpacing: 1,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorations
// ---------------------------------------------------------------------------

/// Plain card decoration — uses only surface + border colours (no accent).
BoxDecoration goldCardDecoration({double borderRadius = 12}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.cardBorder),
    );

/// Glowing card decoration — accent colour depends on the active theme.
/// Pass [context] so the correct [SLColors] accent is resolved.
BoxDecoration goldGlowDecoration(BuildContext context,
        {double borderRadius = 12}) =>
    BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: context.slColors.accent, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: context.slColors.accentGlow,
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    );

// ---------------------------------------------------------------------------
// BuildContext extension
// ---------------------------------------------------------------------------

extension AppThemeContext on BuildContext {
  /// The active per-theme accent colour set. Shorthand for
  /// `Theme.of(context).extension<SLColors>()!`.
  SLColors get slColors => Theme.of(this).extension<SLColors>()!;
}
