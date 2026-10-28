import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_svg.dart';

/// Khung minh họa trạng thái (cao 200): ô trắng 96 chứa icon, kèm nhãn tùy chọn.
class StatePanel extends StatelessWidget {
  const StatePanel({super.key, required this.icon, this.caption});

  final String icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x17625BEE),
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
                  color: AppColors.iconTile,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: AppSvg(icon, size: 28)),
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 12),
            Text(caption!, style: AppText.statusLabel),
          ],
        ],
      ),
    );
  }
}
