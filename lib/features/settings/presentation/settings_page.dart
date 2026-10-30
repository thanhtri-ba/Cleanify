import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/tab_scaffold.dart';
import '../../auth/application/auth_session.dart';
import '../../scan/presentation/scan_actions.dart';
import '../application/app_settings.dart';

/// Tab Settings: tùy chọn trong app, quyền riêng tư và thông tin.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const pageKey = Key('settings-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final session = ref.watch(authSessionProvider);
    final bottom =
        math.max(24.0, MediaQuery.viewPaddingOf(context).bottom + 16);

    return TabScaffold(
      key: pageKey,
      current: AppTab.settings,
      onScan: () => startScanFlow(context, ref),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
          children: [
            Text(AppStrings.navSettings, style: AppText.h1),
            const SizedBox(height: 4),
            Text(AppStrings.settingsTabBody, style: AppText.captionSecondary),
            const SizedBox(height: 24),
            const _SectionLabel(AppStrings.settingsAccount),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 40),
              child: _SettingsCard(
                children: [
                  switch (session) {
                    SignedIn(:final user) => _AccountTile(
                        title: user.displayName,
                        subtitle: user.email,
                        trailing: TextButton(
                          onPressed: () => _signOut(context, ref),
                          child: Text(AppStrings.signOut, style: AppText.link),
                        ),
                      ),
                    SignedOut() => _AccountTile(
                        title: AppStrings.settingsSignIn,
                        subtitle: AppStrings.settingsSignInBody,
                        onTap: () => context.push(AppRoutes.signIn),
                      ),
                  },
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel(AppStrings.settingsPreferences),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _SettingsCard(
                children: [
                  _SwitchTile(
                    icon: AppAssets.bell,
                    title: AppStrings.settingsNotifications,
                    subtitle: AppStrings.settingsNotificationsBody,
                    value: settings.notificationsEnabled,
                    onChanged: (value) => ref
                        .read(appSettingsProvider.notifier)
                        .setNotificationsEnabled(value),
                  ),
                  const _CardDivider(),
                  _NavTile(
                    icon: AppAssets.layers,
                    title: AppStrings.settingsLanguage,
                    value: AppStrings.languageEnglish,
                    onTap: () => _showLanguage(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel(AppStrings.settingsPrivacy),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _SettingsCard(
                children: [
                  _NavTile(
                    icon: AppAssets.lockKeyhole,
                    title: AppStrings.settingsPrivacyPolicy,
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                  ),
                  const _CardDivider(),
                  _NavTile(
                    icon: AppAssets.download,
                    title: AppStrings.settingsRestore,
                    onTap: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.restoreUnavailable),
                          duration: Duration(seconds: 2),
                        ),
                      ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel(AppStrings.settingsAbout),
            const SizedBox(height: 8),
            const FadeSlideIn(
              delay: Duration(milliseconds: 180),
              child: _SettingsCard(
                children: [
                  _AboutTile(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authSessionProvider.notifier).signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.signedOut),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _showLanguage(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppText.custom(11, FontWeight.w600, AppColors.textMuted,
            letterSpacing: 0.66),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      color: AppColors.divider,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          _IconTile(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.rowTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowHint,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final String icon;
  final String title;
  final VoidCallback onTap;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _IconTile(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppText.rowTitle)),
              if (value != null) ...[
                Text(value!, style: AppText.captionSecondary),
                const SizedBox(width: 6),
              ],
              const AppSvg(
                AppAssets.chevronRight,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const _IconTile(AppAssets.userRound),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowHint,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null) ...[
                const SizedBox(width: 6),
                const AppSvg(
                  AppAssets.chevronRight,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: AppSvg(
                AppAssets.brandGlyph,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.appName, style: AppText.rowTitle),
                const SizedBox(height: 2),
                Text(AppStrings.settingsVersion, style: AppText.rowHint),
              ],
            ),
          ),
        ],
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
        : AppText.custom(14, FontWeight.w500, AppColors.textMuted,
            lineHeight: 20);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceTint : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.borderNeutral : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (selected)
            const AppSvg(
              AppAssets.check,
              size: 16,
              color: AppColors.positive,
            ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(trailing!, style: AppText.badge),
            ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.iconTile,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: AppSvg(icon, size: 18, color: AppColors.accentDeep),
      ),
    );
  }
}
