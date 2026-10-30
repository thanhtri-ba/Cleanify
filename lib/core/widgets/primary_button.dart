import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'press_scale.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.labelStyle,
    this.leading,
    this.trailing,
    this.prominentShadow = false,
    this.color = AppColors.primary,
    this.gradient,
    this.radius = 16,
    this.shadows,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final TextStyle? labelStyle;
  final Widget? leading;
  final Widget? trailing;

  /// Bóng đậm dùng cho nút CTA ở onboarding.
  final bool prominentShadow;
  final Color color;

  /// Khi có, nền nút dùng gradient thay cho [color].
  final Gradient? gradient;
  final double radius;

  /// Ghi đè bóng mặc định (danh sách rỗng = không bóng).
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final borderRadius = BorderRadius.circular(radius);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null && !isLoading ? 0.5 : 1,
        child: PressScale(
          enabled: enabled,
          scale: 0.975,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: gradient == null ? color : null,
              gradient: gradient,
              borderRadius: borderRadius,
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: prominentShadow
                          ? const Color(0x52111827)
                          : const Color(0x24111827),
                      blurRadius: prominentShadow ? 24 : 12,
                      offset: Offset(0, prominentShadow ? 8 : 5),
                    ),
                  ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: borderRadius,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        onPressed!();
                      }
                    : null,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leading != null) ...[
                              leading!,
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                style: labelStyle ?? AppText.buttonLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (trailing != null) ...[
                              const SizedBox(width: 8),
                              trailing!,
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
