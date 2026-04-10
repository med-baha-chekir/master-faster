import 'package:flutter/material.dart';

class AppTheme {
  // Primary color: deep purple #534AB7
  static const Color primaryColor = Color(0xFF534AB7);
  // Accent color: teal #1D9E75
  static const Color accentColor = Color(0xFF1D9E75);
  // Emergency color: #E24B4A
  static const Color emergencyColor = Color(0xFFE24B4A);
  // Background: white / near-white #F8F8F8
  static const Color backgroundColor = Color(0xFFF8F8F8);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      error: emergencyColor,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme:
        const TextTheme(
          // Minimum font size: 18sp across the entire app
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ).apply(
          fontSizeFactor: 1.0,
          displayColor: Colors.black87,
          bodyColor: Colors.black87,
        ),
    // All cards use 16dp border radius
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: accentColor,
      error: emergencyColor,
      surface: const Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    textTheme:
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ).apply(
          fontSizeFactor: 1.0,
          displayColor: Colors.white,
          bodyColor: Colors.white,
        ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
  );
}
