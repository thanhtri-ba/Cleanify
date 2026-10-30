import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppTokens.light, Brightness.light);

  static ThemeData dark() => _build(AppTokens.dark, Brightness.dark);

  static ThemeData _build(AppTokens t, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? t.textPrimary : AppColors.primary,
      surface: t.surface,
      error: t.error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppText.fontFamily,
      scaffoldBackgroundColor: t.surface,
      extensions: [t],
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: isDark ? t.textPrimary : AppColors.primary,
      ),
    );
  }
}
