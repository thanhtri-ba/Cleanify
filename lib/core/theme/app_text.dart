import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography theo Figma (font Inter).
/// Font Inter là variable font ở assets/fonts/Inter.ttf (khai báo trong pubspec).
abstract final class AppText {
  static const fontFamily = 'Inter';

  static TextStyle _s(
    double size,
    FontWeight weight,
    Color color, {
    double? lineHeight,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: lineHeight == null ? null : lineHeight / size,
      letterSpacing: letterSpacing,
    );
  }

  static final h1 = _s(26, FontWeight.w700, AppColors.textPrimary,
      lineHeight: 32, letterSpacing: -0.65);
  static final brand =
      _s(18, FontWeight.w700, AppColors.textPrimary, letterSpacing: -0.45);
  static final body =
      _s(14, FontWeight.w400, AppColors.textSecondary, lineHeight: 21);
  static final onboardingBody =
      _s(14, FontWeight.w400, AppColors.textSecondary, lineHeight: 22.75);
  static final fieldLabel = _s(13, FontWeight.w500, AppColors.textPrimary);
  static final input = _s(14, FontWeight.w400, AppColors.textPrimary);
  static final hint = _s(14, FontWeight.w400, AppColors.textMuted);
  static final caption =
      _s(12, FontWeight.w400, AppColors.textMuted, lineHeight: 18);
  static final captionSecondary =
      _s(12, FontWeight.w400, AppColors.textSecondary, lineHeight: 18);
  static final link =
      _s(13, FontWeight.w600, AppColors.primary, lineHeight: 20);
  static final bodySmall =
      _s(13, FontWeight.w400, AppColors.textSecondary, lineHeight: 20);
  static final buttonLabel = _s(15, FontWeight.w600, Colors.white);
  static final ctaLabel = _s(14, FontWeight.w600, Colors.white,
      lineHeight: 18, letterSpacing: -0.07);
  static final secondaryButtonLabel =
      _s(15, FontWeight.w600, AppColors.textSecondary);
  static final social = _s(14, FontWeight.w600, AppColors.textPrimary);
  static final skip = _s(14, FontWeight.w600, AppColors.textSecondary,
      lineHeight: 18, letterSpacing: -0.07);
  static final subtleLink = _s(12, FontWeight.w500, AppColors.textSecondary,
      lineHeight: 16, letterSpacing: 0.12);
  static final badge = _s(11, FontWeight.w600, AppColors.textSecondary,
      lineHeight: 14, letterSpacing: 0.66);
  static final error = _s(12, FontWeight.w500, AppColors.error, lineHeight: 18);
  static final pageTitle =
      _s(18, FontWeight.w600, AppColors.textPrimary);
  static final rowTitle =
      _s(14, FontWeight.w600, AppColors.textPrimary, lineHeight: 20);
  static final statusLabel = _s(12, FontWeight.w600, AppColors.primary);
  static final display = _s(24, FontWeight.w600, AppColors.textPrimary,
      lineHeight: 30, letterSpacing: -0.6);
  static final bigNumber = _s(44, FontWeight.w700, AppColors.textPrimary,
      lineHeight: 48, letterSpacing: -1.1);
  static final bigUnit = _s(20, FontWeight.w700, AppColors.accent,
      lineHeight: 26, letterSpacing: -0.3);
  static final stat = _s(20, FontWeight.w600, AppColors.textPrimary,
      lineHeight: 26, letterSpacing: -0.3);
  static final statLabel = _s(12, FontWeight.w500, AppColors.textSecondary,
      lineHeight: 16, letterSpacing: 0.12);
  static final rowLabel =
      _s(14, FontWeight.w500, AppColors.textPrimary, lineHeight: 20);
  static final rowHint =
      _s(11, FontWeight.w400, AppColors.textMuted, lineHeight: 15);
  static final sectionTitle =
      _s(13, FontWeight.w600, AppColors.textPrimary, lineHeight: 18);
  static final ctaSmall = _s(14, FontWeight.w600, Colors.white,
      lineHeight: 18, letterSpacing: 0.14);
  static final linkAccent = _s(13, FontWeight.w600, AppColors.accent);
  static final accentButton = _s(14, FontWeight.w600, AppColors.accent);
  static final noteBody =
      _s(12, FontWeight.w400, AppColors.textSecondary, lineHeight: 18);
}
