import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_svg.dart';

/// Bảng màu của màn quyền ảnh (theo Figma 127:3099 – 127:3187).
abstract final class PhotoPalette {
  static const ink = Color(0xFF1C1C1C);
  static const body = Color(0xFF464646);
  static const muted = Color(0xFF727272);
  static const tile = Color(0xFFF3F3F3);
  static const card = Color(0xFFF8F8F8);
  static const border = Color(0xFFE7E7E7);
  static const primary = Color(0xFF676767);
  static const divider = Color(0xFFF4F4F4);
}

/// Header 56px: nút back tròn, tiêu đề căn giữa, vạch ngăn bên dưới.
class PhotoPermissionHeader extends StatelessWidget {
  const PhotoPermissionHeader({super.key, required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (onBack != null)
                Positioned(
                  left: 24,
                  child: Semantics(
                    button: true,
                    label: AppStrings.back,
                    excludeSemantics: true,
                    child: Material(
                      color: PhotoPalette.tile,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onBack,
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: AppSvg(AppAssets.chevronLeft, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Semantics(
                header: true,
                child: Text(
                  AppStrings.pmHeaderTitle,
                  style: AppText.custom(18, FontWeight.w600, PhotoPalette.ink),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: PhotoPalette.divider),
      ],
    );
  }
}

/// Khung minh họa 200px: thẻ trắng 96px có icon nằm giữa, kèm caption tùy chọn.
class PhotoIllustrationCard extends StatelessWidget {
  const PhotoIllustrationCard({super.key, required this.icon, this.caption});

  final String icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: PhotoPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PhotoPalette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.tokens.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x17676767),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: PhotoPalette.tile,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: AppSvg(icon, size: 28)),
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 12),
            Text(
              caption!,
              style: AppText.custom(12, FontWeight.w600, PhotoPalette.primary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Một dòng lợi ích: ô icon 34px + tiêu đề + mô tả.
class PhotoInfoRow extends StatelessWidget {
  const PhotoInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: PhotoPalette.tile,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: AppSvg(icon, size: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.custom(14, FontWeight.w600, PhotoPalette.ink,
                    lineHeight: 20),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppText.custom(12, FontWeight.w400, PhotoPalette.muted,
                    lineHeight: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hộp ghi chú có icon info.
class PhotoNoteBox extends StatelessWidget {
  const PhotoNoteBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PhotoPalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PhotoPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSvg(AppAssets.info, size: 16, color: PhotoPalette.muted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: AppText.custom(12, FontWeight.w400, PhotoPalette.muted,
                  lineHeight: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút 52px bo 16: đặc (filled) hoặc viền (outline), có icon tùy chọn.
class PhotoButton extends StatelessWidget {
  const PhotoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? context.tokens.surface : PhotoPalette.body;
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Material(
        color: filled ? PhotoPalette.primary : context.tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: filled
              ? BorderSide.none
              : const BorderSide(color: PhotoPalette.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  AppSvg(icon!, size: 18, color: foreground),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppText.custom(15, FontWeight.w600, foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
