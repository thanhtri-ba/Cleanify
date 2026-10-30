import 'package:flutter/material.dart';

/// Bảng màu cục bộ cho luồng chính (Home, Smart Scan, Scan Complete,
/// Cleaning) theo Figma node 127:857. Tách khỏi AppColors để không ảnh hưởng
/// các màn khác.
abstract final class FlowColors {
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF9F9F9);
  static const border = Color(0xFFE7E7E7);
  static const chip = Color(0xFFEDEDED);
  static const track = Color(0xFFEDEDED);
  static const ink = Color(0xFF1B1B1B);
  static const textSecondary = Color(0xFF464646);
  static const textMuted = Color(0xFF575757);

  // Phân bố dung lượng: ảnh, ảnh chụp màn hình, video.
  static const segPhotos = Color(0xFFF00909);
  static const segScreenshots = Color(0xFFE6ED15);
  static const segVideos = Color(0xFF2845D4);
  static const segOther = Color(0xFF777777);


  // Smart Scan theo Figma 127:1012.
  static const barBg = Color(0xFFF3F3F3);
  static const progress = Color(0xFF676767);
  static const pulse = Color(0xFF009DE5);
  static const cardBorder = Color(0x66C6C6C6);
  static const divider = Color(0x4DC6C6C6);
  static const dividerLight = Color(0x33C6C6C6);
  static const dividerDark = Color(0xFF1B1B1B);
  static const statAccent = Color(0xFF676767);
  static const captionMuted = Color(0xFF727272);

  static const ctaGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF000000)],
  );
}
