import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../application/app_settings.dart';
import 'settings_widgets.dart';
import '../../../core/theme/app_tokens.dart';

/// Scan Preferences (Figma 127:2342).
class ScanPreferencesPage extends ConsumerWidget {
  const ScanPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(appSettingsProvider.select((s) => s.scanOptions));
    final notifier = ref.read(appSettingsProvider.notifier);

    Widget row(ScanOption option, String title, String hint) => _ToggleRow(
          title: title,
          hint: hint,
          value: enabled.contains(option),
          onChanged: (v) => notifier.setScanOption(option, v),
        );

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            SettingsSubHeader(
              title: 'Scan Preferences',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.settings),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Text(
                    'Choose which categories Cleanify checks during a scan. '
                    'Turning on a category only adds it to the scan results.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: context.tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deletion is always confirmed separately after the scan finishes.',
                    style: TextStyle(fontSize: 12, height: 16 / 12, color: context.tokens.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionLabel('Storage'),
                  const SizedBox(height: 8),
                  SettingsCard(
                    children: [
                      row(ScanOption.junkFiles, 'Junk Files',
                          'Temporary files, system cache, and logs.'),
                      const SettingsDivider(),
                      row(ScanOption.largeFiles, 'Large Files',
                          'Files over 100 MB that take up extra storage.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionLabel('Media'),
                  const SizedBox(height: 8),
                  SettingsCard(
                    children: [
                      row(ScanOption.duplicatePhotos, 'Duplicate Photos',
                          'Identical shots that appear more than once.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionLabel('Downloads'),
                  const SizedBox(height: 8),
                  SettingsCard(
                    children: [
                      row(ScanOption.downloads, 'Downloads',
                          'Archived documents and PDFs in your downloads folder.'),
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
                      'Results depend on the device and the permissions available to Cleanify.',
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
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
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: context.tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SettingsToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
