import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_svg.dart';

enum AppTab { home, scan, storage, settings }

/// Thanh điều hướng dưới (Home · Clean · Storage · Settings) theo Figma.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  static const _items = <(AppTab, String, String)>[
    (AppTab.home, AppAssets.home, AppStrings.navHome),
    (AppTab.scan, AppAssets.broom, AppStrings.navClean),
    (AppTab.storage, AppAssets.pieChart, AppStrings.navStorage),
    (AppTab.settings, AppAssets.settings, AppStrings.navSettings),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(14.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottom),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.borderNeutral),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26111827),
              blurRadius: 30,
              spreadRadius: -14,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Row(
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
    final color = active ? AppColors.primary : AppColors.textBlue;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? AppColors.chip : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 18.33,
                child: AppSvg(icon, size: 18.33, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppText.custom(11, FontWeight.w600, color,
                    lineHeight: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
