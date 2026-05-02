import 'package:flutter/material.dart';

/// Tema mengikuti desain Stitch: biru gelap profesional, permukaan bersih.
class AppTheme {
  static const Color navy = Color(0xFF1B2E4B);
  static const Color blueBright = Color(0xFF2563EB);
  static const Color surfaceMuted = Color(0xFFF4F5F7);
  static const Color labelBlue = Color(0xFF6478A8);
  static const Color orangeAccent = Color(0xFFF59E0B);

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: navy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDDE7F7),
      onPrimaryContainer: navy,
      secondary: blueBright,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: navy,
      onSurfaceVariant: Color(0xFF5C6B8A),
      outline: Color(0xFFE2E5EB),
      surfaceContainerHighest: surfaceMuted,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: navy,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
