import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.gradient,
  });

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final g = gradient ?? (isDark ? null : AppColors.backgroundGradient);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: g,
        color: g == null ? context.tokens.background : null,
      ),
      child: child,
    );
  }
}
