import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================================================
/// LÚMEN DESIGN TOKENS (Flutter)
/// Variable names intentionally match design language:
/// Background, Foreground, Primary, Secondary,
/// Accent/Glow, Muted, Border, Card/Surface
/// =======================================================
class LumenColors {
  // ----------------------------
  // LIGHT MODE
  // ----------------------------
  static const lightBackground = Color(0xFFEFECE3); // warm beige
  static const lightFg = Color(0xFF000000); // black
  static const lightPrimary = Color(0xFF4A70A9); // professional blue
  static const lightSecondary = Color(0xFF8FABD4); // soft blue
  static const lightAccent = Color(0xFF8FABD4); // glow / accent (kept soft)
  static const lightMuted = Color(0xFFE0DDD1); // muted beige
  static const lightBorder = Color(0xFFD6D2C4); // slightly darker muted
  static const lightSurface = Color(0xFFFFFFFF); // card / surface

  // ----------------------------
  // DARK MODE
  // ----------------------------
  static const darkBackground = Color(0xFF0C2B4E); // deep navy
  static const darkFg = Color(0xFFF4F4F4); // off-white
  static const darkPrimary = Color(0xFF8FABD4); // cyan-blue
  static const darkSecondary = Color(0xFF1D546C); // dark teal
  static const darkAccent = Color(0xFF8FABD4); // glow / accent
  static const darkMuted = Color(0xFF2E4A66); // muted blue-gray
  static const darkBorder = Color(0xFF334E68); // border gray-blue
  static const darkSurface = Color(0xFF1A3D64); // card / surface
}

extension on Color {
  Color withValues({
    int? alpha,
    int? red,
    int? green,
    int? blue,
  }) {
    return Color.fromARGB(
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}

class LumenTheme {
  // =======================================================
  // LIGHT THEME
  // =======================================================
  static ThemeData get light {
    const scheme = ColorScheme.light(
      background: LumenColors.lightBackground,
      onBackground: LumenColors.lightFg,

      surface: LumenColors.lightSurface,
      onSurface: LumenColors.lightFg,

      primary: LumenColors.lightPrimary,
      onPrimary: Colors.white,

      secondary: LumenColors.lightSecondary,
      onSecondary: Colors.black,

      tertiary: LumenColors.lightAccent,
      onTertiary: Colors.black,

      surfaceVariant: LumenColors.lightMuted,
      outline: LumenColors.lightBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: LumenColors.lightBackground,
      canvasColor: LumenColors.lightBackground,
      textTheme: GoogleFonts.interTextTheme(),
      dividerTheme: DividerThemeData(
        color: LumenColors.lightBorder.withValues(alpha: 0.9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      iconTheme: IconThemeData(
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.85),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.45)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? scheme.secondary.withValues(alpha: 0.45)
              : scheme.outline,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surface,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.secondary,
        inactiveTrackColor: scheme.outline,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
    );
  }

  // =======================================================
  // DARK THEME
  // =======================================================
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      background: LumenColors.darkBackground,
      onBackground: LumenColors.darkFg,

      surface: LumenColors.darkSurface,
      onSurface: LumenColors.darkFg,

      primary: LumenColors.darkPrimary,
      onPrimary: Colors.black,

      secondary: LumenColors.darkSecondary,
      onSecondary: LumenColors.darkFg,

      tertiary: LumenColors.darkAccent,
      onTertiary: Colors.black,

      surfaceVariant: LumenColors.darkMuted,
      outline: LumenColors.darkBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: LumenColors.darkBackground,
      canvasColor: LumenColors.darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      dividerTheme: DividerThemeData(
        color: LumenColors.darkBorder.withValues(alpha: 0.8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      iconTheme: IconThemeData(
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.55),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.45)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outline,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.7),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.outline,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
