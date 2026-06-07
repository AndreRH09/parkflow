import 'package:flutter/material.dart';

// Centralized color and typography tokens for ParkFlow
class AppColors {
  AppColors._();

  static const Color brightSnow = Color(0xFFF8FAFC); // branding
  static const Color dustGray = Color(0xFFD3D3D3);
  static const Color graphite = Color(0xFF302F33);
  static const Color mustard = Color(0xFFFFE14C);
  static const Color vanillaCustard = Color(0xFFFFF0A8);
  static const Color accent = Color(0xFFFFE14C); // apple-ui-skills accent
  static const Color surfaceRaised = Color.fromARGB(255, 220, 199, 8);
  static const Color textPrimary = Color.fromARGB(255, 0, 0, 0);
  static const Color textSecondary = Color(0xFF808080);
  static const Color borderDefault = Color(0xFFB5C7D8);
  static const Color white = Color(0xFFFFFFFF);
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  static const TextStyle heading32 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.graphite,
  );

  static const TextStyle body16 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle button16Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle heading20 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.graphite,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
      final base = ThemeData.light();

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: base.textTheme,
      scaffoldBackgroundColor: AppColors.brightSnow,
      colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      secondary: AppColors.mustard,
      ),
      appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.brightSnow,
      foregroundColor: AppColors.graphite,
      centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: AppColors.dustGray),
      ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      ),
      dividerColor: AppColors.dustGray,
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(AppColors.accent),
      ),
    );
  }
}
