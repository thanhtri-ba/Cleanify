import 'package:flutter/material.dart';

/// Design tokens lấy từ file Figma (VesxbrRh84c6tumqYxgJ6i).
/// Màu có độ trong suốt được ghi sẵn dạng ARGB để tránh `withOpacity`.
abstract final class AppColors {
  static const primary = Color(0xFF625BEE);
  static const violet = Color(0xFFA78BFA);
  static const success = Color(0xFF51DEA2);

  // KHÔNG có trong Figma: màu lỗi tạm thời, cần designer xác nhận.
  static const error = Color(0xFFDC2626);
  static const errorTint = Color(0x14DC2626);

  static const textPrimary = Color(0xFF1A1B25);
  static const textSecondary = Color(0xFF464555);
  static const textMuted = Color(0xFF6B7280);

  static const border = Color(0xFFE2E1EF);
  static const borderNeutral = Color(0xFFE5E7EB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFF8F7FF);
  static const iconTile = Color(0xFFF3F2FF);
  static const divider = Color(0xFFF3F4F6);
  static const accent = Color(0xFF483FD4);
  static const accentDeep = Color(0xFF443E9D);
  static const chip = Color(0xFFECECFE);
  static const divider2 = Color(0xFFE7E7F8);
  static const positive = Color(0xFF288869);
  static const footerBorder = Color(0xFFF0EFF7);
  static const warnTint = Color(0xFFFFF7E9);
  static const warnText = Color(0xFF8D642A);
  static const segmentOff = Color(0xFFDDD9F7);
  static const surfaceMuted = Color(0xFFF9FAFB);
  static const canvas = Color(0xFFFBF8FF);
  static const violetDeep = Color(0xFF6D28D9);
  static const textBlue = Color(0xFF49596E);
  static const categoryTile = Color(0x99E2DFFF);
  static const cardBorderSoft = Color(0x66C7C4D7);

  static const primaryTint = Color(0x1A625BEE); // 10%
  static const dotInactive = Color(0x99C7C4D7); // 60%
  static const glowCenter = Color(0x29625BEE); // 16%
  static const glowEdge = Color(0x00625BEE);
  static const lavenderGlow = Color(0x66C3C0FF); // 40%

  static const glass70 = Color(0xB3FFFFFF);
  static const glass80 = Color(0xCCFFFFFF);
  static const glass90 = Color(0xE6FFFFFF);
  static const glassBorder30 = Color(0x4DC7C4D7);
  static const glassBorderSoft = Color(0x99E8E7F5);

  static const black = Color(0xFF111111);
  static const facebook = Color(0xFF1877F2);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F8FC), Color(0xFFFBF8FF), Color(0xFFF0EFFE)],
    stops: [0, 0.5, 1],
  );
}
