import 'package:flutter/material.dart';

/// Token màu theo ngữ nghĩa, có bản sáng và bản tối.
/// Dùng qua `context.tokens`. Các hằng số trong AppColors vẫn là màu sáng cố định.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textCaption,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.chip,
    required this.iconTile,
    required this.border,
    required this.borderSoft,
    required this.divider,
    required this.error,
    required this.success,
    required this.cta,
    required this.chartPhotos,
    required this.chartScreenshots,
    required this.chartVideos,
    required this.chartOther,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textCaption;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color chip;
  final Color iconTile;
  final Color border;
  final Color borderSoft;
  final Color divider;
  final Color error;
  final Color success;
  final Color cta;
  final Color chartPhotos;
  final Color chartScreenshots;
  final Color chartVideos;
  final Color chartOther;

  static const light = AppTokens(
    textPrimary: Color(0xFF1B1B1B),
    textSecondary: Color(0xFF464646),
    textMuted: Color(0xFF6B7280),
    textCaption: Color(0xFF727272),
    background: Color(0xFFF9F9F9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF9FAFB),
    chip: Color(0xFFEDEDED),
    iconTile: Color(0xFFF3F4F6),
    border: Color(0xFFE5E7EB),
    borderSoft: Color(0x66C6C6C6),
    divider: Color(0xFFF3F4F6),
    error: Color(0xFFDC2626),
    success: Color(0xFF288869),
    cta: Color(0xFF363539),
    chartPhotos: Color(0xFFF00909),
    chartScreenshots: Color(0xFFE6ED15),
    chartVideos: Color(0xFF2845D4),
    chartOther: Color(0xFF777777),
  );

  static const dark = AppTokens(
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFC9CDD3),
    textMuted: Color(0xFF9AA0A8),
    textCaption: Color(0xFF8A9099),
    background: Color(0xFF111318),
    surface: Color(0xFF1C1F26),
    surfaceMuted: Color(0xFF23272F),
    chip: Color(0xFF2A2E36),
    iconTile: Color(0xFF2A2E36),
    border: Color(0xFF2F343D),
    borderSoft: Color(0x662F343D),
    divider: Color(0xFF272B33),
    error: Color(0xFFF87171),
    success: Color(0xFF4ADE9B),
    cta: Color(0xFF3B4252),
    chartPhotos: Color(0xFFF00909),
    chartScreenshots: Color(0xFFE6ED15),
    chartVideos: Color(0xFF2845D4),
    chartOther: Color(0xFF777777),
  );

  @override
  AppTokens copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textCaption,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? chip,
    Color? iconTile,
    Color? border,
    Color? borderSoft,
    Color? divider,
    Color? error,
    Color? success,
    Color? cta,
    Color? chartPhotos,
    Color? chartScreenshots,
    Color? chartVideos,
    Color? chartOther,
  }) =>
      AppTokens(
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    textCaption: textCaption ?? this.textCaption,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    chip: chip ?? this.chip,
    iconTile: iconTile ?? this.iconTile,
    border: border ?? this.border,
    borderSoft: borderSoft ?? this.borderSoft,
    divider: divider ?? this.divider,
    error: error ?? this.error,
    success: success ?? this.success,
    cta: cta ?? this.cta,
    chartPhotos: chartPhotos ?? this.chartPhotos,
    chartScreenshots: chartScreenshots ?? this.chartScreenshots,
    chartVideos: chartVideos ?? this.chartVideos,
    chartOther: chartOther ?? this.chartOther,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textCaption: Color.lerp(textCaption, other.textCaption, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      iconTile: Color.lerp(iconTile, other.iconTile, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      cta: Color.lerp(cta, other.cta, t)!,
      chartPhotos: Color.lerp(chartPhotos, other.chartPhotos, t)!,
      chartScreenshots: Color.lerp(chartScreenshots, other.chartScreenshots, t)!,
      chartVideos: Color.lerp(chartVideos, other.chartVideos, t)!,
      chartOther: Color.lerp(chartOther, other.chartOther, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
