import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/tab_scaffold.dart';
import '../../scan/presentation/scan_actions.dart';
import '../application/app_settings.dart';
import 'settings_widgets.dart';

/// Tab Settings (Figma 127:2216): tùy chọn, quét, hỗ trợ và thông tin.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const pageKey = Key('settings-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final bottom =
        math.max(24.0, MediaQuery.viewPaddingOf(context).bottom + 16);

    return TabScaffold(
      key: pageKey,
      current: AppTab.settings,
      onScan: () => startScanFlow(context, ref),
      body: ColoredBox(
        color: context.tokens.surface,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: context.tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              const SettingsSectionLabel('Preferences'),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 40),
                child: SettingsCard(
                  children: [
                    SettingsRow(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      value: _appearanceLabel(settings.appearance),
                      onTap: () => context.push(AppRoutes.appearanceSettings),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      asset: AppAssets.bell,
                      title: 'Notifications',
                      trailing: SettingsToggle(
                        value: settings.notificationsEnabled,
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setNotificationsEnabled(value),
                      ),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      asset: AppAssets.layers,
                      title: AppStrings.settingsLanguage,
                      value: AppStrings.languageEnglish,
                      onTap: () => _showLanguage(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SettingsSectionLabel('Storage'),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: SettingsCard(
                  children: [
                    SettingsRow(
                      asset: AppAssets.search,
                      title: 'Scan preferences',
                      onTap: () => context.push(AppRoutes.scanPreferences),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      asset: AppAssets.shieldCheck,
                      title: 'Cleanup confirmation',
                      onTap: () => _showCleanupConfirmation(context),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      asset: AppAssets.folder,
                      title: 'File access permissions',
                      onTap: () => context.push(AppRoutes.fileAccess),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SettingsSectionLabel('Support'),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: SettingsCard(
                  children: [
                    SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      onTap: () => context.push(AppRoutes.help),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      asset: AppAssets.fileText,
                      title: AppStrings.settingsPrivacyPolicy,
                      onTap: () => context.push(AppRoutes.privacyPolicy),
                    ),
                    const SettingsDivider(),
                    SettingsRow(
                      asset: AppAssets.info,
                      title: 'About Cleanify',
                      onTap: () => context.push(AppRoutes.about),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Cleanify v0.1.0',
                  style: TextStyle(fontSize: 12, color: context.tokens.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _appearanceLabel(AppearanceMode mode) => switch (mode) {
        AppearanceMode.system => 'System',
        AppearanceMode.light => 'Light',
        AppearanceMode.dark => 'Dark',
      };

  Future<void> _showCleanupConfirmation(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cleanup confirmation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Deletion always asks for your confirmation first. '
                'Nothing is removed until you review the selection and confirm.',
                style: TextStyle(fontSize: 14, height: 1.43, color: context.tokens.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguage(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.settingsLanguage, style: AppText.h1),
              const SizedBox(height: 16),
              const _LanguageRow(
                label: AppStrings.languageEnglish,
                selected: true,
              ),
              const SizedBox(height: 8),
              const _LanguageRow(
                label: AppStrings.languageVietnamese,
                selected: false,
                trailing: AppStrings.languageSoon,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    this.trailing,
  });

  final String label;
  final bool selected;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = selected
        ? AppText.rowTitle
        : AppText.custom(14, FontWeight.w500, context.tokens.textMuted,
            lineHeight: 20);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? context.tokens.surfaceMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? context.tokens.border : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (selected)
            AppSvg(
              AppAssets.check,
              size: 16,
              color: context.tokens.success,
            ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.tokens.chip,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(trailing!, style: AppText.badge),
            ),
        ],
      ),
    );
  }
}
