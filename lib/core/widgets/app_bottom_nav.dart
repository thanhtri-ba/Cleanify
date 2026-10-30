import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_assets.dart';
import '../theme/app_text.dart';
import 'app_svg.dart';
import '../theme/app_tokens.dart';

enum AppTab { home, scan, activity, settings }

/// Thanh điều hướng dưới (Home · Clean · Activity · Settings) theo Figma.
/// Nền pill trượt sang tab đang chọn, icon nhích nhẹ khi kích hoạt.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  static const _items = <(AppTab, String, String)>[
    (AppTab.home, AppAssets.home, AppStrings.navHome),
    (AppTab.scan, AppAssets.broom, AppStrings.navClean),
    (AppTab.activity, AppAssets.history, AppStrings.navActivity),
    (AppTab.settings, AppAssets.settings, AppStrings.navSettings),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(14.0, MediaQuery.viewPaddingOf(context).bottom);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final activeIndex =
        math.max(0, _items.indexWhere((item) => item.$1 == current));

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: context.tokens.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26111827),
              blurRadius: 30,
              spreadRadius: -14,
              offset: Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          height: 52,
          child: LayoutBuilder(
            builder: (context, box) {
              final itemWidth = box.maxWidth / _items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 340),
                    curve: Curves.easeOutCubic,
                    left: activeIndex * itemWidth + 2,
                    top: 0,
                    width: itemWidth - 4,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.tokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (tab, icon, label) in _items)
                        Expanded(
                          child: _NavItem(
                            icon: icon,
                            label: label,
                            active: tab == current,
                            onTap: () => onTap(tab),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final color = active ? context.tokens.textPrimary : context.tokens.textMuted;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (!active) HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active && !reduce ? 1.08 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: SizedBox(
                height: 18.33,
                child: AppSvg(icon, size: 18.33, color: color),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppText.custom(11, FontWeight.w600, color, lineHeight: 14),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
