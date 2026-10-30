import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../application/app_settings.dart';
import 'settings_widgets.dart';
import '../../../core/theme/app_tokens.dart';

/// Appearance (Figma 127:2393). Lựa chọn được lưu; giao diện chưa đổi theo.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  static const _options = [
    (
      mode: AppearanceMode.system,
      title: 'System Default',
      hint: 'Follows your device appearance setting.',
      icon: Icons.brightness_auto_rounded,
    ),
    (
      mode: AppearanceMode.light,
      title: 'Light',
      hint: 'Bright surfaces with high contrast text.',
      icon: Icons.light_mode_outlined,
    ),
    (
      mode: AppearanceMode.dark,
      title: 'Dark',
      hint: 'Deep surfaces with readable light text.',
      icon: Icons.dark_mode_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appSettingsProvider.select((s) => s.appearance));
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            SettingsSubHeader(
              title: 'Appearance',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.settings),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    'Choose how Cleanify looks on your device. System Default '
                    'follows your device settings, while Light and Dark modes '
                    'stay consistent across every screen.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your selection is saved on this device.',
                    style: TextStyle(fontSize: 12, height: 16 / 12, color: context.tokens.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionLabel('Preview'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final o in _options) ...[
                        Expanded(
                          child: _PreviewCard(
                            mode: o.mode,
                            selected: mode == o.mode,
                            onTap: () => notifier.setAppearance(o.mode),
                          ),
                        ),
                        if (o.mode != AppearanceMode.dark)
                          const SizedBox(width: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionLabel('Selection'),
                  const SizedBox(height: 8),
                  SettingsCard(
                    children: [
                      for (var i = 0; i < _options.length; i++) ...[
                        if (i > 0) const SettingsDivider(),
                        SettingsRow(
                          icon: _options[i].icon,
                          title: _options[i].title,
                          subtitle: _options[i].hint,
                          trailing: mode == _options[i].mode
                              ? const _SelectedPill()
                              : null,
                          onTap: () => notifier.setAppearance(_options[i].mode),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tokens.iconTile,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: Text(
                      'Dark mode uses a clean dark surface system with strong '
                      'contrast so menus, cards, and text remain easy to read.',
                      style: TextStyle(fontSize: 12, height: 16 / 12, color: context.tokens.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppearanceMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = mode == AppearanceMode.dark;
    final ink = dark ? context.tokens.surface : context.tokens.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: dark ? context.tokens.textPrimary : context.tokens.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? context.tokens.textSecondary : context.tokens.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF555555),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.tokens.surface,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? context.tokens.textSecondary : Colors.transparent,
                      border: Border.all(
                        color: selected ? context.tokens.textSecondary : context.tokens.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final label in const ['Storage', 'Support', 'Settings'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dark ? context.tokens.surface : context.tokens.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.tokens.textSecondary,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        'Selected',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.tokens.surface,
        ),
      ),
    );
  }
}
