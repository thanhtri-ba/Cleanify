import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/theme/app_tokens.dart';

// Bảng màu màn Settings theo Figma (127:2216 … 127:2487).
// Tương đương token sáng; màn Settings chưa đổi theo tối.
const settingsBorder = Color(0xFFE5E7EB);
const settingsFaint = Color(0xFF727272);
const settingsIconWrap = Color(0xFFF3F4F6);

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.tokens.textCaption,
        letterSpacing: 0.96,
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.tokens.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 1, child: ColoredBox(color: context.tokens.surfaceMuted));
}

/// Một dòng trong thẻ: ô icon 28px, tiêu đề, giá trị hoặc công tắc, chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.asset,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String? asset;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconChild = asset != null
        ? AppSvg(asset!, size: 18, color: context.tokens.textPrimary)
        : Icon(icon, size: 18, color: context.tokens.textPrimary);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: context.tokens.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: iconChild),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.33,
                        color: context.tokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(fontSize: 13, color: context.tokens.textSecondary),
              ),
              const SizedBox(width: 8),
            ],
            if (trailing != null)
              trailing!
            else if (onTap != null)
              AppSvg(AppAssets.chevronRight,
                  size: 16, color: context.tokens.textSecondary),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: context.tokens.surface,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.tokens.surface,
      activeTrackColor: context.tokens.textSecondary,
      inactiveThumbColor: context.tokens.border,
      inactiveTrackColor: context.tokens.border,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Đầu trang các màn con: nút back tròn, tiêu đề giữa, đường kẻ dưới.
class SettingsSubHeader extends StatelessWidget {
  const SettingsSubHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: AppStrings.back,
                child: Material(
                  color: context.tokens.surfaceMuted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: AppSvg(AppAssets.chevronLeft,
                            size: 14, color: context.tokens.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 24 / 18,
                    letterSpacing: -0.45,
                    color: context.tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        const SettingsDivider(),
      ],
    );
  }
}
