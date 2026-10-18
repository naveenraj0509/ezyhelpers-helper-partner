import 'package:flutter/material.dart';

/// Colour tokens shared by the glass widgets and the Material theme.
class AppColors {
  static const primary = Color(0xFF1B55A6); // EzyHelpers deep blue
  static const sky = Color(0xFF6FC8F1); // EzyHelpers sky blue
  static const primaryDeep = Color(0xFF134285);
  static const ink = Color(0xFF232B38);
  static const inkSoft = Color(0xFF6B7785);

  static const success = Color(0xFF4C9A74);
  static const warning = Color(0xFFD09A4E);
  static const danger = Color(0xFFC4535A);

  static const backdropTop = Color(0xFFEEF8FE);
  static const backdropMid = Color(0xFFF8FCFF);
  static const backdropBottom = Color(0xFFE8F2FB);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: Colors.white,
  );

  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography.blackMountainView.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: const TextStyle(color: AppColors.inkSoft),
      prefixIconColor: AppColors.inkSoft,
      suffixIconColor: AppColors.inkSoft,
      border: border(Colors.white.withValues(alpha: 0.8)),
      enabledBorder: border(Colors.white.withValues(alpha: 0.8)),
      focusedBorder: border(AppColors.primary, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink.withValues(alpha: 0.92),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
  );
}
