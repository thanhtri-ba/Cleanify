import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Nút nền trắng có viền, đi cùng [PrimaryButton] (Back, Skip for now...).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.labelStyle,
    this.radius = 16,
    this.borderColor = AppColors.border,
    this.shadows,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final TextStyle? labelStyle;
  final double radius;
  final Color borderColor;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    Widget button = Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onPressed,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: labelStyle ?? AppText.secondaryButtonLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
    if (shadows != null) {
      button = DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
        child: button,
      );
    }
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: button,
    );
  }
}
