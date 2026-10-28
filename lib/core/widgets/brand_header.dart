import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_svg.dart';

/// Thanh đầu của các màn tài khoản: logo bên trái, nút Back tròn bên phải
/// (đúng theo Figma). Ẩn nút Back khi [onBack] là null.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppSvg(AppAssets.brandMark, size: 36),
                const SizedBox(width: 8),
                Text(AppStrings.appName, style: AppText.brand),
              ],
            ),
            if (onBack != null)
              Semantics(
                button: true,
                label: AppStrings.back,
                excludeSemantics: true,
                child: Material(
                  color: AppColors.surface,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.border),
                  ),
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
              )
            else
              const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}
