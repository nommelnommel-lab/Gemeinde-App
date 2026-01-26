import 'package:flutter/material.dart';

class AppTheme {
  static const Color warmBackground = Color(0xFFF8F3EE);
  static const Color primaryTeal = Color(0xFF1F8A8A);
  static const Color secondaryAccent = Color(0xFFF2A46F);
  static const Color textDark = Color(0xFF2C2A28);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF2E7DC);
  static const Color outline = Color(0xFFE6DDD3);

  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: primaryTeal,
      onPrimary: Colors.white,
      secondary: secondaryAccent,
      onSecondary: Colors.white,
      background: warmBackground,
      onBackground: textDark,
      surface: surface,
      onSurface: textDark,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: textDark,
      outline: outline,
      error: Color(0xFFE1645A),
    );

    final baseTextTheme = Typography.blackMountainView;
    final textTheme = baseTextTheme.copyWith(
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        height: 1.5,
        color: textDark,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        height: 1.4,
        color: textDark,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: textDark.withOpacity(0.7),
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: warmBackground,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: warmBackground,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textDark.withOpacity(0.6)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: primaryTeal, width: 1.4),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: primaryTeal,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryTeal,
        labelStyle: const TextStyle(color: textDark),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: const BorderSide(color: outline),
        ),
      ),
      dividerColor: outline,
    );
  }
}

class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double pill = 999;
}
