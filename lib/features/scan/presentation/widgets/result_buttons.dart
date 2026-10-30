import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Nút chính 52px màu xám đậm của các màn kết quả (Figma 02B).
class ResultPrimaryButton extends StatelessWidget {
  const ResultPrimaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Material(
        color: FlowColors.progress,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: AppText.custom(14, FontWeight.w600, Colors.white,
                    lineHeight: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút phụ 52px nền trắng, viền nhạt, chữ xám đậm (Figma 02B).
class ResultSecondaryButton extends StatelessWidget {
  const ResultSecondaryButton(
      {super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: context.tokens.border),
    );
    return Material(
      color: context.tokens.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onPressed,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: AppText.custom(14, FontWeight.w600, context.tokens.textPrimary,
                  lineHeight: 20),
            ),
          ),
        ),
      ),
    );
  }
}
