import 'package:flutter/material.dart';

/// Design tokens lấy từ file Figma (VesxbrRh84c6tumqYxgJ6i).
/// Màu có độ trong suốt được ghi sẵn dạng ARGB để tránh `withOpacity`.
abstract final class AppColors {
  static const primary = Color(0xFF111827);
  static const violet = Color(0xFF9CA3AF);
  static const success = Color(0xFF51DEA2);

  // KHÔNG có trong Figma: màu lỗi tạm thời, cần designer xác nhận.
  static const error = Color(0xFFDC2626);
  static const errorTint = Color(0x14DC2626);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted = Color(0xFF6B7280);

  static const border = Color(0xFFE5E7EB);
  static const borderNeutral = Color(0xFFE5E7EB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFF9FAFB);
  static const iconTile = Color(0xFFF3F4F6);
  static const divider = Color(0xFFF3F4F6);
  static const accent = Color(0xFF111827);
  static const accentDeep = Color(0xFF374151);
  static const chip = Color(0xFFF3F4F6);
  static const divider2 = Color(0xFFE5E7EB);
  static const positive = Color(0xFF288869);
  static const footerBorder = Color(0xFFF3F4F6);
  static const warnTint = Color(0xFFFFF7E9);
  static const warnText = Color(0xFF8D642A);
  static const segmentOff = Color(0xFFD1D5DB);
  static const surfaceMuted = Color(0xFFF9FAFB);
  static const canvas = Color(0xFFFFFFFF);
  static const violetDeep = Color(0xFF374151);
  static const textBlue = Color(0xFF6B7280);
  static const categoryTile = Color(0xFFF3F4F6);
  static const cardBorderSoft = Color(0x66D1D5DB);

  // Onboarding và File access (Figma node 74:2115, 74:2152, 74:2198, 74:2241).
  static const cta = Color(0xFF363539);
  static const skipBackground = Color(0xFFE2E2E2);
  static const textBody = Color(0xFF4B5563);
  static const ink = Color(0xFF111827);
  static const titleInk = Color(0xFF111827);
  static const dotActive1 = Color(0xFF0A0913);
  static const dotActive2 = Color(0xFF0E0E12);
  static const dotShadowSoft = Color(0x0D000000); // 5%
  static const dotShadowViolet = Color(0x33111827); // 30%
  static const illustrationCard = Color(0x08C2C2C2); // 3%
  static const glass60 = Color(0x99FFFFFF);
  static const reviewLink = Color(0xFF111827);
  static const alertDot = Color(0xFFBA1A1A);
  static const cardShadow = Color(0x0A1E202C); // 4%
  static const headerGlass = Color(0xCCFFFFFF); // 80%

  // Phân bố dung lượng trên Home.
  static const breakdownPhotos = Color(0xFF4F8CFF);
  static const breakdownScreenshots = Color(0xFFFFC83D);
  static const breakdownVideos = Color(0xFFFF5A5F);

  // Màn quét / dọn dẹp.
  static const scanHaloTop = Color(0x33E5E7EB);
  static const scanHaloBottom = Color(0x66F3F4F6);
  static const positiveSoft = Color(0xFF65CDA9);

  static const primaryTint = Color(0x1A111827); // 10%
  static const dotInactive = Color(0x99D1D5DB); // 60%
  static const glowCenter = Color(0x14111827); // 16%
  static const glowEdge = Color(0x00111827);
  static const lavenderGlow = Color(0x66D1D5DB); // 40%

  // Thẻ hero nền tối (dung lượng ở Home và tab Storage).
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF283343), Color(0xFF141C27), Color(0xFF0A1017)],
    stops: [0, 0.55, 1],
  );
  static const ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF25303F), Color(0xFF0B1220)],
  );
  static const heroAccent = Color(0xFF8FB4FF);
  static const onHero = Color(0xFFFFFFFF);
  static const onHeroSecondary = Color(0xB8FFFFFF); // 72%
  static const onHeroMuted = Color(0x8AFFFFFF); // 54%
  static const onHeroFaint = Color(0x52FFFFFF); // 32%
  static const heroBorder = Color(0x1FFFFFFF); // 12%
  static const heroTrack = Color(0x24FFFFFF); // 14%
  static const heroSurface = Color(0x1FFFFFFF); // 12%
  static const heroSegmentFree = Color(0x3DFFFFFF); // 24%

  static const glass70 = Color(0xB3FFFFFF);
  static const glass80 = Color(0xCCFFFFFF);
  static const glass90 = Color(0xE6FFFFFF);
  static const glassBorder30 = Color(0x4DD1D5DB);
  static const glassBorderSoft = Color(0x99E5E7EB);

  static const black = Color(0xFF111111);
  static const facebook = Color(0xFF1877F2);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9FAFB), Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
    stops: [0, 0.5, 1],
  );

  /// Nền từng trang onboarding theo Figma.
  static const onboarding1Gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9FAFB), Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
    stops: [0, 0.9999, 1],
  );
  static const onboarding2Gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9FAFB), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    stops: [0, 0.5, 1],
  );
  static const onboarding3Gradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  );
}
